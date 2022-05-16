import 'dart:ffi';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import './data_constants.dart';

/*class InternalTankData {
  WaterLevel waterLevel;
  Pump pumpState;
  String inletFlow="--", outletFlow="--", timeStamp="--";

  InternalTankData({this.timeStamp, this.inletFlow,this.outletFlow,this.waterLevel,this.pumpState});

  @override
  String toString() {
    return "inletFlow : "+inletFlow+" outletFlow : "+outletFlow+" pumpState : "+pumpState.toString()+" waterLevel : "+waterLevel.toString();
  }

  toJSON(){
    return {
      "intletFlow" : inletFlow,
      "outletFlow" : outletFlow,
      "pumpState" : pumpState,
      "timeStamp" : timeStamp,
    };
  }
}

class TankData {
  String tankName, macID;
  InternalTankData latestDataDump = new InternalTankData();

  TankData({this.macID,this.latestDataDump});
  TankData.buildMetaData(DataSnapshot snapshot){
    this.macID = snapshot.key;
    this.tankName = snapshot.value["associated_tank_name"];
  }

  void buildInternalState(DataSnapshot snapshot){

    this.latestDataDump.timeStamp = snapshot.key.toString();
    this.latestDataDump.pumpState = (snapshot.value["pump_status"] == "ON") ? Pump.ON: Pump.OFF;
    this.latestDataDump.outletFlow = snapshot.value["outlet_flow"].toString();
    this.latestDataDump.inletFlow = snapshot.value["inlet_flow"].toString();
    switch(snapshot.value["water_flow"]){
      case "HIGH":
        this.latestDataDump.waterLevel = WaterLevel.HIGH;
        break;
      case "LOW":
        this.latestDataDump.waterLevel = WaterLevel.LOW;
        break;
      case "MEDIUM":
        this.latestDataDump.waterLevel = WaterLevel.MEDIUM;
        break;
    }
  }

  toJSON() {
    return {
        "inlet_flow" : int.parse(this.latestDataDump.inletFlow),
        "outlet_flow" : int.parse(this.latestDataDump.outletFlow),
        "water_level" : (this.latestDataDump.waterLevel == WaterLevel.HIGH) ? "HIGH" : (this.latestDataDump.waterLevel == WaterLevel.LOW) ? "LOW" : "MEDIUM",
        "pump_state" : (this.latestDataDump.pumpState == Pump.ON) ? "ON" : "OFF",
    };
  }
}

class AggregateTankData {
  String macID;
  double usage=0, loss=0, numOfTimesSwitchedOn=0;
  WaterLevel minWaterLevel, maxWaterLevel;

  AggregateTankData({this.macID, DataSnapshot snapshot}){
    if(snapshot != null) {
      for (var entry in snapshot.value.values) {
        print(entry.key);
      }
    }
  }

  void buildAggregate(DataSnapshot snapshot){
    for(var entry in snapshot.value.values){
      usage += double.parse(entry["outlet_flow"].toString());
    }
  }
}*/

class AggregateTankData {
  double usage = 0.0, loss = 0.0;
  int numberOfTimesSwitchOn = 0;
  String previousTankStatus = "OFF";

  AggregateTankData() {
    usage = 0.0;
    loss = 0.0;
    numberOfTimesSwitchOn = 0;
    previousTankStatus = "OFF";
  }

  toJSON() {
    return {"usage": usage, "loss": loss, "numberOfTimesSwithedOn": numberOfTimesSwitchOn};
  }
}

class LatestTankDataDump {
  String lastUpdated, inletFLow, outletFlow;
  Pump pumpState;
  WaterLevel currentWaterLevel;

  LatestTankDataDump() {
    lastUpdated = "--";
    inletFLow = "--";
    outletFlow = "--";
    pumpState = Pump.UNDEFINED;
    currentWaterLevel = WaterLevel.UNDEFINED;
  }

