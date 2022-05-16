import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:water_sync_iot/models/tank_data.dart';
import 'package:water_sync_iot/screens/profile.dart';
import 'package:water_sync_iot/smartconfig/smart_config_main.dart';
import 'package:water_sync_iot/service/data_base_queries.dart';
import 'package:water_sync_iot/temp/reports.dart';
import 'package:water_sync_iot/temp/settings.dart';
import '../mqtt/MQTTAppState.dart';
import './test.dart';

import './home.dart';

class PreHome extends StatefulWidget {
  @override
  _PreHomeState createState() => _PreHomeState();
}

class _PreHomeState extends State<PreHome> {
  int _currentIndex = 0;
  List<Widget> _children = [
    Home(),
    Profile(),
    SmartConfigMain(),
    Reports(),
    Settings(),
  ];

  @override
  Widget build(BuildContext context) {
//    print("--------------Called PreHome.build---------------");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MQTTAppState>(
          create: (_) => MQTTAppState(),
        ),
        ChangeNotifierProvider<DataBaseConnection>(
          create: (_) => DataBaseConnection(),
        ),
      ],
      child: Scaffold(
        body: _children[_currentIndex],
        bottomNavigationBar: new Theme(
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
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                title: Text('Settings',style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

