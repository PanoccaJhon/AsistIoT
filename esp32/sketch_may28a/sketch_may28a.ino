// --- LIBRERÍAS ---
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <BH1750.h>
#include "secrets.h"

#include <Preferences.h>     // <-- NUEVO: Para guardar credenciales WiFi
#include <BLEDevice.h>       // <-- NUEVO: Librerías para Bluetooth
#include <BLEUtils.h>
#include <BLEServer.h>

// --- PINES Y CONFIGURACIÓN ---
#define PIR_PIN 10
#define RELAY1_PIN 7
#define RELAY2_PIN 6
#define I2C_SDA 8
#define I2C_SCL 9
#define RESET_BUTTON_PIN 1

#define LUX_THRESHOLD 100
#define TELEMETRY_INTERVAL 30000
#define MOTION_TIMEOUT 60000
#define LONG_PRESS_DURATION 5000

// --- CONFIGURACIÓN BLE (deben coincidir con la app Flutter) --- // <-- NUEVO
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// --- OBJETOS Y VARIABLES GLOBALES ---
char TELEMETRY_TOPIC[128];
char EVENTS_TOPIC[128];
char COMMANDS_TOPIC[128];
char CONNECTION_STATE_TOPIC[128];

unsigned long buttonPressStartTime = 0;
bool resetActionTriggered = false;

bool relay1State = false;
bool relay2State = false;
bool autoMode = true;
float currentLux = 0;
bool lastMotionState = false;
unsigned long lastPublishTime = 0;
unsigned long lastMotionTime = 0;

WiFiClientSecure net;
PubSubClient client(net);
BH1750 lightMeter;
Preferences preferences; // Objeto para almacenamiento persistente

// --- DECLARACIÓN DE FUNCIONES ---
void setupTopics();
void startNormalMode(String ssid, String password);
void connectAWS(String ssid, String password);
void reconnect();
void publishTelemetry();
void publishEvent(const char* eventType, const char* message);
void messageHandler(char* topic, byte* payload, unsigned int length);
void handleSensorLogic();
void controlLight(const char* lightId, bool state);
void setupBLEProvisioning(); 
void checkResetButton(); 
void clearWifiCredentialsAndReboot(); 

// --- Clase para manejar los eventos de escritura BLE ---
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      //std::string stdValue = pCharacteristic->getValue();
      //String value = stdValue.c_str();
      String value = pCharacteristic->getValue();

      if (value.length() > 0) {
        Serial.println("*********");
        Serial.print("Nuevo valor recibido: ");
        Serial.println(value); // Serial.println funciona perfectamente con String

        // Parsear el JSON recibido
        StaticJsonDocument<128> doc;
        // deserializeJson también funciona perfectamente con String
        DeserializationError error = deserializeJson(doc, value);

        if (error) {
          Serial.print(F("deserializeJson() falló: "));
          Serial.println(error.c_str());
          return;
        }

        String ssid = doc["ssid"];
        String pass = doc["pass"];

        Serial.println("Guardando credenciales WiFi...");
        preferences.begin("wifi-creds", false);
        preferences.putString("ssid", ssid);
        preferences.putString("pass", pass);
        preferences.end();
        
        Serial.println("Credenciales guardadas. El dispositivo se reiniciará en 3 segundos.");
        delay(3000);
        ESP.restart();
      }
    }
};


// --- CÓDIGO PRINCIPAL ---
void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(RESET_BUTTON_PIN, INPUT_PULLUP); // Configurar el boton de reinicio

  // Comprobar si ya tenemos credenciales WiFi guardadas
  preferences.begin("wifi-creds", true); // `true` para modo solo lectura
  String savedSsid = preferences.getString("ssid", "");
  String savedPass = preferences.getString("pass", "");
  preferences.end();

  if (savedSsid == "") {
    // No hay credenciales, iniciar modo de aprovisionamiento BLE
    Serial.println("No se encontraron credenciales WiFi. Iniciando modo de configuración BLE...");
    setupBLEProvisioning();
  } else {
    // Hay credenciales, iniciar modo normal
    Serial.println("Credenciales WiFi encontradas. Iniciando modo normal...");
    startNormalMode(savedSsid, savedPass);
  }
}

void loop() {
  checkResetButton();
  // En modo normal, el loop hace su trabajo. En modo BLE, no hace nada
  // ya que la lógica está en los callbacks de BLE.
  if (WiFi.isConnected()) {

    

    if (!client.connected()) {
      checkResetButton();
      reconnect();
    }
    client.loop();
    handleSensorLogic();
    
    if (millis() - lastPublishTime > TELEMETRY_INTERVAL) {
      publishTelemetry();
      lastPublishTime = millis();
    }
  }
}

