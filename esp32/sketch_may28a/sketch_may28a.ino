// --- LIBRERÍAS ---
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <BH1750.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>


#include "secrets.h"
#include "graphics.h"

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// --- PINES Y CONFIGURACIÓN ---
#define PIR_PIN 2
#define RELAY1_PIN 0
#define RELAY2_PIN 1
#define I2C_SDA 6
#define I2C_SCL 7
#define RESET_BUTTON_PIN 3

#define SCREEN_WIDTH 128 // Ancho de la pantalla OLED
#define SCREEN_HEIGHT 64 // Alto de la pantalla OLED
#define OLED_RESET -1    // Pin de reset (-1 si no se usa)

#define LUX_THRESHOLD 5
#define TELEMETRY_INTERVAL 30000
#define MOTION_TIMEOUT 60000
#define LONG_PRESS_DURATION 5000

// --- CONFIGURACIÓN BLE
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
char* msg_main = "- - - - - - - - ...";
bool pub_state = false;
bool sub_state = false;

WiFiClientSecure net;
PubSubClient client(net);
BH1750 lightMeter;
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
Preferences preferences; // Objeto para almacenamiento persistente

// --- DECLARACIÓN DE FUNCIONES ---
void displayMessage(const char* message, int size = 1, bool clear = true);
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
void updateDisplay();
void startDisplay();

// --- Clase para manejar los eventos de escritura BLE ---
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue();

      if (value.length() > 0) {
        Serial.println("*********");
        Serial.print("Nuevo comando recibido: ");
        Serial.println(value.c_str());

        // Usamos ArduinoJson para parsear el comando
        JsonDocument doc;
        DeserializationError error = deserializeJson(doc, value);

        if (error) {
          Serial.print("deserializeJson() falló: ");
          Serial.println(error.c_str());
          return;
        }

        // LÓGICA CONDICIONAL: ¿Es un comando de credenciales o de reinicio?

        // 1. Si el JSON contiene la clave "ssid", guardamos las credenciales
        if (doc.containsKey("ssid")) {
          const char* ssid = doc["ssid"];
          const char* pass = doc["pass"];

          Serial.println("Guardando credenciales WiFi en NVS...");
          preferences.begin("wifi-creds", false);
          preferences.putString("ssid", ssid);
          preferences.putString("pass", pass);
          preferences.end();
          displayMessage("Credenciales guardadas. Esperando comando de reinicio.");
        }

        // 2. Si el JSON contiene la clave "action" y el valor es "restart"...
        if (doc.containsKey("action")) {
          const char* action = doc["action"];
          if (strcmp(action, "restart") == 0) {
            Serial.println("Comando de reinicio recibido. Reiniciando en 2 segundos...");
            delay(10000);
            ESP.restart();
          }
        }
        Serial.println("*********");
      }
      delay(100);
    }
};


