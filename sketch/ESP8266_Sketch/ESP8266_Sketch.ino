#include "ESP8266WiFi.h"
#include <ESP8266HTTPClient.h>

const char* ssid = "Dan iPhone"; //Enter SSID
const char* password = "l1acoeAaiae"; //Enter Password
const int ledPin = 0;

void setup(void)
{ 
  // LED:
  pinMode(ledPin, OUTPUT);
  
  Serial.begin(115200);
  Serial.println("Codes:");
  Serial.println(WL_CONNECTED);
  Serial.println(WL_NO_SHIELD);
  Serial.println(WL_IDLE_STATUS);
  Serial.println(WL_CONNECT_FAILED);
  Serial.println(WL_NO_SSID_AVAIL);
  Serial.println(WL_SCAN_COMPLETED);
  Serial.println(WL_CONNECTION_LOST);
  Serial.println(WL_DISCONNECTED);
  Serial.println("Connecting.");
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) 
  {
    if (WiFi.status() == WL_CONNECT_FAILED) {
      Serial.println("Failed");
    }
     delay(500);
     Serial.print(WiFi.status());
  }
  
  Serial.println("");
  Serial.println("WiFi connection Successful");
  Serial.print("The IP Address of ESP8266 Module is: ");
  Serial.print(WiFi.localIP());// Print the IP address
}

void loop() 
{
  if(WiFi.status()== WL_CONNECTED){   //Check WiFi connection status

   digitalWrite(ledPin, HIGH);   // turn the LED on (HIGH is the voltage level)
 
   HTTPClient http;    //Declare object of class HTTPClient
 
   http.begin("http://jsonplaceholder.typicode.com/users");      //Specify request destination
   http.addHeader("Content-Type", "text/plain");  //Specify content-type header
 
   int httpCode = http.POST("Message from ESP8266");   //Send the request
   String payload = http.getString();                  //Get the response payload
 
   Serial.println(httpCode);   //Print HTTP return code
   Serial.println(payload);    //Print request response payload
 
   http.end();  //Close connection

   digitalWrite(ledPin, LOW);
 
 }else{
 
    Serial.println("Error in WiFi connection");   
 
 }
 
  delay(3000);  //Send a request every 30 seconds
 
}
