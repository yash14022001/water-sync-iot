import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:water_sync_iot/mqtt/MQTTAppState.dart';
import 'package:water_sync_iot/mqtt/MQTTManager.dart';
import 'package:flutter/cupertino.dart';
import 'package:random_string/random_string.dart';
import 'package:water_sync_iot/screens/sign_in.dart';
import 'package:water_sync_iot/service/authentication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' show Random;

class MQTTView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MQTTViewState();
  }
}

class _MQTTViewState extends State<MQTTView> {
  final TextEditingController _hostTextController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  final AuthenticationService _auth = AuthenticationService();
  MQTTAppState currentAppState;
  MQTTManager manager;
  //FirebaseAuth _userFirebaseAuth = FirebaseAuth.instance;
  final databaseReference = FirebaseDatabase.instance.reference();
  bool switchStatus = false;

  @override
  void initState() {
    super.initState();

    /*
    _hostTextController.addListener(_printLatestValue);
    _messageTextController.addListener(_printLatestValue);
    _topicTextController.addListener(_printLatestValue);

     */
    //print(_userFirebaseAuth.currentUser().toString());
    //databaseReference.child("/users/" + user.uid.toString())
  }

  @override
  void dispose() {
    _hostTextController.dispose();
    _messageTextController.dispose();
    _topicTextController.dispose();
    super.dispose();
  }

  /*
  _printLatestValue() {
    print("Second text field: ${_hostTextController.text}");
    print("Second text field: ${_messageTextController.text}");
    print("Second text field: ${_topicTextController.text}");
  }

   */

  @override
  Widget build(BuildContext context) {
    Size media = MediaQuery.of(context).size;
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    // Keep a reference to the app state.
    currentAppState = appState;
    return Scaffold(
      appBar: AppBar(
        //  backgroundColor: Colors.white,
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
//              print('Click leading');
            },
          ),
        ),
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('Water Sync'),
        ]),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              _auth.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignIn(),
                ),
              );
            },
          ),
        ],
      ),
      body: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: <Widget>[
            _buildConnectionStateText(
              _prepareStateMessageFrom(currentAppState.getAppConnectionState),
            ),
            Container(
              width: media.width * .6,
              child: ListTile(
                title: Text("Water Pump"),
                subtitle: Text("Slide to change"),
                trailing: Switch(
                  onChanged: (bool value) {
                    if (manager == null) {
                      _configureAndConnect();
                    }
                    setState(() {
                      switchStatus = value;
                    });
//                    print("-------------------------------------------------");
//                    print(value);
//                    print("-------------------------------------------------");
                    if (switchStatus == true)
                      _publishMessage("#pump_on");
                    else {
                      _publishMessage("#pump_off");
                    }
                  },
                  value: switchStatus,
                ),
              ),
            ),
            _buildConnecteButtonFrom(currentAppState.getAppConnectionState),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('MQTT'),
      backgroundColor: Colors.greenAccent,
    );
  }

  Widget _buildColumn() {
    return Column(
      children: <Widget>[
        _buildConnectionStateText(_prepareStateMessageFrom(currentAppState.getAppConnectionState)),
        _buildEditableColumn(),
        _buildScrollableTextWith(currentAppState.getHistoryText)
      ],
    );
  }

  Widget _buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          _buildTextFieldWith(_hostTextController, 'Enter broker address', currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          _buildTextFieldWith(_topicTextController, 'Enter a topic to subscribe or listen', currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          _buildPublishMessageRow(),
          const SizedBox(height: 10),
          _buildConnecteButtonFrom(currentAppState.getAppConnectionState)
        ],
      ),
    );
  }

  Widget _buildPublishMessageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: _buildTextFieldWith(_messageTextController, 'Enter a message', currentAppState.getAppConnectionState),
        ),
        _buildSendButtonFrom(currentAppState.getAppConnectionState)
      ],
    );
  }

  Widget _buildConnectionStateText(String status) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(color: Colors.deepOrangeAccent, child: Text(status, textAlign: TextAlign.center)),
        ),
      ],
    );
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText, MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if (controller == _messageTextController && state == MQTTAppConnectionState.connected) {
      shouldEnable = true;
    } else if ((controller == _hostTextController && state == MQTTAppConnectionState.disconnected) ||
        (controller == _topicTextController && state == MQTTAppConnectionState.disconnected)) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  Widget _buildScrollableTextWith(String text) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: 400,
        height: 300,
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildConnecteButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          child: RaisedButton(
            color: Colors.lightBlueAccent,
            child: const Text('Connect'),
            onPressed: state == MQTTAppConnectionState.disconnected ? _configureAndConnect : null, //
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RaisedButton(
            color: Colors.redAccent,
            child: const Text('Disconnect'),
            onPressed: state == MQTTAppConnectionState.connected ? _disconnect : null, //
          ),
        ),
      ],
    );
  }

  void sendCustomMessage(String message) {
    var state = currentAppState.getAppConnectionState;
    state == MQTTAppConnectionState.connected
        ? _publishMessage(_messageTextController.text)
        : print("-----------------Not Connected------------------");
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return RaisedButton(
      color: Colors.green,
      child: const Text('Send'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null, //
    );
  }

  // Utility functions
  String _prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        return 'Connected';
      case MQTTAppConnectionState.connecting:
        return 'Connecting';
      case MQTTAppConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  void _configureAndConnect() {
    // TODO: Use UUID
    String osPrefix = 'Flutter_iOS';
    if (Platform.isAndroid) {
      osPrefix = "sdf";
    }
    manager =
        MQTTManager(host: _hostTextController.text, topic: _topicTextController.text, identifier: randomAlphaNumeric(20), state: currentAppState);
    manager.initializeMQTTClient();
    manager.connect();
  }

  void _disconnect() {
    manager.disconnect();
  }

  void _publishMessage(String text) {
    final String message = text;
    manager.publish(message);
    _messageTextController.clear();
  }
}
