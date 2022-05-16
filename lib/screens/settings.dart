import 'package:flutter/material.dart';
import 'package:water_sync_iot/widgets/app_bar.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Profile",
      ),
      body: ListView(
        children: <Widget>[
          Text("Ebable Auto mode"),
          Text("Enable Leakage Detection"),
          Text("Enable Inlet flow"),
          Text("Enable Outlet flow"),
        ],
      ),

    );
  }

}
