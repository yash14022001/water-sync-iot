import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './service/authenticate.dart';

void main() {
  //Provider.debugCheckInvalidValueType = null;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      darkTheme: ThemeData.dark(),
      //home: WrapperMain(),
      //home: Home(),
      home: Authenticate(),
    );
  }
}