// --- FUNCIONES ---
void checkResetButton() {
  // Leemos el estado del botón. LOW significa que está presionado.
  if (digitalRead(RESET_BUTTON_PIN) == LOW) {
    // Si es la primera vez que detectamos la pulsación, guardamos el tiempo
    if (buttonPressStartTime == 0) {
      Serial.println("Botón de reseteo presionado. Mantén presionado por 5 segundos...");
      buttonPressStartTime = millis();
    }
    // Si se ha mantenido presionado por más de 5 segundos y no hemos actuado ya
    if (millis() - buttonPressStartTime > LONG_PRESS_DURATION && !resetActionTriggered) {
      clearWifiCredentialsAndReboot();
      resetActionTriggered = true; // Marcamos que la acción ya se disparó
    }
  } else {
    // Si el botón se suelta, reiniciamos el contador
    if (buttonPressStartTime > 0) {
      Serial.println("Botón de reseteo liberado antes de tiempo.");
    }
    buttonPressStartTime = 0;
    resetActionTriggered = false;
  }
}

void clearWifiCredentialsAndReboot() {
  Serial.println("¡ACCIÓN DE RESETEO ACTIVADA!");
  Serial.println("Borrando credenciales WiFi guardadas...");
  
  preferences.begin("wifi-creds", false); // Abrir en modo escritura
  preferences.clear();                    // Borrar todas las claves
  preferences.end();
  
  Serial.println("Credenciales borradas. Reiniciando en 3 segundos para entrar en modo de configuración...");
  delay(3000);
  ESP.restart();
}

void setupBLEProvisioning() { // <-- NUEVO
  // Crear el dispositivo BLE
  BLEDevice::init(THING_NAME); // Nombre que aparecerá en la app

  // Crear el servidor BLE
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Crear una Característica BLE (el "buzón" para escribir datos)
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  pCharacteristic->setCallbacks(new MyCallbacks()); // Asignar nuestro manejador de eventos

  // Iniciar el servicio y el advertising
  pService->start();
  // Añadir el UUID del servicio al anuncio para que la app lo pueda filtrar
  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pServer->getAdvertising()->start();

  Serial.println("Servidor BLE iniciado. Esperando conexión desde la app...");
}


void startNormalMode(String ssid, String password) {
  setupTopics();

  pinMode(PIR_PIN, INPUT);
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  digitalWrite(RELAY1_PIN, LOW);
  digitalWrite(RELAY2_PIN, LOW);

  Wire.begin(I2C_SDA, I2C_SCL);
  if (!lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE)) {
    Serial.println(F("Error al inicializar BH1750."));
  } else {
    Serial.println(F("Sensor de luz BH1750 OK."));
  }
  
  connectAWS(ssid, password);
}


void connectAWS(String ssid, String password) { // Modificado para recibir credenciales
  WiFi.begin(ssid.c_str(), password.c_str());
  Serial.println("Conectando a WiFi...");
  Serial.println("Credenciales: ");
  Serial.println(ssid.c_str());
  Serial.println(password.c_str());
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Conectado.");
  Serial.print("Dirección IP: ");
  Serial.println(WiFi.localIP());
  
  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);

  client.setServer(AWS_IOT_ENDPOINT, 8883);
  client.setCallback(messageHandler);

  reconnect();
}

// El resto de funciones (reconnect, handleSensorLogic, publish, etc.)
// permanecen exactamente iguales a como las tenías.
// ... (pega aquí el resto de tus funciones sin cambios) ...
void setupTopics() {
 sprintf(TELEMETRY_TOPIC, "telemetria/%s/datos", THING_NAME);
 sprintf(EVENTS_TOPIC, "eventos/%s/alerta", THING_NAME);
 sprintf(COMMANDS_TOPIC, "comandos/%s/set", THING_NAME);
 sprintf(CONNECTION_STATE_TOPIC, "dispositivos/%s/estado_conexion", THING_NAME);
}

