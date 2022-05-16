//mac 84:0D:8E:A5:80:83
#include <ESP8266WiFi.h>
#include <NTPClient.h>
#include <PubSubClient.h>
#include <ArduinoJson.h> 
#include <SoftwareSerial.h>
#include <FirebaseArduino.h>
#include <ESP8266HTTPClient.h>
#include <WiFiUdp.h>


#define LED 16
#define Relay 5 //D1
#define NTP_OFFSET   60 * 60      // In seconds
#define NTP_INTERVAL 60 * 1000    // In milisecondsde
#define NTP_ADDRESS  "in.pool.ntp.org"
#define DEBUG 1

/*
#define FIREBASE_HOST "first-project-8ad90.firebaseio.com"                         // the project name address from firebase id
#define FIREBASE_AUTH "JuSy0QQz3NMGVL0f7VDEBlw4Rs7JrCaCToxYibbE" 
*/


#define FIREBASE_HOST "watersync-75750.firebaseio.com"                         // the project name address from firebase id
#define FIREBASE_AUTH "u3cKF7V4XmL3OquKxVQXzzZccvpSfY7tmnmWVEM0"  

/*

Pins configuration : 
|----|--------------------------|--------|
|    | flowmeter (inlt)       | 14 D5  |
|    | flowmeter (out)        | 12 D6  |
|    | Relay                    | 5  D1  |
|    | transistor(1)            | 4  D2  |
|    | transistor(2)            | 0  D3  |
|    | transistor(3)            | 2  D4  |
------------------------------------------


*/

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, NTP_ADDRESS, NTP_OFFSET, NTP_INTERVAL);

void ICACHE_RAM_ATTR pulseCounter();
void ICACHE_RAM_ATTR pulseCounter1();

//############ Flow meter (inlet)####################
byte flowMeter = 14;  // D5
float calibrationFactor = 4.5;// 4.5 pulses per second per
volatile byte pulseCount;  
float flowRate;
unsigned int flowMilliLitres;
unsigned long totalMilliLitres;
unsigned long oldTime;
//###############################

//############ Flow meter1(outlet) ####################
byte flowMeter1 = 12;  // D6
float calibrationFactor1 = 4.5;// 4.5 pulses per second per
volatile byte pulseCount1;  
float flowRate1;
unsigned int flowMilliLitres1;
unsigned long totalMilliLitres1;
unsigned long oldTime1;
//###############################

//###############################
//Level 1 => 0
//Level 2 => 1
//Level 3 => 2
/*   /             \
//  /               \
//  |   Level 1     |3
//  |               |--
//  |   Level 2     |2   
//  |               |--
//  |   Level 3     |1
//  |               |--
//  |               |0
//  |---------------|
*/
int currentWaterLevel;
int Level3 = 4; //d4 ok low
int Level2 = 0; //d2 ok mid
int Level1 = 2; //d3 high

//###############################

//############ Pins and Configs ###############
const int sensor_pin = A0;

/*const char * ssid = "Tanna_E";
const char * password = "9137035624";
*/
/*const char * ssid = "Hidden Network";
const char * password = "!!!!!!!!";*/

const char * ssid = "RED CODER";
const char * password = "codeforcescodechefhackerrank";

const char * mqttServer = "soldier.cloudmqtt.com";
const int mqttPort = 17830;
const char * mqttUser = "mkgzsqgr";
const String macId = "testMAC1234";
const char * mqttPassword = "VJGKX-8r_QwW";
//###########################

//############ Globals ###############
int pumpStatus = 0;
bool autoMode = false;
bool hasLeakage = false;
int threshold = 25;
int waterLevel = 0;
const String uid = "2taxSnwboqSYN7iRKycgby3liW72";
//                  2taxSnwboqSYN7iRKycgby3liW72
//###########################

//############ ob ###############
WiFiClient espClient;
PubSubClient client(espClient);
//###########################

void debugger(String msg){
    #ifdef DEBUG
    Serial.println(msg);
    #endif
}

void measureFlowmeter(){
    debugger("----------measureFlowmeter-------------");
    flowmeter();
    flowmeter1();
}

