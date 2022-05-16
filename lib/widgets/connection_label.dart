import 'package:flutter/material.dart';
import 'package:water_sync_iot/mqtt/MQTTAppState.dart';

class ConnectionLabel extends StatelessWidget {

  String message;
  Color bg;
  bool requireConnectButton;
  final MQTTAppConnectionState state;
  final Function onPressHandler;

  static const bool DEBUG = false;

  ConnectionLabel({this.state, this.onPressHandler}){
    if(state == MQTTAppConnectionState.connected){
      message = "Connected to Server";
      requireConnectButton = false;
      bg = Colors.green;
      if(DEBUG) print("----Changed to green theme----------");
    } else if(state == MQTTAppConnectionState.connecting){
      message = "Connecting to Server";
      bg = Colors.yellowAccent;
      requireConnectButton = false;
      if(DEBUG) print("----Changed to yellow theme----------");
    } else {
      message = "Disconnected to Server";
      bg = Colors.deepOrange;
      requireConnectButton = true;
      if(DEBUG) print("----Changed to orange theme----------");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: bg,
      child: Container(
        padding: EdgeInsets.all(2),
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: this.connectionBody(),
      ),
    );
  }

  Widget connectionBody(){
    if (!requireConnectButton) {
      return Text(
        message,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            message,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          SizedBox(
            height: 20,
            child: RaisedButton(
              child: Text("Connect"),
              color: Colors.green,
              onPressed: () {
                this.onPressHandler();
              },
            ),
          ),
        ],
      );
    }
  }
}