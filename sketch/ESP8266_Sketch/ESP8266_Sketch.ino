#include "ESP8266WiFi.h"
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h> //From https://arduinojson.org/
#include "config.h"

// Config values
const int ledPin = 0;
const int analogInPin = A0;
unsigned long selectionDelay = 5000; // 5 second delay before confirmation

// Initial values
int engagementCount = 0;
String engagementNames[100];
String engagementIds[100];
int selectedValue = -1;
unsigned long selectionTime;
String sfAuthToken = "";
String sfInstanceURL = "";

// Private settings
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;
const char* sfClientId = SF_CLIENT_ID;
const char* sfClientKey = SF_CLIENT_KEY;
const char* sfUsername = SF_USERNAME;
const char* sfPassword = SF_PASSWORD;
const char* sfToken = SF_TOKEN;
const char* sfLoginFingerprint = SF_LOGIN_FINGERPRINT;
const char* sfInstanceFingerprint = SF_INSTANCE_FINGERPRINT;

#define DEBUG false

void setup(void)
{ 
  pinMode(ledPin, OUTPUT);
  
  Serial.begin(115200);
  Serial.println("");
  
  digitalWrite(ledPin, HIGH);
  printToScreen("Connecting...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) 
  {
    if (WiFi.status() == WL_CONNECT_FAILED) {
      printToScreen("Failed");
    }
    delay(100);
  }
  
  
  printToScreen("WiFi connection Successful");
  if (DEBUG) {
    Serial.println("");
    Serial.print("The IP Address of ESP8266 Module is: ");
    Serial.println(WiFi.localIP());// Print the IP address
  }

  //once online, login to salesforce
  doLogin(sfUsername, sfPassword, sfToken, sfClientId, sfClientKey, sfLoginFingerprint);
  getEngagements("Engagements");
  digitalWrite(ledPin, LOW);
}

void checkSelection() {
  int sensorValue = analogRead(analogInPin);
  int outputValue = map(sensorValue, 0, 1024, 0, engagementCount);

  if (outputValue != selectedValue) {
    if (DEBUG) {
      Serial.print("Sensor Value: ");
      Serial.println(sensorValue);
      Serial.print("Engagement number: ");
      Serial.println(outputValue);
    }
    digitalWrite(ledPin, HIGH);
    selectionTime = millis();
  
    if (outputValue == 0) {
      printToScreen("Change to No Engagement?");
    }
    else {
      printToScreen("Change to " + engagementNames[outputValue-1] + "?");
    }
    selectedValue = outputValue;
  }
}

void changeSelection() {
  selectionTime = NULL;
  printToScreen("Changing...");

  String reqURL = (String)sfInstanceURL + "/services/apexrest/continuum/EngagementEntries";

  if(DEBUG) {
    Serial.println("Instance URL: " + (String)sfInstanceURL);
    Serial.println("Auth Token: " + (String)sfAuthToken);
    Serial.println("Request URL: " + reqURL);
    Serial.println("JSON Sent: ");
    Serial.println();
  }

  HTTPClient http;
  http.begin(reqURL, sfInstanceFingerprint);
  http.addHeader("Authorization", "Bearer " + (String)sfAuthToken);
  http.addHeader("Content-Type", "application/JSON");
  http.addHeader("Content-Length", "0");
  
  String id = "";
  if (selectedValue >= 1) id = engagementIds[selectedValue-1];
  int httpCode = http.POST("{\"engagementId\": \"" + id + "\"}");
  String payload = http.getString();
  
  http.end();

  if (DEBUG) {
    Serial.println("HTTP Code:");
    Serial.println(httpCode);
    if (httpCode < 0) {
      Serial.printf("[HTTP] GET... failed, error: %s\n", http.errorToString(httpCode).c_str());
      printToScreen(http.errorToString(httpCode).c_str());
    }
    Serial.println("HTTP Response:");
    Serial.println(payload);
  }
  if (httpCode == 200) {
    if (selectedValue >= 1) {
      printToScreen(engagementNames[selectedValue-1]);
    }
    else {
      printToScreen("No Engagement");
    }
  }
  digitalWrite(ledPin, LOW);
  
}

void loop() 
{
  checkSelection();
  if (selectionTime && selectionTime+selectionDelay < millis()) {
    changeSelection();
  }
  delay(500);
}

// Login method, will return a JSON object with auth token and instance URL you can use to perform requests
void doLogin(String username, String password, String token, String clientId, String clientKey, String fingerprint) {
        
    HTTPClient http;
    //you can change this to test.salesforce.com if you need to
    http.begin("https://login.salesforce.com/services/oauth2/token", fingerprint);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    
    String postBody = "?&grant_type=password";
    postBody += "&client_id=" + clientId;
    postBody += "&client_secret=" + clientKey;
    postBody += "&username=" + username;
    postBody += "&password=" + password + token;
    
    int httpCode = http.POST(postBody);
    if(DEBUG) {
      Serial.print("http result:");
      Serial.println(httpCode);
    }
    
    String payload = http.getString();
    
    http.end();

    StaticJsonDocument<1024> jsonBuffer;

    deserializeJson(jsonBuffer, payload);
    
    if(DEBUG) {
      Serial.println("Response: ");
      Serial.println(payload);
    }
    
    if(httpCode == 200) {    
      if (DEBUG) {
        Serial.println("Successfully logged in!");
      }
      String token = jsonBuffer["access_token"];
      String url = jsonBuffer["instance_url"];
      sfAuthToken = token;
      sfInstanceURL = url;
    }
    else {
      Serial.println("An error occured, not logged in!");
    }

}

// Method to insert a SObject (or Platform Event!) pass it both the JSON auth object and an JSON object repersenting the record you wish to insert
bool getEngagements(String objectName) {
  String reqURL = (String)sfInstanceURL + "/services/apexrest/continuum/" + (String)objectName;

  if(DEBUG) {
    Serial.println("Instance URL: " + (String)sfInstanceURL);
    Serial.println("Auth Token: " + (String)sfAuthToken);
    Serial.println("Request URL: " + reqURL);
    Serial.println("JSON Sent: ");
    Serial.println();
  }

  HTTPClient http;
  http.begin(reqURL, sfInstanceFingerprint);
  http.addHeader("Authorization", "Bearer " + (String)sfAuthToken);
  http.addHeader("Content-Type", "application/JSON");
    
  int httpCode = http.GET();
  String payload = http.getString();
  
  http.end();

  if (DEBUG) {
    Serial.println("HTTP Code:");
    Serial.println(httpCode);
    if (httpCode < 0) {
      Serial.printf("[HTTP] GET... failed, error: %s\n", http.errorToString(httpCode).c_str());
    }
    Serial.println("HTTP Response:");
    Serial.println(payload);
  }

  DynamicJsonDocument jsonBuffer(2048);

  deserializeJson(jsonBuffer, payload);

  JsonArray jsArray = jsonBuffer.as<JsonArray>();
  engagementCount = jsArray.size();
  if(DEBUG) {
    Serial.print("engagementCount: ");
    Serial.println(engagementCount);
  }
  for (int i = 0; i < engagementCount; i++)
  {
      engagementNames[i] = jsArray[i].getMember("Name").as<String>();
      engagementIds[i] = jsArray[i].getMember("Id").as<String>();
  }
}

void printToScreen(String output) {
  Serial.print("Screen: ");
  Serial.println(output);
}