// --- CÓDIGO PRINCIPAL ---
void setup() {
  Serial.begin(115200);
  delay(1000);

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { // El 0x3C es la dirección I2C común
    Serial.println(F("Fallo al iniciar la pantalla SSD1306"));
    // En un caso real, podrías querer detener el programa aquí
    // pero por ahora, solo lo reportamos.
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Dispositivo Iniciado");
  display.display();
  delay(2000); // Muestra el mensaje de inicio por 2 segundos

  pinMode(RESET_BUTTON_PIN, INPUT_PULLUP); // Configurar el boton de reinicio

  // Comprobar si ya tenemos credenciales WiFi guardadas
  preferences.begin("wifi-creds", true); // `true` para modo solo lectura
  String savedSsid = preferences.getString("ssid", "");
  String savedPass = preferences.getString("pass", "");
  preferences.end();

  if (savedSsid == "") {
    // No hay credenciales, iniciar modo de aprovisionamiento BLE
    displayMessage("No se encontraron credenciales WiFi. Iniciando modo de configuración BLE...");
    setupBLEProvisioning();
  } else {
    // Hay credenciales, iniciar modo normal
    displayMessage("Credenciales WiFi encontradas. Iniciando modo normal...");
    startNormalMode(savedSsid, savedPass);
  }
}

void loop() {
  checkResetButton();

  if (WiFi.status() != WL_CONNECTED) {
      delay(100);
      return;
  }

  // Lógica de reconexión y MQTT
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  handleSensorLogic();
  
  // Publicar telemetría
  if (millis() - lastPublishTime > TELEMETRY_INTERVAL) {
    publishTelemetry();
    lastPublishTime = millis();
  }

  static unsigned long lastDisplayUpdate = 0;
  // Actualizamos la pantalla cada segundo (1000 ms)
  if (millis() - lastDisplayUpdate > 1000) { 
    updateDisplay();
    lastDisplayUpdate = millis();
  }
}

// --- FUNCIONES ---
void displayMessage(const char* message, int size, bool clear) {
  if (clear) {
    display.clearDisplay();
  }
  display.setTextSize(size);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println(message);
  display.display(); // ¡Muy importante! Esto actualiza la pantalla.
}

void checkResetButton() {
  // Leemos el estado del botón. LOW significa que está presionado.
  if (digitalRead(RESET_BUTTON_PIN) == LOW) {
    // Si es la primera vez que detectamos la pulsación, guardamos el tiempo
    if (buttonPressStartTime == 0) {
      Serial.println("Boton de reseteo presionado. Manten presionado por 5 segundos...");
      displayMessage("Boton de reseteo presionado. Manten presionado por 5 segundos...");
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
  displayMessage("Credenciales borradas. Reiniciando en 3 segundos para entrar en modo de configuración...");
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

  startDisplay();
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
  displayMessage("Conectando a Wifi...");
  Serial.println("Credenciales: ");
  Serial.println(ssid.c_str());
  Serial.println(password.c_str());
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    checkResetButton();
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
     displayMessage("Conectado a AWS IoT!");
     
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

   if (currentLux < LUX_THRESHOLD) {
    if(!relay2State){
      Serial.println("Modo Auto: Encendiendo luz 2...");
      controlLight("luz2", HIGH);
    }
   } else {
    if(relay2State) {
      Serial.println("Modo Auto: Apagando luz 2...");
      controlLight("luz2", LOW);
    }
   }


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
 pub_state = true;
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
 pub_state = true;
 Serial.println(jsonBuffer);
}

void messageHandler(char* topic, byte* payload, unsigned int length) {
  Serial.print("Comando recibido en [");
  sub_state = true;
  Serial.print(topic);
  Serial.println("]: ");

  // Usamos un JsonDocument dinámico para mayor flexibilidad
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, payload, length);

  if (error) {
    Serial.print(F("deserializeJson() falló: "));
    Serial.println(error.c_str());
    return;
  }
  
  // Convertimos el documento a un objeto para poder iterar sobre él
  JsonObject command = doc.as<JsonObject>();
  
  // Iteramos sobre cada par clave-valor en el JSON recibido
  for (JsonPair kv : command) {
    const char* key = kv.key().c_str(); // ej: "luz1"
    
    if (strcmp(key, "luz1") == 0) {
      bool value = (strcmp(kv.value().as<const char*>(), "ON") == 0);
      Serial.println("...Orden para luz1");
      autoMode = false; // Comando manual desactiva modo auto
      controlLight("luz1", value);

    } else if (strcmp(key, "luz2") == 0) {
      bool value = (strcmp(kv.value().as<const char*>(), "ON") == 0);
      Serial.println("...Orden para luz2");
      controlLight("luz2", value);

    } else if (strcmp(key, "modo_auto") == 0) {
      bool value = kv.value().as<bool>();
      Serial.println("...Orden para modo_auto");
      autoMode = value;
    }
  }
  // Publicamos la telemetría para que la app refleje los cambios inmediatamente
  publishTelemetry(); 
}

void startDisplay(){
  display.clearDisplay();
  display.setCursor(2,0);
  display.print("Sincronizar con APP");
  display.drawBitmap(10,20, bluetooth_icon, 32,32, SSD1306_WHITE);
  display.display(); 
}

void updateDisplay() {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // --- BARRA DE ESTADO SUPERIOR ---

  // Ícono de WiFi: se muestra si estamos conectados
  if (WiFi.status() == WL_CONNECTED) {
    display.drawBitmap(0, 0, wifi_icon, 16, 16, SSD1306_WHITE);
  }

  // Pub / Sub state : icono de envio o recepcion de datos
  if (pub_state){
    display.drawBitmap(20,0, upload_icon, 16, 16, SSD1306_WHITE);
  }else if(sub_state){
    display.drawBitmap(20,0, download_icon, 16, 16, SSD1306_WHITE);
  }


  // Estado del Modo Auto en la esquina superior derecha
  display.setTextSize(1);
  display.setCursor(80, 5);
  display.print("AUTO:");
  display.print(autoMode ? "ON" : "OFF");

  // --- ÁREA DE DATOS PRINCIPAL ---
  display.setCursor(64, 22);
  display.setTextSize(2);
  display.print(String(currentLux, 0)); // Valor del sensor de luz en grande
  display.setTextSize(1);
  display.print(" lux");

  // Luz 1
  display.drawBitmap(7, 20, relay1State ? light_on_icon : light_off_icon, 16, 16, SSD1306_WHITE);
  display.setCursor(7, 40);
  display.print("Luz1");

  // Luz 2
  display.drawBitmap(39, 20, relay2State ? light_on_icon : light_off_icon, 16, 16, SSD1306_WHITE);
  display.setCursor(39, 40);
  display.print("Luz2");

  // --- BARRA DE ESTADO INFERIOR ---

  display.setCursor(1, 55);
  display.setTextSize(1);
  display.print(msg_main);

  // Actualizar la pantalla
  display.display();
}