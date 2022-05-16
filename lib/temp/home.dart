import 'dart:async';
import 'dart:io';

import 'package:random_string/random_string.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:water_sync_iot/debug.dart';
import 'package:water_sync_iot/models/data_constants.dart';
import 'package:water_sync_iot/models/tank_data.dart';
import 'package:water_sync_iot/mqtt/MQTTAppState.dart';
import 'package:water_sync_iot/mqtt/MQTTManager.dart';
import 'package:water_sync_iot/screens/profile.dart';
import 'package:water_sync_iot/screens/sign_in.dart';
import 'package:water_sync_iot/service/data_base_queries.dart';
import 'package:water_sync_iot/temp/reports.dart';
import 'package:water_sync_iot/temp/settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:water_sync_iot/widgets/connection_label.dart';
import 'package:water_sync_iot/widgets/notifications_icon.dart';
import '../widgets/quick_access_tank.dart';

import '../service/authentication_service.dart';

import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool shouldRepeatFunctionCall = true;
  bool autoMode;
  DebugLog debug = new DebugLog(DEBUG: false);
  MQTTAppState currentMQTTState;
  MQTTManager manager;
  final GlobalKey<ScaffoldState> _homeScaffoldKey = new GlobalKey<ScaffoldState>();
  AuthenticationService _authService;
  FirebaseUser _user;
  FirebaseDatabase _database = FirebaseDatabase.instance;
  List<TankData> _userTankData = new List<TankData>();
  final cloud_firestore.Firestore _db = cloud_firestore.Firestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging();
  //int _currentIndex = 0;

  Query _tankMetaDataQuery;
  DataBaseConnection dbConnection;

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instance;

    initAsynchronousFields();
    _saveDeviceToken();
    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
