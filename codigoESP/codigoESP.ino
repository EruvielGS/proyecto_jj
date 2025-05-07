#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <EEPROM.h>

// Configuración WiFi
const char* ssid = "Mega_2.4G_9714";
const char* password = "c9T7etAX";

// Configuración de pines (usando números GPIO)
#define SOIL_MOISTURE_PIN A0    // Pin analógico para sensor de humedad del suelo (A0 es el único en ESP8266)
#define DHT_PIN 2             // Pin digital para sensor DHT (equivale a D4 en algunas placas)
#define LIGHT_SENSOR_PIN 16     // Pin digital para fotorresistor (o usar otro pin analógico si está disponible) no tenemos parece (equivale a D0)
#define WATER_PUMP_PIN 5       // Pin digital para controlar el relé de la bomba de agua (equivale a D1)

// Configuración del sensor DHT
#define DHTTYPE DHT22           // Cambiar a DHT11 si usas ese sensor
DHT dht(DHT_PIN, DHTTYPE);

// Configuración del servidor web
ESP8266WebServer server(80);

// Identificación del dispositivo
String deviceId = "esp8266_001";
String deviceName = "ESP8266 Jardín";
String deviceType = "ESP8266";

// Variables para almacenar lecturas de sensores
float soilMoisture = 0.0;
float temperature = 0.0;
float lightLevel = 0.0;

// Variables para configuración de riego
int wateringThreshold = 30;     // Umbral de humedad para riego automático (%)
int wateringDuration = 5;       // Duración del riego en segundos
bool automaticWateringEnabled = true;
unsigned long lastWateringTime = 0;
bool isWatering = false;
unsigned long wateringStartTime = 0;
String currentPlantId = "";     // ID de la planta actual

// Estructura para almacenar configuración en EEPROM
struct Config {
  int wateringThreshold;
  int wateringDuration;
  bool automaticWateringEnabled;
  char plantId[32];
};

void setup() {
  // Inicializar comunicación serial
  Serial.begin(115200);
  Serial.println("\n\nIniciando Sistema de Riego con ESP8266...");
  
  // Configurar pines
  pinMode(SOIL_MOISTURE_PIN, INPUT);
  pinMode(LIGHT_SENSOR_PIN, INPUT);
  pinMode(WATER_PUMP_PIN, OUTPUT);
  digitalWrite(WATER_PUMP_PIN, LOW);  // Asegurarse de que la bomba esté apagada al inicio
  
  // Inicializar sensor DHT
  dht.begin();
  
  // Inicializar EEPROM
  EEPROM.begin(sizeof(Config));
  loadConfig();
  
  // Conectar a WiFi
  connectToWiFi();
  
  // Configurar endpoints del servidor
  setupServerEndpoints();
  
  // Iniciar servidor
  server.begin();
  Serial.println("Servidor HTTP iniciado");
  
  // Mostrar información del dispositivo
  Serial.println("Información del dispositivo:");
  Serial.println("ID: " + deviceId);
  Serial.println("Nombre: " + deviceName);
  Serial.println("Tipo: " + deviceType);
  Serial.println("IP: " + WiFi.localIP().toString());
}

void loop() {
  // Manejar solicitudes del cliente
  server.handleClient();
  
  // Leer sensores cada 5 segundos
  static unsigned long lastSensorReadTime = 0;
  if (millis() - lastSensorReadTime > 5000) {
    readSensors();
    lastSensorReadTime = millis();
    
    // Imprimir lecturas en el monitor serial
    Serial.println("Lecturas de sensores:");
    Serial.println("Humedad del suelo: " + String(soilMoisture) + "%");
    Serial.println("Temperatura: " + String(temperature) + "°C");
    Serial.println("Nivel de luz: " + String(lightLevel) + "%");
  }
  
  // Controlar el riego
  manageWatering();
}

void connectToWiFi() {
  Serial.print("Conectando a ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
    Serial.printf("Intentos: %d, Estado: %d\n", attempts, WiFi.status()); // Debug
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n¡Conectado!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nError: No se pudo conectar. Reiniciando...");
    ESP.restart(); // Reinicia el ESP si falla
  }
}