void flowmeter() {
    
    if ((millis() - oldTime) > 1000) // Only process counters once per second
    {

        detachInterrupt(flowMeter);

        flowRate = ((1000.0 / (millis() - oldTime)) * pulseCount) / calibrationFactor;
        oldTime = millis();
        flowMilliLitres = (flowRate / 60) * 1000;
        totalMilliLitres += flowMilliLitres;

        /*Serial.print("ML");
        Serial.print("\t");
        Serial.print(total

void flowmeter() {
    MilliLitres / 1000);
        Serial.println("L");*/
        debugger("----------flowmeter(inlet)-------------"+(String)flowMilliLitres);
        //debugger("Inlet flowmeter flow : "+flowMilliLitres);

        pulseCount = 0;

    
        attachInterrupt(flowMeter, pulseCounter, FALLING);
    }
}

void pulseCounter() {
    pulseCount++;
}

void flowmeter1() {
    
    if ((millis() - oldTime1) > 1000) // Only process counters once per second
    {

        detachInterrupt(flowMeter1);

        flowRate1 = ((1000.0 / (millis() - oldTime1)) * pulseCount1) / calibrationFactor1;
        oldTime1 = millis();
        flowMilliLitres1 = (flowRate1 / 60) * 1000;
        totalMilliLitres1 += flowMilliLitres1;

        /*Serial.print("Quantity: ");
        Serial.print(totalMilliLitres1);
        Serial.print("ML");
        Serial.print("\t");
        Serial.print(totalMilliLitres1 / 1000);
        Serial.println("L");*/
        debugger("----------flowmeter(outlet)-------------"+(String)flowMilliLitres1);
        //debugger("Outlet flowmeter flow : "+flowMilliLitres1);
        pulseCount1 = 0;

        attachInterrupt(flowMeter1, pulseCounter1, FALLING);
    }
}

void pulseCounter1() {
    pulseCount1++;
}

void pumpOnOff(bool onOrOff){
    debugger("----------pumpOnOff-------------");
    if(onOrOff){
        digitalWrite(Relay, LOW);    
        pumpStatus = 1;
        debugger("Pump is turned ON");
    }
    else{
        digitalWrite(Relay, HIGH);    
        pumpStatus = 0;
        debugger("Pump is turned OFF");
    }
}

void MQTTcallback(char * topic, byte * payload, unsigned int length) {
    debugger("----------MQTTcallback-------------");
    debugger("MQTT message is arrived for message :"+String(topic));

    String message;
    
    for (unsigned int i = 0; i < length; i++) {
        message = message + (char) payload[i]; //Conver *byte to String
    }
    debugger("MQTT message has content :"+message);
    
    if (message == "#on") {
        digitalWrite(LED, LOW);
    } //LED on  
    if (message == "#off") {
        digitalWrite(LED, HIGH);
    } //LED off
    if (message == "#pumpOn") {
        pumpOnOff(true);
    } //LED on  
    if (message == "#pumpOff") {
        pumpOnOff(false);
    }
    if (message == "#autoTrue") {
        autoMode= true;
    }
    if (message == "#autoFalse") {
        autoMode= false;
    }
}

void setup() {
    delay(1000);
    pinMode(LED, OUTPUT);
    pinMode(Relay, OUTPUT);
    pinMode(Level1, INPUT_PULLUP);
    pinMode(Level2, INPUT_PULLUP);
    pinMode(Level3, INPUT_PULLUP); 
    Serial.begin(115200);
    
    digitalWrite(LED, HIGH);
    digitalWrite(Relay, HIGH);
    
    pulseCount = 0;
    flowRate = 0.0;
    flowMilliLitres = 0;
    totalMilliLitres = 0;
    oldTime = 0;
    
    pulseCount1 = 0;
    flowRate1 = 0.0;
    flowMilliLitres1 = 0;
    totalMilliLitres1 = 0;
    oldTime1 = 0;

    attachInterrupt(flowMeter, pulseCounter, FALLING);
    attachInterrupt(flowMeter1, pulseCounter1, FALLING);

    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.println("Connecting to WiFi..");
    }
    
    Serial.print("Connected to WiFi :");
    Serial.println(WiFi.SSID());
    
    client.setServer(mqttServer, mqttPort);
    client.setCallback(MQTTcallback);
    
    timeClient.begin();

    Serial.println(macId);
    Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
    //Firebase.setString("Variable/Value","dhr");
    while (!client.connected()) {
        Serial.println("Connecting to MQTT...");

        if (client.connect("ESP8266", mqttUser, mqttPassword)) {

            Serial.println("connected with MQTT servers");

        } else {

            Serial.print("failed with state ");
            Serial.println(client.state()); //If you get state 5: mismatch in configuration
            delay(2000);

        }
    }
    
    client.publish("esp/84:0D:8E:A5:80:83/hello", "Hello from ESP8266");
    client.subscribe("esp/testMAC1234/#");

}