//        print("onMessage: $message");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ListTile(
              title: Text(message['notification']['title']),
              subtitle: Text(message['notification']['body']),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        // TODO optional
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        // TODO optional
      },
    );
    //getTodayStartTimeStamp();
  }

  Future<void> initAsynchronousFields() async {
    debug.PRINT(tag: "Home.initAsynchronousFields", msg: "Initilizing _authService,_user,_userTankData for Home");

    _authService = AuthenticationService();
    _user = await _authService.getLoggedInUser();

    _tankMetaDataQuery = _database
        .reference()
        .child("/users/" + this._user.uid + "/hardware/mac_id")
        .orderByChild("associated_tank_name");

    _tankMetaDataQuery.onChildAdded.listen((Event event) {
      onTankDataAdded(event);
    });

    setState(() {
      _userTankData = _userTankData;
    });
  }

  _saveDeviceToken() async {
    // Get the current user
    //String uid = 'jeffd23';
    FirebaseUser user = await _authService.getLoggedInUser();

    // Get the token for this device
    String fcmToken = await _fcm.getToken();

    // Save it to Firestore
    if (fcmToken != null) {
//      print("------------------------------");
//      print("FCM now will create new token");
//      print("--------------------------------");
      var tokens = _db
          .collection('users')
          .document(user.uid)
          .collection('tokens')
          .document(fcmToken);

      await tokens.setData({
        'token': fcmToken,
        'createdAt': cloud_firestore.FieldValue.serverTimestamp(), // optional
        'platform': Platform.operatingSystem // optional
      });
//      print("------------------------------");
//      print("FCM token was created");
//      print("saved token was $fcmToken");
//      print("--------------------------------");
    }
    else{
//      print("------------------------------");
//      print("FCM token was null");
//      print("--------------------------------");
    }
  }

  void onTankDataAdded(Event event) async {
    TankData obj = TankData.buildMetaData(snapshot: event.snapshot);
    obj.todaysTankData = new List<LatestTankDataDump>();
    debug.PRINT(
      tag: "Home.initAsynchronousFields",
      msg: "Added for todaystankdata :" + obj.todaysTankData.toString(),
    );
//    setState(() {
      this._userTankData.add(obj);
//    });
    debug.PRINT(
      tag: "Home.initAsynchronousFields",
      msg: "added " + event.snapshot.value.toString(),
    );
    debug.PRINT(
      tag: "Home.initAsynchronousFields",
      msg: "Now starting init for internal state with length of list :" + _userTankData.length.toString(),
    );
    //Init list of TankData for internal state
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
        debug.PRINT(tag: "Home.initAsynchronousFields", msg: "added internal state " + event.snapshot.value.toString());
        _userTankData[i].buildLatestTankData(snapshot: event.snapshot);
        setState(() {
          _userTankData = _userTankData;
        });
      });

      _database
          .reference()
          .child("/users/" + this._user.uid + "/hardware/data_values/" + _userTankData[i].macID)
          .orderByKey()
          .startAt(getTodayStartTimeStamp())
          .onChildAdded
          .listen((Event event) {
            setState(() {
              this.addNewDataToTodayTankData(event, i);
            });
      });
    }

    setState(() {
      _userTankData = _userTankData;
    });
  }

  @override
  Widget build(BuildContext context) {
    debug.PRINT(tag: "Home.build", msg: "build called");
    Size media = MediaQuery.of(context).size;
    this.currentMQTTState = Provider.of<MQTTAppState>(context);
    this.dbConnection = Provider.of<DataBaseConnection>(context);

    if(manager==null)this._configureAndConnect();

    return Scaffold(
      key: _homeScaffoldKey,
      appBar: AppBar(
        title: Text("Water Sync"),
        leading: NotificationBadge(
          scaffoldKey: _homeScaffoldKey,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              //Navigator.push(context, new MaterialPageRoute(builder: (context) => SettingsPanel()));
              //TODO : Settings Panel
              addNewDataValueInFirebase();
            },
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              //TODO : Logout
              Navigator.pop(context);
              Navigator.push(context, new MaterialPageRoute(builder: (context) => SignIn()));
            },
          ),
        ],
      ),
      //drawer: SettingsPanel(),
      /*bottomNavigationBar: new Theme(
        data: Theme.of(context).copyWith(
        // sets the background color of the `BottomNavigationBar`
          canvasColor: Theme.of(context).primaryColor,
          // sets the active color of the `BottomNavigationBar` if `Brightness` is light
          primaryColor: Colors.redAccent,
          backgroundColor: Colors.grey,
          textTheme: Theme
              .of(context)
              .textTheme
              .copyWith(caption: new TextStyle(color: Colors.white))), // sets the inactive color of the `BottomNavigationBar`,
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).primaryColor,
          type: BottomNavigationBarType.fixed,
          onTap: onTabTapped, // new
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.home),
              title: new Text('Home',style: TextStyle(color: Colors.white),),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.account_box),
              title: new Text('Profile',style: TextStyle(color: Colors.white),),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wifi_tethering),
              title: Text('Smart config',style: TextStyle(color: Colors.white),),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline),
              title: Text('Reports',style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),*/
      body: Container(
        height: media.height,
        width: media.width,
        child: Column(
          children: <Widget>[
            ConnectionLabel(
              state: currentMQTTState.getAppConnectionState,
              onPressHandler: this._configureAndConnect,
            ),
            //buildDashboardRow(),
            //buildQuickAccessLabel(),
            /*Container(
              margin: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Auto Mode",
                  style: TextStyle(fontSize: 19),),
                  Switch(
                    value: this._userTankData[0].autoMode,
                    onChanged: (val){
                      if(val) {
                        print("Called for auto mode on");
                        _publishMessage("#autoModeOn");
                      }
                      else {
                        print("Called for auto mode on");
                        _publishMessage("#autoModeOff");
                      }
                      setState(() {
                        this._userTankData[0].autoMode = val;
                      });
                    },
                  )
                ],
              ),
            ),*/
            Expanded(
              child: buildQuickTankColumn(),
            ),
          ],
        ),
      ),
    );
  }

  /*void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }*/

  Widget buildDashboardRow() {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Container(
        height: 100.0,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            Container(
              width: 600,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFFD7384),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return ChangeNotifierProvider<DataBaseConnection>.value(
                                value: this.dbConnection,
                                child: Reports(),
                              );
                            }));
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.settings_remote,
                                color: Colors.white,
                                size: 40,
                              ),
                              Text(
                                'Configure Water Tanks',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        shouldRepeatFunctionCall = (shouldRepeatFunctionCall) ? false : true;
                        Timer.periodic(Duration(seconds: 1), (timer) {
                          if (shouldRepeatFunctionCall) {
                            timer.cancel();
                          }
                          addNewDataValueInFirebase();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2.5),
                        child: Column(
                          children: <Widget>[
                            rowCards(label: "Buy Hardware", icon: Icons.local_offer, color: Color(0XFF2BD093)),
                            rowCards(
                                label: "Profile",
                                icon: Icons.account_box,
                                color: Color(0XFFFC7B4D),
                                clickHandler: this.navigateToProfilePage),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.5),
                      child: Column(
                        children: <Widget>[
                          rowCards(label: "Reports", color: Color(0XFF53CEDB), icon: Icons.timeline),
                          rowCards(label: "Map Hardware", icon: Icons.art_track, color: Color(0XFFF1B069)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.5),
                      child: Column(
                        children: <Widget>[
                          rowCards(label: "Smart Config", icon: Icons.timeline, color: Color(0XFF53CEDB)),
                          rowCards(label: "Distribute Water", icon: Icons.timeline, color: Color(0XFF53CEDB)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rowCards({String label, IconData icon, Color color, Function clickHandler}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2.5),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: InkWell(
            onTap: clickHandler,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 5.0, right: 2.5),
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    //fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildQuickTankColumn() {
    debug.PRINT(
        tag: "Home.buildQuickTankColumn",
        msg: "Called buildQuickTankColumn with list length " + this._userTankData.length.toString());
    if (_userTankData.length <= 0) {
      debug.PRINT(tag: "Home.buildQuickTankColumn", msg: "Called with 0 length so returning another loader Object");
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          new CircularProgressIndicator(),
          new Padding(
            padding: EdgeInsets.all(10),
          ),
          new Text("Loading Data... Please Wait..."),
        ],
      );
    }
    debug.PRINT(tag: "buildQuickTankColumn", msg: "Called with greater than 0 length so returning Tank tiles Object");
    /*for (int i = 0; i < _userTankData.length; i++) {
      print("--" + _userTankData[i].macID);
      try {
        print("--" + _userTankData[i].latestTankData.toJSON().toString());
      } catch(e) {
        print("--Tried to call method toJSON on null Object");
      }
    }*/
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Container(
        height: double.infinity,
        child: ListView.builder(
          itemCount: this._userTankData.length,
          itemBuilder: (ctx, count) {
            return QuickAccessTank(
              state: currentMQTTState.getAppConnectionState,
              onOnOffPressHandler: this._motorOnOff,
              tankData: this._userTankData.elementAt(count),
              //aggregateTankState: this._todayTankData.elementAt(count),
            );
          },
        ),
      ),
    );
  }

  Widget buildQuickAccessLabel() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 9,
            child: Center(
              child: Text(
                "Quick Access",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: IconButton(
              icon: Icon(Icons.sort),
              onPressed: () {
                // TODO : Sort
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  void _configureAndConnect() {
    manager = MQTTManager(host: "", topic: "", identifier: randomAlphaNumeric(20), state: currentMQTTState);
    manager.initializeMQTTClient();
    manager.connect();
  }

  String getTodayStartTimeStamp() {
    DateTime now = new DateTime.now();
    DateTime todayStart = new DateTime(now.year, now.month, now.day, 0, 0, 0, 0, 0);
    int timeStamp = todayStart.millisecondsSinceEpoch ~/ 1000;
    debug.PRINT(tag: "Home.getTodayStartTimeStamp", msg: "Verifying timestamp object ->" + timeStamp.toString());
    debug.PRINT(
        tag: "Home.getTodayStartTimeStamp",
        msg: "Verifying date ->" + parseFormattedDate(timeStamp: timeStamp.toString()));
    return timeStamp.toString();
  }

  String parseFormattedDate({String timeStamp}) {
    return DateFormat('yyyy-MM-dd – HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(int.parse(timeStamp) * 1000));
  }

  void _motorOnOff(bool value) {
    //TODO: SEND MQTT REQUEST
//    print("From: Home._motorOnOff\n\t\tHere we will send message receieved from caller, using manager object");
    if(value){
      _publishMessage("#pumpOn");
    }
    else{
      _publishMessage("#pumpOff");
    }
  }

  void _publishMessage(String text) {
    final String message = text;
    manager.publish(message);
  }

  void addNewDataValueInFirebase() {
    LatestTankDataDump itd;
    TankData td;

    itd = new LatestTankDataDump();
    itd.lastUpdated = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    itd.inletFLow = randomBetween(1, 1500).toString();
    itd.outletFlow = randomBetween(1, 1500).toString();
    itd.currentWaterLevel = getRandomWaterLevel();
    itd.pumpState = getRandomPumpValue();

    td = new TankData(macID: "testMAC1234", latestTankData: itd);
    debug.PRINT(
        tag: "Home.addNewDataValueInFirebase",
        msg: "Added for" + td.macID + " : " + td.latestTankData.toJSON().toString());
    _database
        .reference()
        .child("/users/" + this._user.uid + "/hardware/data_values/" + td.macID + "/" + td.latestTankData.lastUpdated)
        .set(td.latestTankData.toJSONFirebase());

    itd = new LatestTankDataDump();
    itd.lastUpdated = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    itd.inletFLow = randomBetween(1, 1500).toString();
    itd.outletFlow = randomBetween(1, 1500).toString();
    itd.currentWaterLevel = getRandomWaterLevel();
    itd.pumpState = getRandomPumpValue();
    td = new TankData(macID: "testMAC5678", latestTankData: itd);
    debug.PRINT(
        tag: "Home.addNewDataValueInFirebase",
        msg: "Added for" + td.macID + " : " + td.latestTankData.toJSON().toString());
    _database
        .reference()
        .child("/users/" + this._user.uid + "/hardware/data_values/" + td.macID + "/" + td.latestTankData.lastUpdated)
        .set(td.latestTankData.toJSONFirebase());

    itd = new LatestTankDataDump();
    itd.lastUpdated = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    itd.inletFLow = randomBetween(1, 1500).toString();
    itd.outletFlow = randomBetween(1, 1500).toString();
    itd.currentWaterLevel = getRandomWaterLevel();
    itd.pumpState = getRandomPumpValue();
    td = new TankData(macID: "testMAC9012", latestTankData: itd);
    debug.PRINT(
        tag: "Home.addNewDataValueInFirebase",
        msg: "Added for" + td.macID + " : " + td.latestTankData.toJSON().toString());
    _database
        .reference()
        .child("/users/" + this._user.uid + "/hardware/data_values/" + td.macID + "/" + td.latestTankData.lastUpdated)
        .set(td.latestTankData.toJSONFirebase());
  }

  Pump getRandomPumpValue() {
    switch (randomBetween(0, 2)) {
      case 0:
        return Pump.OFF;
      case 1:
        return Pump.ON;
    }
  }

  WaterLevel getRandomWaterLevel() {
    switch (randomBetween(0, 3)) {
      case 0:
        return WaterLevel.HIGH;
      case 1:
        return WaterLevel.LOW;
      case 2:
        return WaterLevel.MEDIUM;
    }
  }

  void addNewDataToTodayTankData(Event event, int index) {
    LatestTankDataDump ltdd = new LatestTankDataDump.fromSnapshot(snapshot: event.snapshot);
    _userTankData[index].todaysTankData.add(ltdd);
//   print("added for " +
//        _userTankData[index].macID +
//        " :" +
//        parseFormattedDate(timeStamp: event.snapshot.key.toString()) +
//        " with length increasing " +
//        _userTankData[index].todaysTankData.length.toString());
    _userTankData[index].updateAggregrateTankDataValue(snapshot: event.snapshot);
//    print("AggegrateTankData for this :" + _userTankData[index].aggregateTankData.toJSON().toString());
  }

  void navigateToProfilePage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => Profile()),
    );
  }
}
