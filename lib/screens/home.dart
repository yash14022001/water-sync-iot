import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:water_sync_iot/mqtt/mqttView.dart';
import 'package:water_sync_iot/mqtt/MQTTAppState.dart';
import 'package:provider/provider.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ChangeNotifierProvider<MQTTAppState>(
          builder: (_) => MQTTAppState(),
          child: MQTTView(),
        ));
  }
}