void generateFirebasePush() {

    debugger("----------generateFirebasePush-------------");

    timeClient.update();
      String epochTime =  (String)timeClient.getEpochTime();
      Serial.println("ep : "+epochTime);

      StaticJsonBuffer < 300 > JSONbuffer;
      JsonObject & JSONencoder = JSONbuffer.createObject();
    
    JSONencoder["inlet_flow"] = flowMilliLitres;
    JSONencoder["outlet_flow"] = flowMilliLitres1;
    if(pumpStatus==0){
        JSONencoder["pump_status"] = "OFF";    
    }
    else{
        JSONencoder["pump_status"] = "ON";
    }

    if(currentWaterLevel==3){
        JSONencoder["water_level"] = "HIGH";    
    }
    else if(currentWaterLevel==2){
        JSONencoder["water_level"] = "MEDIUM";    
    }
    else if(currentWaterLevel==1){
        JSONencoder["water_level"] = "LOW";    
    }
    else{
        JSONencoder["water_level"] = "VERY LOW";    
    }
    

    char JSONmessageBuffer[100];
    //JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    JsonVariant variant = JSONencoder;
    variant.printTo(Serial);
    //JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    
    String path = "users/"+uid+"/hardware/data_values/";
    Firebase.set("users/"+uid+"/hardware/data_values/"+macId+"/"+epochTime+"/",variant); 
    
    //Firebase.push("users/"+uid+"/hardware/data_values/"+macId+"/"+epochTime+"/",JSONmessageBuffer); //outlet flow meter readings
    
    debugger(JSONmessageBuffer);
}

void measureWaterLevel(){
    debugger("----------measureWaterLevel-------------");
    if(digitalRead(Level1)==LOW ) {
        currentWaterLevel = 3;
    }
    else if(digitalRead(Level2)==LOW){
        currentWaterLevel = 2;
    }
    else if(digitalRead(Level3)==LOW){
        currentWaterLevel = 1;
    }
    else {
        currentWaterLevel = 0;
    }
   /* if(digitalRead(Level1)==LOW) {
    Serial.println("Level-3 HIGH");
    
  }
  else if(digitalRead(Level2)==LOW ){
    Serial.println("Level-2 MID");
    

  }
  else if(digitalRead(Level3)==LOW){
    Serial.println("Level-1 LOW");
    

  }
  else {
    
    Serial.println(" Dead level");
    }*/
    debugger("currentWaterLevel set is :"+String(currentWaterLevel));
}

void checkLeakage(){
    debugger("----------checkLeakage-------------");
  int i=20;
  unsigned int average_leakage = 0, total_leakage = 0;
  while(i>0){
    debugger("Collecting "+String(i)+" sample");
    flowmeter();
    flowmeter1();
    total_leakage += abs(flowMilliLitres1-flowMilliLitres);
    average_leakage += total_leakage/(20-i+1);
    debugger("Inlet flow :"+(String)flowMilliLitres+" Outlet flow :"+(String)flowMilliLitres1+" Average Difference :"+(String)average_leakage+" Total Leakage :"+(String)total_leakage);
    i--;  
    delay(1500);
  }
  average_leakage = average_leakage /20;
  if(average_leakage > 100)
    hasLeakage = true;
  else
    hasLeakage = false;
    debugger("Third Umpire decision (Leakage):"+(String)average_leakage+" (Decision)"+(String)hasLeakage);
   //return hasLeakage;
}

void measureFlowmeterRandom() {
  flowMilliLitres = random(100,1000);
  flowMilliLitres1 = random(flowMilliLitres-10,flowMilliLitres+10);
}

void measureWaterLevelRandom() {
  currentWaterLevel = random(0,3);
}

void loop() {
    client.loop();
    //measureFlowmeter();
    //measureWaterLevel();

    measureFlowmeterRandom();
    measureWaterLevelRandom();
    
    /*if(abs(flowMilliLitres-flowMilliLitres1)>threshold){
        checkLeakage();      
    } */ 
    if(autoMode==true)
    {
        if(currentWaterLevel == 0 || hasLeakage){
            pumpOnOff(true);
        }
        else if(currentWaterLevel == 3){
            pumpOnOff(false);
        }
    }
    generateFirebasePush();
    delay(2000);
}
//A
//B