void setupServerEndpoints() {
  // Endpoint de información del dispositivo
  server.on("/info", HTTP_GET, []() {
    DynamicJsonDocument doc(256);
    doc["device_id"] = deviceId;
    doc["name"] = deviceName;
    doc["device_type"] = deviceType;
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  });
  
  // Endpoint de estado
  server.on("/status", HTTP_GET, []() {
    DynamicJsonDocument doc(256);
    doc["status"] = "online";
    doc["uptime"] = millis() / 1000;
    doc["is_watering"] = isWatering;
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  });
  
  // Endpoint de lecturas de sensores
  server.on("/sensors", HTTP_GET, []() {
    // Actualizar lecturas antes de responder
    readSensors();
    
    DynamicJsonDocument doc(256);
    doc["soil_moisture"] = soilMoisture;
    doc["temperature"] = temperature;
    doc["light_level"] = lightLevel;
    doc["last_watering"] = lastWateringTime / 1000;
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  });
  
  // Endpoint para activar el riego
  server.on("/water", HTTP_POST, []() {
    // Verificar si ya está regando
    if (isWatering) {
      server.send(409, "application/json", "{\"error\":\"Ya se está regando\"}");
      return;
    }
    
    // Parsear el cuerpo de la solicitud
    String body = server.arg("plain");
    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, body);
    
    if (error) {
      server.send(400, "application/json", "{\"error\":\"Formato JSON inválido\"}");
      return;
    }
    
    // Obtener duración y plantId
    int duration = doc["duration"] | wateringDuration;
    String plantId = doc["plant_id"] | "";
    
    // Iniciar riego
    startWatering(duration);
    currentPlantId = plantId;
    
    // Responder
    DynamicJsonDocument responseDoc(256);
    responseDoc["success"] = true;
    responseDoc["message"] = "Riego iniciado";
    responseDoc["duration"] = duration;
    
    String response;
    serializeJson(responseDoc, response);
    server.send(200, "application/json", response);
  });
  
  // Endpoint para configurar el riego automático
  server.on("/config", HTTP_POST, []() {
    // Parsear el cuerpo de la solicitud
    String body = server.arg("plain");
    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, body);
    
    if (error) {
      server.send(400, "application/json", "{\"error\":\"Formato JSON inválido\"}");
      return;
    }
    
    // Actualizar configuración
    if (doc.containsKey("watering_threshold")) {
      wateringThreshold = doc["watering_threshold"];
    }
    
    if (doc.containsKey("watering_duration")) {
      wateringDuration = doc["watering_duration"];
    }
    
    if (doc.containsKey("automatic_watering")) {
      automaticWateringEnabled = doc["automatic_watering"];
    }
    
    if (doc.containsKey("plant_id")) {
      currentPlantId = doc["plant_id"].as<String>();
    }
    
    // Guardar configuración
    saveConfig();
    
    // Responder
    DynamicJsonDocument responseDoc(256);
    responseDoc["success"] = true;
    responseDoc["message"] = "Configuración actualizada";
    responseDoc["watering_threshold"] = wateringThreshold;
    responseDoc["watering_duration"] = wateringDuration;
    responseDoc["automatic_watering"] = automaticWateringEnabled;
    
    String response;
    serializeJson(responseDoc, response);
    server.send(200, "application/json", response);
  });
  
  // Endpoint para obtener la configuración actual
  server.on("/config", HTTP_GET, []() {
    DynamicJsonDocument doc(256);
    doc["watering_threshold"] = wateringThreshold;
    doc["watering_duration"] = wateringDuration;
    doc["automatic_watering"] = automaticWateringEnabled;
    doc["plant_id"] = currentPlantId;
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  });
  
  // Manejar rutas no encontradas
  server.onNotFound([]() {
    server.send(404, "application/json", "{\"error\":\"Endpoint no encontrado\"}");
  });
}

void readSensors() {
  // Leer sensor de humedad del suelo
  int soilMoistureRaw = analogRead(SOIL_MOISTURE_PIN);
  // Convertir a porcentaje (ajustar estos valores según tu sensor)
  // Nota: Para sensores capacitivos, generalmente:
  // - Valor en aire seco: ~880-1023
  // - Valor en agua: ~200-400
  int airValue = 880;    // Valor en aire seco (0% humedad)
  int waterValue = 400;  // Valor en agua (100% humedad)
  soilMoisture = map(soilMoistureRaw, airValue, waterValue, 0, 100);
  soilMoisture = constrain(soilMoisture, 0, 100);
  
  // Leer sensor DHT (temperatura)
  float newTemp = dht.readTemperature();
  if (!isnan(newTemp)) {
    temperature = newTemp;
  }
  
  // Leer sensor de luz
  // Si usas un pin digital con un fotorresistor y una resistencia en divisor de voltaje
  int lightRaw = digitalRead(LIGHT_SENSOR_PIN);
  // Para un sensor analógico, usarías:
  // int lightRaw = analogRead(LIGHT_SENSOR_PIN);
  // lightLevel = map(lightRaw, 0, 1023, 0, 100);
  
  // Para esta implementación simple con pin digital:
  lightLevel = lightRaw == HIGH ? 100 : 0;
}

void startWatering(int duration) {
  if (!isWatering) {
    Serial.println("Iniciando riego por " + String(duration) + " segundos");
    isWatering = true;
    wateringStartTime = millis();
    digitalWrite(WATER_PUMP_PIN, HIGH);  // Activar bomba
    lastWateringTime = millis();
  }
}

void stopWatering() {
  if (isWatering) {
    Serial.println("Deteniendo riego");
    isWatering = false;
    digitalWrite(WATER_PUMP_PIN, LOW);  // Desactivar bomba
  }
}

void manageWatering() {
  // Verificar si está regando y si debe detenerse
  if (isWatering && (millis() - wateringStartTime >= wateringDuration * 1000)) {
    stopWatering();
  }
  
  // Verificar si debe iniciar riego automático
  if (automaticWateringEnabled && !isWatering) {
    // Solo regar si la humedad está por debajo del umbral y ha pasado al menos 1 hora desde el último riego
    if (soilMoisture < wateringThreshold && (millis() - lastWateringTime >= 3600000)) {
      Serial.println("Iniciando riego automático");
      startWatering(wateringDuration);
    }
  }
}

void loadConfig() {
  Config config;
  EEPROM.get(0, config);
  
  // Verificar si hay datos válidos en EEPROM
  if (config.wateringThreshold >= 0 && config.wateringThreshold <= 100) {
    wateringThreshold = config.wateringThreshold;
    wateringDuration = config.wateringDuration;
    automaticWateringEnabled = config.automaticWateringEnabled;
    currentPlantId = String(config.plantId);
    
    Serial.println("Configuración cargada desde EEPROM");
  } else {
    // Usar valores predeterminados
    Serial.println("Usando configuración predeterminada");
  }
}

void saveConfig() {
  Config config;
  config.wateringThreshold = wateringThreshold;
  config.wateringDuration = wateringDuration;
  config.automaticWateringEnabled = automaticWateringEnabled;
  currentPlantId.toCharArray(config.plantId, 32);
  
  EEPROM.put(0, config);
  EEPROM.commit();
  
  Serial.println("Configuración guardada en EEPROM");
}