void reconnect() {
 Serial.println("Conectando a AWS IoT...");
 
 // Configurar Last Will and Testament (LWT)
 const char* lwt_payload = "{\"online\": false}";
 
 while (!client.connected()) {
   if (client.connect(THING_NAME, "", "", CONNECTION_STATE_TOPIC, 1, true, lwt_payload)) {
     Serial.println("Conectado a AWS IoT!");
     
     // Publicar estado "online"
     client.publish(CONNECTION_STATE_TOPIC, "{\"online\": true}", true); // `true` para mensaje retenido
     
     // Suscribirse al tópico de comandos
     client.subscribe(COMMANDS_TOPIC);
     Serial.print("Suscrito a: ");
     Serial.println(COMMANDS_TOPIC);
     
   } else {
     Serial.print("Fallo, rc=");
     Serial.print(client.state());
     Serial.println(" reintentando en 5 seg...");
     delay(5000);
   }
 }
}

void handleSensorLogic() {
 bool currentMotion = digitalRead(PIR_PIN) == HIGH;
 currentLux = lightMeter.readLightLevel();

 if (currentMotion && !lastMotionState) {
   Serial.println("Evento: Movimiento detectado.");
   publishEvent("MOVIMIENTO_DETECTADO", "Se ha detectado movimiento.");
   lastMotionTime = millis();
 }
 lastMotionState = currentMotion;

 if (autoMode) {
   if (currentMotion && currentLux < LUX_THRESHOLD) {
     if (!relay1State) {
       Serial.println("Modo Auto: Encendiendo Luz 1...");
       controlLight("luz1", HIGH);
     }
   } else if (millis() - lastMotionTime > MOTION_TIMEOUT && lastMotionTime != 0) {
     if (relay1State) {
       Serial.println("Modo Auto: Apagando Luz 1 por timeout...");
       controlLight("luz1", LOW);
     }
   }
 }
}

void controlLight(const char* lightId, bool state) {
 if (strcmp(lightId, "luz1") == 0) {
   relay1State = state;
   digitalWrite(RELAY1_PIN, state);
 } else if (strcmp(lightId, "luz2") == 0) {
   relay2State = state;
   digitalWrite(RELAY2_PIN, state);
 }
 // Publicar inmediatamente la telemetría para reflejar el cambio en la app
 publishTelemetry();
}

void publishTelemetry() {
 StaticJsonDocument<512> doc;
 
 JsonObject luces = doc.createNestedObject("estado_luces");
 luces["luz1"] = relay1State ? "ON" : "OFF";
 luces["luz2"] = relay2State ? "ON" : "OFF";

 JsonObject sensores = doc.createNestedObject("sensores");
 sensores["movimiento"] = lastMotionState;
 sensores["lux"] = currentLux;
 
 JsonObject config = doc.createNestedObject("config");
 config["modo_auto"] = autoMode;

 doc["timestamp"] = millis(); // O usar un RTC

 char jsonBuffer[512];
 serializeJson(doc, jsonBuffer);

 client.publish(TELEMETRY_TOPIC, jsonBuffer);
 Serial.print("Publicando Telemetría: ");
 Serial.println(jsonBuffer);
}

void publishEvent(const char* eventType, const char* message) {
 StaticJsonDocument<256> doc;
 doc["tipo_evento"] = eventType;
 doc["mensaje"] = message;
 doc["timestamp"] = millis();

 char jsonBuffer[256];
 serializeJson(doc, jsonBuffer);
 
 client.publish(EVENTS_TOPIC, jsonBuffer);
 Serial.print("Publicando Evento: ");
 Serial.println(jsonBuffer);
}

void messageHandler(char* topic, byte* payload, unsigned int length) {
 Serial.print("Comando recibido en [");
 Serial.print(topic);
 Serial.println("]: ");

 StaticJsonDocument<256> doc;
 DeserializationError error = deserializeJson(doc, payload, length);

 if (error) {
   Serial.print(F("deserializeJson() falló: "));
   Serial.println(error.c_str());
   return;
 }

 const char* componente = doc["componente"];
 
 if (strcmp(componente, "luz1") == 0) {
   bool value = (strcmp(doc["valor"], "ON") == 0);
   Serial.println("...Orden para luz1");
   autoMode = false; // Comando manual desactiva modo auto
   controlLight("luz1", value);
 } 
 else if (strcmp(componente, "luz2") == 0) {
   bool value = (strcmp(doc["valor"], "ON") == 0);
   Serial.println("...Orden para luz2");
   controlLight("luz2", value);
 }
 else if (strcmp(componente, "modo_auto") == 0) {
   bool value = doc["valor"];
   Serial.println("...Orden para modo_auto");
   autoMode = value;
   publishTelemetry(); // Publicar el cambio de estado de la config
 }
}