  LatestTankDataDump.fromSnapshot({@required DataSnapshot snapshot}) {
    inletFLow = (snapshot.value["inlet_flow"] == null) ? "--" : (double.parse(snapshot.value["inlet_flow"].toString())/1000).toStringAsFixed(2);
    outletFlow = (snapshot.value["outlet_flow"] == null) ? "--" : (double.parse(snapshot.value["outlet_flow"].toString())/1000).toStringAsFixed(2);
    lastUpdated = (snapshot.key == null) ? "--" : snapshot.key.toString();
    switch (snapshot.value["water_level"].toString()) {
      case "HIGH":
        currentWaterLevel = WaterLevel.HIGH;
        break;
      case "MEDIUM":
        currentWaterLevel = WaterLevel.MEDIUM;
        break;
      case "LOW":
        currentWaterLevel = WaterLevel.LOW;
        break;
      default:
        currentWaterLevel = WaterLevel.UNDEFINED;
        break;
    }
    switch (snapshot.value["pump_status"].toString()) {
      case "ON":
        pumpState = Pump.ON;
        break;
      case "OFF":
        pumpState = Pump.OFF;
        break;
      default:
        pumpState = Pump.UNDEFINED;
        break;
    }
  }

  String get getPumpState {
    switch (pumpState) {
      case Pump.ON:
        return "ON";
      default:
        return "OFF";
      /*default:
        return "--";*/
    }
  }

  String get getWaterLevel {
    switch (currentWaterLevel) {
      case WaterLevel.HIGH:
        return "HIGH";
      case WaterLevel.MEDIUM:
        return "MEDIUM";
      case WaterLevel.LOW:
        return "LOW";
      default:
        //return "--";
        return "VERY LOW";
    }
  }

  toJSON() {
    return {
      lastUpdated: {
        "inlet_flow": this.inletFLow,
        "outlet_flow": this.outletFlow,
        "water_level": this.getWaterLevel,
        "pump_status": this.getPumpState
      }
    };
  }

  toJSONFirebase() {
    return {
      "inlet_flow": this.inletFLow,
      "outlet_flow": this.outletFlow,
      "water_level": this.getWaterLevel,
      "pump_status": this.getPumpState
    };
  }
}

class TankData {
  String macID, tankName;
  bool autoMode;
  LatestTankDataDump latestTankData = new LatestTankDataDump();
  List<LatestTankDataDump> todaysTankData = new List<LatestTankDataDump>();
  AggregateTankData aggregateTankData = new AggregateTankData();

  TankData({this.macID, this.tankName, this.latestTankData});

  TankData.buildMetaData({@required DataSnapshot snapshot}) {
    this.macID = snapshot.key.toString();
    this.tankName = snapshot.value["associated_tank_name"];
    this.autoMode = (snapshot.value["auto_mode"]==1) ? true : false;
  }

  void buildLatestTankData({@required DataSnapshot snapshot}) {
    this.latestTankData = new LatestTankDataDump.fromSnapshot(snapshot: snapshot);
  }

  void updateAggregrateTankDataValue({@required DataSnapshot snapshot}) {
//    print(snapshot.value);
    double convertedOutletFLow,convertedInletFLow;
    convertedOutletFLow = double.parse((double.parse(snapshot.value["outlet_flow"].toString())/1000).toStringAsFixed(2));
    convertedInletFLow = double.parse((double.parse(snapshot.value["inlet_flow"].toString())/1000).toStringAsFixed(2));

//    aggregateTankData.usage += double.parse((double.parse(snapshot.value["outlet_flow"])/1000).toStringAsFixed(2));
//    if((double.parse((snapshot.value["outlet_flow"]).toString())) < (double.parse((snapshot.value["inlet_flow"]).toString()))){
//      aggregateTankData.loss -=
//      (double.parse((snapshot.value["outlet_flow"]).toString()) - double.parse((snapshot.value["inlet_flow"]).toString()));
//    }

    aggregateTankData.usage += convertedOutletFLow;
    aggregateTankData.usage = double.parse(aggregateTankData.usage.toStringAsFixed(2));
    if(convertedOutletFLow < convertedInletFLow){
      aggregateTankData.loss -= convertedOutletFLow - convertedInletFLow;
      aggregateTankData.loss = double.parse(aggregateTankData.loss.toStringAsFixed(2));
    }

    print("---------Pump on/off-----------------");
    print(snapshot.value["pump_status"].toString());
    aggregateTankData.numberOfTimesSwitchOn +=
        (snapshot.value["pump_status"].toString() != aggregateTankData.previousTankStatus && snapshot.value["pump_status"].toString() == "ON")
            ? 1
            : 0;
    aggregateTankData.previousTankStatus = snapshot.value["pump_status"];
    print("No of.times :"+aggregateTankData.numberOfTimesSwitchOn.toString());
    print("Loss :"+aggregateTankData.loss.toString());
    print("Usgae :"+aggregateTankData.usage.toString());
  }
}
