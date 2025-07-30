# AsistIoT: Asistente Inteligente para el Hogar

![AsistIoT Banner](https://i.imgur.com/your-banner-image.png)
*[Imagen de un banner promocional para AsistIoT]*

**AsistIoT** es una solución completa de Internet de las Cosas (IoT) para el control y monitoreo inteligente del hogar. Este proyecto integra un dispositivo físico basado en ESP32, una potente infraestructura en la nube y una aplicación móvil multiplataforma, permitiendo un control total sobre tu entorno a través de toques, automatización y comandos de voz.

## ✨ Características Principales

* **Control Remoto e Inteligente:** Enciende y apaga luces desde cualquier lugar del mundo.
* **Modo Automático:** Deja que el sistema active las luces de forma inteligente basándose en la detección de movimiento y el nivel de luz ambiental.
* **Aprovisionamiento Seguro por Bluetooth:** Configura fácilmente nuevos dispositivos en tu red WiFi de forma segura a través de Bluetooth Low Energy (BLE).
* **Control por Voz Avanzado:** Utiliza tu voz para controlar los dispositivos gracias a la integración con **Google Cloud Speech-to-Text** y **Dialogflow**.
* **Monitoreo en Tiempo Real:** Conoce el estado de conexión de tus dispositivos y visualiza los datos de los sensores directamente en la app.
* **Historial de Eventos:** Consulta un registro de todos los eventos de movimiento detectados por tus sensores.
* **Gestión de Usuarios Segura:** Sistema completo de autenticación (registro, inicio de sesión, confirmación) manejado por AWS Cognito.
* **Interfaz de Usuario Moderna:** Una aplicación limpia y reactiva construida con Flutter, disponible para Android e iOS.

---

## 📖 Guía de Instalación y Uso (Para el Usuario Final)

¡Bienvenido a AsistIoT! Sigue estos sencillos pasos para configurar tu dispositivo y empezar a disfrutar de un hogar más inteligente.

### ¿Qué necesitas?

* El dispositivo físico AsistIoT.
* Un smartphone (Android o iOS).
* Una red WiFi de 2.4 GHz con conexión a internet.

### Paso 1: Instala la Aplicación AsistIoT

1.  Descarga la aplicación AsistIoT desde la **Google Play Store** (para Android) o la **App Store** (para iOS).
2.  Instálala en tu smartphone.

### Paso 2: Crea tu Cuenta

1.  Abre la aplicación AsistIoT.
2.  Toca el botón **"Registrarse"**.
3.  Introduce tu dirección de correo electrónico y crea una contraseña segura.
4.  Recibirás un **código de confirmación** en tu correo. Introdúcelo en la aplicación para verificar tu cuenta.
5.  Una vez verificado, inicia sesión con tu nuevo usuario y contraseña.

### Paso 3: Configura tu Dispositivo AsistIoT por Primera Vez

Esta configuración inicial solo se realiza una vez.

1.  **Enchufa tu dispositivo AsistIoT** a una fuente de alimentación. La pantalla OLED se encenderá y mostrará un mensaje indicando que está en **"Modo de Configuración BLE"**.
2.  En la aplicación, asegúrate de que el Bluetooth de tu teléfono esté activado.
3.  Toca el botón **"+"** o **"Añadir Dispositivo"**.
4.  La aplicación buscará dispositivos cercanos. Selecciona tu dispositivo **"AsistIoT_ESP32_PE"** de la lista.
5.  Se te pedirá que introduzcas el **nombre y la contraseña de tu red WiFi**.
6.  Toca **"Conectar"**. La aplicación enviará las credenciales al dispositivo de forma segura.
7.  El dispositivo se reiniciará y su pantalla mostrará el estado mientras se conecta a tu WiFi y a la nube. ¡Y listo!

### Paso 4: ¡Disfruta de tu Hogar Inteligente!

Una vez configurado, tu dispositivo aparecerá en la pantalla principal de la aplicación.

* **Toca el dispositivo** para acceder a la pantalla de detalles.
* **Controla las luces:** Usa los interruptores para encender o apagar las luces manualmente.
* **Activa el Modo Automático:** Permite que el dispositivo controle las luces por ti.
* **Usa tu voz:** Toca el **botón del micrófono** y di comandos como *"enciende la luz del dormitorio"* o *"activa el modo automático"*.
* **Consulta el historial:** Ve al historial para ver cuándo se detectó movimiento.
* **Refresca el estado:** Desliza el dedo hacia abajo en la pantalla de detalles para actualizar los datos de los sensores en tiempo real.

### Solución de Problemas

* **¿El dispositivo no se conecta?** Asegúrate de que la contraseña de tu WiFi sea correcta y que la red sea de 2.4 GHz.
* **¿Quieres cambiar de red WiFi?** Mantén presionado el botón físico del dispositivo AsistIoT durante 5 segundos. La pantalla indicará que las credenciales se han borrado y el dispositivo volverá al modo de configuración. Repite el Paso 3.

---

## 🛠️ Documentación para Desarrolladores

Esta sección contiene información sobre la arquitectura y cómo configurar el entorno de desarrollo.

### Pila Tecnológica

* **Firmware (ESP32):** C++ (Arduino), PubSubClient, ArduinoJson, Adafruit GFX/SSD1306, BLEDevice.
* **Nube (AWS):** IoT Core, DynamoDB, Lambda (Python), API Gateway, Cognito.
* **Nube (GCP):** Cloud Speech-to-Text, Dialogflow.
* **App Móvil (Flutter):** Provider, http, googleapis_auth, record, google_speech.

### Arquitectura del Sistema

El sistema sigue una arquitectura desacoplada y escalable:

1.  **Dispositivo (ESP32):** Actúa como un cliente MQTT que se comunica exclusivamente con AWS IoT Core. Publica telemetría y eventos, y se suscribe a un tópico de comandos.
2.  **Nube (AWS + GCP):**
    * **AWS IoT Core** es el broker MQTT central. Las **Reglas de IoT** procesan los mensajes y los persisten en **DynamoDB**.
    * La **API Gateway** expone endpoints RESTful protegidos por **Cognito**.
    * Las funciones **Lambda** contienen la lógica de negocio (consultar DynamoDB, publicar en IoT Core).
    * Para los comandos de voz, la app utiliza **GCP Speech-to-Text** para la transcripción y **Dialogflow** para la NLU. El resultado se envía a la API de AWS.
3.  **Aplicación (Flutter):** Sigue un patrón MVVM. Se autentica con **Cognito** y utiliza el token JWT para realizar llamadas seguras a la API Gateway.

### Configuración del Entorno de Desarrollo

1.  **Backend:**
    * Configura un User Pool en **Cognito**.
    * Crea las tres tablas en **DynamoDB** (`AsistIoT_DeviceData`, `AsistIoT_DeviceConnectionStatus`, `AsistIoT_MotionHistory`).
    * Despliega las funciones **Lambda** en Python y asígnales los roles de IAM necesarios.
    * Configura la **API Gateway** con los endpoints y la integración con Lambda y Cognito.
    * En **IoT Core**, crea un "Thing", genera los certificados y configura las Reglas de IoT.
    * En **GCP**, crea un proyecto, habilita las APIs, crea un agente de Dialogflow y genera un archivo de credenciales de cuenta de servicio.
2.  **Firmware (ESP32):**
    * Abre el sketch `.ino` en la IDE de Arduino.
    * Instala las librerías requeridas desde el Gestor de Librerías.
    * Crea un archivo `secrets.h` en la carpeta del sketch para almacenar los certificados de AWS y el endpoint de IoT.
    * Carga el firmware al ESP32.
3.  **Aplicación (Flutter):**
    * Clona el repositorio.
    * Configura Amplify con `amplify init` para generar `amplifyconfiguration.dart`.
    * Coloca el archivo de credenciales de GCP en la carpeta `assets/`.
    * Actualiza el `projectId` de GCP en `lib/core/services/voice_service.dart`.
    * Ejecuta `flutter pub get`.
    * Ejecuta la aplicación en un dispositivo físico con `flutter run`.
