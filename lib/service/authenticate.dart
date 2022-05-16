import 'package:flutter/material.dart';
import 'package:water_sync_iot/screens/sign_in.dart';
import 'package:water_sync_iot/service/authentication_service.dart';
import 'package:water_sync_iot/temp/pre_home.dart';

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  // Holds which screen to display. (Home screen OR Login Screen)
  var _screen;

  @override
  void initState() {
    super.initState();
    AuthenticationService _authService = AuthenticationService();
    _authService.getLoggedInUser().then((user) {
      if (user != null) {
        setState(() {
          _screen = PreHome();
        });
      } else {
        setState(() {
          _screen = SignIn();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _screen,
    );
  }
}
