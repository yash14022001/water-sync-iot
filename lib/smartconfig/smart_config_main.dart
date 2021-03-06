import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info/device_info.dart';
import 'package:water_sync_iot/screens/sign_in.dart';
import 'package:water_sync_iot/widgets/notifications_icon.dart';

// Note support only Android
// for iOS https://github.com/lou-lan/SmartConfig

class SmartConfigMain extends StatefulWidget {
  SmartConfigMain({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SmartConfigMainState createState() => _SmartConfigMainState();
}

class _SmartConfigMainState extends State<SmartConfigMain> {
  static const platform = const MethodChannel('samples.flutter.io/esptouch');
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  final TextEditingController _bssidFilter = new TextEditingController();
  final TextEditingController _ssidFilter = new TextEditingController();
  final TextEditingController _passwordFilter = new TextEditingController();

  final GlobalKey<ScaffoldState> _homeScaffoldKey =
      new GlobalKey<ScaffoldState>();

  bool _isLoading = false;

  String _ssid = "";
  String _bssid = "";
  String _password = "";
  String _msg = "";

  _MyHomePageState() {
    _ssidFilter.addListener(_ssidListen);
    _passwordFilter.addListener(_passwordListen);
    _bssidFilter.addListener(_bssidListen);
  }

  void _ssidListen() {
//    print("_ssidListen called");
    if (_ssidFilter.text.isEmpty) {
      _ssid = "";
    } else {
      _ssid = _ssidFilter.text;
    }
  }

  void _bssidListen() {
    if (_bssidFilter.text.isEmpty) {
      _bssid = "";
    } else {
      _bssid = _bssidFilter.text;
    }
  }

  void _passwordListen() {
    if (_passwordFilter.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFilter.text;
    }
  }

  Future<void> _configureEsp() async {
    String output = "";

    setState(() {
      _isLoading = true;
    });

//    print("ssid : $_ssid");
//    print("bssid : $_bssid");
//    print("password : $_password");

    try {
      // Change if required.
      const String deviceCount = "1"; //  the expect result count
      const String broadcast = "1"; // broadcast or multicast
      const Duration _kLongTimeout = const Duration(seconds: 20);

      final String result =
          await platform.invokeMethod('startSmartConfig', <String, dynamic>{
        'ssid': _ssid,
        'bssid': _bssid,
        'pass': _passwordFilter.text,
        'deviceCount': deviceCount,
        'broadcast': broadcast,
      }).timeout(_kLongTimeout);

      final parsed = json.decode(result);
      final devices = parsed["devices"];

      output = "Following devices configured: \n\n";

      for (var device in devices) {
        output += "bssid: ${device["bssid"]} ip: ${device["ip"]} \n";
      }

      _msg = output;
    } on PlatformException catch (e) {
      output = "Failed to configure: '${e.message}'.";
    }

    setState(() {
      _isLoading = false;
      _msg = output;
    });
  }

  Future<void> _getConnectedWiFiInfo() async {
    String ssid = "";
    String bssid = "";
    String msg = "";

    /*if (Platform.isIOS) {
      print('is a IOS');
    } else if (Platform.isAndroid) {
      // Note Build.VERSION.SDK_INT >= 28 needs Manifest.permission.ACCESS_COARSE_LOCATION
      AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;
      if (build.version.sdkInt >= 28) {
        //Permission permission = Permission.AccessCoarseLocation;
        ServiceStatus serviceStatus = await PermissionHandler().checkServiceStatus(PermissionGroup.location);
        final res = await SimplePermissions.checkPermission(permission);

        if(res == false) {
            final res = await SimplePermissions.requestPermission(permission);
            print("permission request result is " + res.toString());
        }
      }
    }*/

    try {
      String wiFiInfo = await platform.invokeMethod('getConnectedWiFiInfo');
      final parsed = json.decode(wiFiInfo);
      ssid = parsed["ssid"];
      bssid = parsed["bssid"];

//      print("ssid in try : $ssid");
//      print("bssid int try : $bssid");

      msg = 'Connected ssid name is $ssid. bssid is $bssid';

      if (parsed["is5G"] == 'yes') {
        msg += ". Connected to a 5G network. Cannot use OneTouch SmartConfig!";
      }
    } on PlatformException catch (e) {
      msg = "Failed to get connected WiFi name: '${e.message}'.";
    }

    setState(() {
      _ssidFilter.text = ssid;
      _bssidFilter.text = bssid;

      _msg = msg;
      _ssid = ssid;
      _bssid = bssid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart config"),
        leading: NotificationBadge(
          scaffoldKey: _homeScaffoldKey,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              //TODO : Logout
              Navigator.push(context,
                  new MaterialPageRoute(builder: (context) => SignIn()));
            },
          ),
        ],
      ),
      body: Center(
          child: _isLoading
              ? Container(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                    ),
                  ),
                  color: Colors.white.withOpacity(0.8),
                )
              : new Container(
                  padding: new EdgeInsets.all(10.0),
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(height: 10),
                      new Container(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                            Text("ESP Touch v0.3.7.0"),
                            new TextField(
                              controller: _ssidFilter,
                              decoration:
                                  new InputDecoration(labelText: 'ssid'),
                            ),
                            new TextField(
                              controller: _bssidFilter,
                              decoration:
                                  new InputDecoration(labelText: 'bssid'),
                            ),
                            RaisedButton(
                              child: Text('Get Connected WiFi details'),
                              onPressed: _getConnectedWiFiInfo,
                            )
                          ])),
                      new Container(
                        child: new TextField(
                          controller: _passwordFilter,
                          decoration:
                              new InputDecoration(labelText: 'Password'),
                        ),
                      ),
                      new RaisedButton(
                        child: new Text('Configure ESP'),
                        onPressed: _configureEsp,
                      ),
                      new Container(height: 10),
                      Text(_msg),
                    ],
                  ))

          // This trailing comma makes auto-formatting nicer for build methods.
          ),
    );
  }
}
