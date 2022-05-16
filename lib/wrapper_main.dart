import 'package:flutter/material.dart';
import 'package:water_sync_iot/screens/sign_in.dart';
import 'package:water_sync_iot/service/authenticate.dart';
import 'package:water_sync_iot/screens/home.dart';

class WrapperMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Authenticate();
  }
}
