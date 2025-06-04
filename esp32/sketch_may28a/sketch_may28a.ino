#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h> // Para JSON

#include "secrets.h" // Aquí estarán tus credenciales y certificados

// Pines GPIO para el relé y el sensor PIR
const int RELAY_PIN_LUZ1 = 8; // GPIO para el relé de la Luz 1
const int RELAY_PIN_LUZ2 = 9; // GPIO para el relé de la Luz 2
const int PIR_PIN = 2;        // GPIO para el sensor PIR

// Variables de estado de las luces (true = ON, false = OFF)
bool luz1_estado = false;
bool luz2_estado = false;

// Variables para el sensor de movimiento
unsigned long lastMotionTime = 0;
const long motionCooldown = 5000; // 5 segundos de 'enfriamiento' para alertas (ajustable)
bool motionDetected = false;

// Cliente WiFi seguro para MQTT
WiFiClientSecure net;
PubSubClient client(net);

// ====================================================================================
// Funciones de Conexión
// ====================================================================================

void connectWiFi() {
    Serial.print("Conectando a WiFi...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi Conectado!");
    Serial.print("Dirección IP: ");
    Serial.println(WiFi.localIP());
}


// ====================================================================================
// Funciones de Publicación MQTT
// ====================================================================================

void publishLightState(int lightNum, bool state, const char* origin = "manual") {
    StaticJsonDocument<256> doc; // Tamaño del documento JSON, ajusta si es necesario
    doc["timestamp"] = String(millis());
    doc["device_id"] = THING_NAME;
    doc["light_num"] = lightNum;
    doc["state"] = state ? "ON" : "OFF";
    doc["origin"] = origin; // "manual", "cloud", "motion"

    char jsonBuffer[256];
    serializeJson(doc, jsonBuffer);

    String topic = "hogar/" THING_NAME "/luz" + String(lightNum) + "/estado";
    if (client.publish(topic.c_str(), jsonBuffer)) {
        Serial.print("Publicado estado de Luz "); Serial.print(lightNum); Serial.print(" ("); Serial.print(state ? "ON" : "OFF"); Serial.println(")");
    } else {
        Serial.print("Fallo al publicar estado de Luz "); Serial.println(lightNum);
    }
}

void publishMotionEvent(const char* alertType = "detection") {
    StaticJsonDocument<256> doc;
    doc["timestamp"] = String(millis());
    doc["device_id"] = THING_NAME;
    doc["event_type"] = "motion_detected";
    doc["alert_type"] = alertType; // "detection", "cleared"

    char jsonBuffer[256];
    serializeJson(doc, jsonBuffer);

    if (client.publish(AWS_IOT_PUBLISH_TOPIC_ALERTA, jsonBuffer)) {
        Serial.print("Publicada alerta de movimiento ("); Serial.print(alertType); Serial.println(")");
    } else {
        Serial.println("Fallo al publicar alerta de movimiento.");
    }
}

// ====================================================================================
// Función de Callback MQTT (Manejo de Comandos desde la Nube)
// ====================================================================================

void messageHandler(char* topic, byte* payload, unsigned int length) {
    Serial.print("Mensaje recibido en tema: ");
    Serial.println(topic);
    Serial.print("Payload: ");
    for (int i = 0; i < length; i++) {
        Serial.print((char)payload[i]);
    }
    Serial.println();

    // Parsear el JSON del payload
    StaticJsonDocument<256> doc;
    DeserializationError error = deserializeJson(doc, payload);

    if (error) {
        Serial.print(F("Fallo al parsear JSON: "));
        Serial.println(error.f_str());
        return;
    }

    const char* accion = doc["accion"];

    if (strcmp(topic, AWS_IOT_SUBSCRIBE_TOPIC_LUZ1) == 0) {
        if (strcmp(accion, "encender") == 0) {
            digitalWrite(RELAY_PIN_LUZ1, LOW); // Relé de activación BAJA
            luz1_estado = true;
            Serial.println("Luz 1 Encendida por la Nube.");
            publishLightState(1, true, "cloud"); // Reporta el nuevo estado
        } else if (strcmp(accion, "apagar") == 0) {
            digitalWrite(RELAY_PIN_LUZ1, HIGH); // Relé de activación BAJA
            luz1_estado = false;
            Serial.println("Luz 1 Apagada por la Nube.");
            publishLightState(1, false, "cloud"); // Reporta el nuevo estado
        }
    } else if (strcmp(topic, AWS_IOT_SUBSCRIBE_TOPIC_LUZ2) == 0) {
        if (strcmp(accion, "encender") == 0) {
            digitalWrite(RELAY_PIN_LUZ2, LOW); // Relé de activación BAJA
            luz2_estado = true;
            Serial.println("Luz 2 Encendida por la Nube.");
            publishLightState(2, true, "cloud"); // Reporta el nuevo estado
        } else if (strcmp(accion, "apagar") == 0) {
            digitalWrite(RELAY_PIN_LUZ2, HIGH); // Relé de activación BAJA
            luz2_estado = false;
            Serial.println("Luz 2 Apagada por la Nube.");
            publishLightState(2, false, "cloud"); // Reporta el nuevo estado
        }
    }
}


