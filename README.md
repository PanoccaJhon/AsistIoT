# AsistIoT: Asistente Inteligente para el Hogar  
**Control, Automatización y Voz**

**AsistIoT** es una solución completa de Internet de las Cosas (IoT) para el control y monitoreo inteligente del hogar. Este proyecto integra un dispositivo físico basado en **ESP32**, una potente infraestructura en la nube y una aplicación móvil multiplataforma, permitiendo un control total sobre tu entorno a través de toques, automatización y comandos de voz.

---

## ✨ Características Principales

- **Control Remoto e Inteligente:** Enciende y apaga luces desde cualquier lugar del mundo.  
- **Modo Automático:** Activa luces basándose en la detección de movimiento y nivel de luz.  
- **Aprovisionamiento Seguro por Bluetooth:** Configura nuevos dispositivos en tu red WiFi usando BLE.  
- **Control por Voz Avanzado:** Integración con Google Cloud Speech-to-Text y Dialogflow.  
- **Monitoreo en Tiempo Real:** Visualiza el estado de conexión y sensores desde la app.  
- **Historial de Eventos:** Revisa eventos de movimiento registrados.  
- **Gestión de Usuarios Segura:** Autenticación completa con AWS Cognito.  
- **Interfaz Moderna:** Aplicación Flutter, limpia y responsiva, para Android e iOS.  

---

## 📖 Guía de Instalación y Uso (Para el Usuario Final)

### ¿Qué necesitas?

- El dispositivo físico AsistIoT.  
- Un smartphone (Android o iOS).  
- Una red WiFi de 2.4 GHz con acceso a internet.  

---

### 🚀 Paso 1: Instala la Aplicación AsistIoT

**Android:**  
Puedes descargar el archivo de instalación (APK) desde este repositorio.  
➡️ [Descargar la aplicación (app.apk)](./build_outputs/app-release.apk)

> _Nota: Es posible que necesites habilitar la opción "Instalar desde fuentes desconocidas" en la configuración de tu teléfono._

**iOS:**  
Disponible próximamente en la App Store.

---

### 👤 Paso 2: Crea tu Cuenta

1. Abre la aplicación AsistIoT.  
2. Pulsa **"Registrarse"**.  
3. Ingresa tu correo electrónico y una contraseña segura.  
4. Revisa tu correo y coloca el código de confirmación en la app.  
5. Inicia sesión con tus nuevas credenciales.

---

### 🔧 Paso 3: Configura tu Dispositivo AsistIoT

1. Enchufa tu dispositivo AsistIoT.  
2. La pantalla OLED mostrará "Modo de Configuración BLE".  
3. Asegúrate de que el Bluetooth del teléfono esté activado.  
4. Pulsa **"+"** en la app para añadir un dispositivo.  
5. Selecciona **"AsistIoT_ESP32_PE"** de la lista.  
6. Ingresa el nombre y contraseña de tu red WiFi.  
7. Pulsa **"Conectar"**.  
8. El dispositivo se reiniciará y se conectará a la nube. ¡Listo!

---

### 🏠 Paso 4: ¡Disfruta de tu Hogar Inteligente!

- **Control Manual:** Toca para encender o apagar luces.  
- **Modo Automático:** El dispositivo tomará decisiones inteligentes.  
- **Control por Voz:** Usa comandos como _"enciende la luz del dormitorio"_.  
- **Historial de Movimiento:** Revisa registros de detección.  
- **Refrescar Estado:** Desliza hacia abajo para actualizar sensores.

---

## 🛠️ Documentación para Desarrolladores

### 🧱 Pila Tecnológica

- **Firmware (ESP32):**  
  C++, Arduino, PubSubClient, ArduinoJson, Adafruit GFX/SSD1306, BLEDevice.  

- **Nube (AWS):**  
  IoT Core, DynamoDB, Lambda (Python), API Gateway, Cognito.  

- **Nube (GCP):**  
  Cloud Speech-to-Text, Dialogflow.  

- **App Móvil (Flutter):**  
  Provider, http, googleapis_auth, record, google_speech.

---

### 🧩 Arquitectura del Sistema

#### **Dispositivo (ESP32):**  
Cliente MQTT → Publica telemetría y eventos → Se suscribe a comandos desde AWS IoT Core.

#### **Nube (AWS + GCP):**

- **AWS IoT Core:** Broker MQTT central.  
- **DynamoDB:** Persistencia de datos.  
- **API Gateway:** Endpoints RESTful protegidos por Cognito.  
- **Lambda:** Lógica de negocio.  
- **GCP:**  
  - Speech-to-Text: Transcripción de voz.  
  - Dialogflow: Procesamiento del lenguaje natural (NLU).

#### **Aplicación (Flutter):**  
MVVM + JWT para autenticación segura contra API Gateway.

---

## ⚙️ Configuración del Entorno de Desarrollo

### 🔙 Backend

1. Configura un **User Pool en Cognito**.  
2. Crea las siguientes tablas en **DynamoDB**:  
   - `AsistIoT_DeviceData`  
   - `AsistIoT_DeviceConnectionStatus`  
   - `AsistIoT_MotionHistory`  
3. Despliega funciones **Lambda** en Python.  
4. Configura **API Gateway** con endpoints REST y vinculación con Lambda y Cognito.  
5. En **AWS IoT Core**:  
   - Crea un "Thing"  
   - Genera certificados  
   - Define Reglas de IoT.  
6. En **Google Cloud Platform**:  
   - Crea un proyecto  
   - Habilita APIs necesarias  
   - Configura Dialogflow y credenciales JSON.

---

### 🔌 Firmware (ESP32)

1. Abre el archivo `.ino` en Arduino IDE.  
2. Instala librerías requeridas.  
3. Crea un archivo `secrets.h` con certificados de AWS y endpoint MQTT.  
4. Sube el firmware al ESP32.

---

### 📱 Aplicación Flutter

1. Clona el repositorio.  
2. Ejecuta `amplify init` para generar `amplifyconfiguration.dart`.  
3. Crea carpeta `assets/` si no existe.  
4. Coloca tu archivo JSON de credenciales de GCP en esa carpeta.  
5. Declara `assets/` en `pubspec.yaml`.  
6. Actualiza el `projectId` en `lib/core/services/voice_service.dart`.  
7. Ejecuta:  
   ```bash
   flutter pub get
   flutter run
