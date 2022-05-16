import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:water_sync_iot/models/tank_data.dart';

import '../service/authentication_service.dart';

class DataBaseConnection extends ChangeNotifier{
  AuthenticationService _authService;
  FirebaseUser _user;
  FirebaseDatabase _database = FirebaseDatabase.instance;
  List<TankData> _userTankData = new List<TankData>();

  Query _tankMetaDataQuery;

  DataBaseConnection(){
    _database = FirebaseDatabase.instance;
    initAsynchronousFields();
  }

  Future<void> initAsynchronousFields() async {

    _authService = AuthenticationService();
    _user = await _authService.getLoggedInUser();

    _tankMetaDataQuery = _database
        .reference()
        .child("/users/" + this._user.uid + "/hardware/mac_id")
        .orderByChild("associated_tank_name");

    fireInitTankMetaData();
  }

  void fireInitTankMetaData(){
    _tankMetaDataQuery.onChildAdded.listen((Event event) {
//      print("-----------------Tank Meta data added in DataBaseConnection--------------");
      onTankDataAdded(event);
      notifyListeners();
    });
    notifyListeners();
  }

  void onTankDataAdded(Event event) async {
    TankData obj = TankData.buildMetaData(snapshot: event.snapshot);
    obj.todaysTankData = new List<LatestTankDataDump>();
    this._userTankData.add(obj);

    for (int i = 0; i < _userTankData.length; i++) {
      if (!(_userTankData[i].macID == event.snapshot.key)) {
        continue;
      }

      _database
          .reference()
          .child("/users/" + this._user.uid + "/hardware/data_values/" + _userTankData[i].macID)
          .limitToLast(1)
          .onChildAdded
          .listen((Event event) {
//        print("----------------------New Value is added in this MAC-------------------");
        _userTankData[i].buildLatestTankData(snapshot: event.snapshot);
        notifyListeners();
      });

      _database
          .reference()
          .child("/users/" + this._user.uid + "/hardware/data_values/" + _userTankData[i].macID)
          .orderByKey()
          .startAt(getTodayStartTimeStamp())
          .onChildAdded
          .listen((Event event) {
//            print("----------------------New Value for today is added in this MAC-------------------");
        this.addNewDataToTodayTankData(event, i);
        notifyListeners();
      });
    }
    notifyListeners();
  }

  String getTodayStartTimeStamp() {
    DateTime now = new DateTime.now();
    DateTime todayStart = new DateTime(now.year, now.month, now.day, 0, 0, 0, 0, 0);
    int timeStamp = todayStart.millisecondsSinceEpoch ~/ 1000;
    return timeStamp.toString();
  }

  void addNewDataToTodayTankData(Event event, int index) {
    LatestTankDataDump ltdd = new LatestTankDataDump.fromSnapshot(snapshot: event.snapshot);
    _userTankData[index].todaysTankData.add(ltdd);
    _userTankData[index].updateAggregrateTankDataValue(snapshot: event.snapshot);
    notifyListeners();
  }

  List<TankData> get getTankData => _userTankData;
  FirebaseDatabase get getDatabase => _database;
  FirebaseUser get getFirebaseUser => _user;

}