void connectAWS() {
    // Configura certificados
    net.setCACert(AWS_CERT_CA);
    net.setCertificate(AWS_CERT_CRT);
    net.setPrivateKey(AWS_CERT_PRIVATE);

    // Configura el cliente MQTT
    client.setServer(AWS_IOT_ENDPOINT, 8883); // Puerto MQTT seguro es 8883
    client.setCallback(messageHandler); // Asigna la función para manejar mensajes entrantes

    Serial.println("Conectando a AWS IoT Core...");
    while (!client.connected()) {
        if (client.connect(THING_NAME)) { // Conecta usando el nombre del Thing
            Serial.println("Conectado a AWS IoT Core!");
            // Suscribirse a los temas de comandos después de la conexión exitosa
            client.subscribe(AWS_IOT_SUBSCRIBE_TOPIC_LUZ1);
            Serial.print("Suscrito a: "); Serial.println(AWS_IOT_SUBSCRIBE_TOPIC_LUZ1);
            client.subscribe(AWS_IOT_SUBSCRIBE_TOPIC_LUZ2);
            Serial.print("Suscrito a: "); Serial.println(AWS_IOT_SUBSCRIBE_TOPIC_LUZ2);

            // Publica el estado inicial de las luces al reconectar
            publishLightState(1, luz1_estado);
            publishLightState(2, luz2_estado);

        } else {
            Serial.print("Fallo en la conexión a AWS IoT Core, rc=");
            Serial.print(client.state());
            Serial.println(" Reintentando en 5 segundos...");
            delay(5000);
        }
    }
}

// ====================================================================================
// Funciones de Inicialización
// ====================================================================================

void setup() {
    Serial.begin(115200);
    delay(100);
    Serial.println("Setup");
    // Configurar pines de los relés como OUTPUT y apagarlos inicialmente (HIGH si es activación BAJA)
    pinMode(RELAY_PIN_LUZ1, OUTPUT);
    digitalWrite(RELAY_PIN_LUZ1, HIGH); // Asegura que la luz esté apagada al inicio
    pinMode(RELAY_PIN_LUZ2, OUTPUT);
    digitalWrite(RELAY_PIN_LUZ2, HIGH); // Asegura que la luz esté apagada al inicio

    // Configurar pin del sensor PIR como INPUT
    pinMode(PIR_PIN, INPUT);

    connectWiFi();
    connectAWS();
}

// ====================================================================================
// Bucle Principal
// ====================================================================================

void loop() {
    if (!client.connected()) {
        connectAWS(); // Reintentar conexión si se pierde
    }
    client.loop(); // Permite que el cliente MQTT procese mensajes entrantes y mantenga la conexión

    // Leer el estado del sensor PIR
    int pirState = digitalRead(PIR_PIN);

    // Lógica para el sensor de movimiento
    if (pirState == HIGH) {
        if (!motionDetected) { // Si es la primera detección o después de un cooldown
            Serial.println("Movimiento detectado!");
            publishMotionEvent("detection"); // Publica alerta de detección

            // Aquí puedes decidir encender automáticamente una luz al detectar movimiento
            // Por ejemplo, encender la Luz 1 si está apagada
            if (!luz1_estado) {
                digitalWrite(RELAY_PIN_LUZ1, LOW); // Enciende la Luz 1
                luz1_estado = true;
                Serial.println("Luz 1 encendida por movimiento.");
                publishLightState(1, true, "motion"); // Reporta el nuevo estado
            }
            lastMotionTime = millis(); // Actualiza el tiempo de la última detección
            motionDetected = true;
        }
    } else { // Si no hay movimiento
        if (motionDetected && (millis() - lastMotionTime > motionCooldown)) {
            Serial.println("Movimiento cesado.");
            publishMotionEvent("cleared"); // Publica alerta de movimiento cesado
            motionDetected = false; // Resetear la bandera
            // Opcional: Apagar la luz automáticamente después de un tiempo sin movimiento
            // if (luz1_estado) {
            //     digitalWrite(RELAY_PIN_LUZ1, HIGH);
            //     luz1_estado = false;
            //     Serial.println("Luz 1 apagada por ausencia de movimiento.");
            //     publishLightState(1, false, "motion_timeout");
            // }
        }
    }

    delay(100); // Pequeño delay para evitar sobrecargar el ESP32
}