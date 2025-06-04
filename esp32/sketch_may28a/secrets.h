#ifndef SECRETS_H
#define SECRETS_H

// WiFi
#define WIFI_SSID "Redmi Note 14 5G"
#define WIFI_PASSWORD "vitapanocca"

// AWS IoT Core Endpoint
#define AWS_IOT_ENDPOINT "a3fgjlvszr1rqj-ats.iot.us-east-2.amazonaws.com" // ¡Reemplaza con tu endpoint!

// AWS IoT Core Thing Name
#define THING_NAME "AsistIoT_ESP32_PE" 

// Publicaciones MQTT
#define AWS_IOT_PUBLISH_TOPIC_LUZ1 "hogar/" THING_NAME "/luz1/estado"
#define AWS_IOT_PUBLISH_TOPIC_LUZ2 "hogar/" THING_NAME "/luz2/estado"
#define AWS_IOT_PUBLISH_TOPIC_ALERTA "hogar/" THING_NAME "/sensor_movimiento/alerta"

// Suscripciones MQTT (para comandos)
#define AWS_IOT_SUBSCRIBE_TOPIC_LUZ1 "hogar/" THING_NAME "/luz1/comandos"
#define AWS_IOT_SUBSCRIBE_TOPIC_LUZ2 "hogar/" THING_NAME "/luz2/comandos"

// Certificado Raíz de Amazon (Generalmente el Amazon Root CA 1 o 3 para IoT)
const char AWS_CERT_CA[] = R"EOF(
-----BEGIN CERTIFICATE-----

-----END CERTIFICATE-----
)EOF";

// Certificado de tu Dispositivo (Thing)
const char AWS_CERT_CRT[] = R"EOF(
-----BEGIN CERTIFICATE-----

-----END CERTIFICATE-----
)EOF";

// Clave Privada de tu Dispositivo (Thing)
const char AWS_CERT_PRIVATE[] = R"EOF(
-----BEGIN RSA PRIVATE KEY-----

-----END RSA PRIVATE KEY-----
)EOF";

#endif