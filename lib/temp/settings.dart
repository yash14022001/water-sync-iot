import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';
import 'package:water_sync_iot/mqtt/MQTTAppState.dart';
import 'package:water_sync_iot/mqtt/MQTTManager.dart';
import 'package:water_sync_iot/widgets/app_bar.dart';
import 'package:water_sync_iot/widgets/connection_label.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _autoMode = false; //TODO: FETCH VALUE FROM DB
  MQTTManager manager;
  MQTTAppState currentMQTTState;


  @override
  Widget build(BuildContext context) {
    this.currentMQTTState = Provider.of<MQTTAppState>(context);

    if (manager == null) {
      _configureAndConnect();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "Profile",
      ),
      body: Column(
        children: <Widget>[
          ConnectionLabel(
            state: currentMQTTState.getAppConnectionState,
            onPressHandler: this._configureAndConnect,
          ),
          Card(
            elevation: 5,
            margin: EdgeInsets.all(5),
            child: ListTile(
              contentPadding: EdgeInsets.all(5),
              title: Text(
                "Enable Automatic Mode",
                style: TextStyle(color: Theme.of(context).accentColor,
                fontWeight: FontWeight.bold),

              ),
              subtitle:
                  Text("It decides whether or not system should control pump"),
              trailing: Switch(
                onChanged: (bool value) {
                  setState(() {
                    _autoMode = value;
                  });

                  if (_autoMode == true) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "Enabling auto mode...please wait", style: TextStyle(
                          fontWeight: FontWeight.bold),),
                      duration: Duration(milliseconds: 800),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                    ));
                    _publishMessage("#autoMode_on");
                  }
                  else {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Disabling auto mode...please wait",style: TextStyle(fontWeight: FontWeight.bold),),
                      duration: Duration(milliseconds: 800),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                    ));
                  _publishMessage("#autoMode_off");
                  }
                },
                value: _autoMode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _publishMessage(String text) {
    final String message = text;
    manager.publish(message);
  }

  void _configureAndConnect() {
    manager = MQTTManager(host: "", topic: "", identifier: randomAlphaNumeric(20), state: currentMQTTState);
    manager.initializeMQTTClient();
    manager.connect();
  }
}
