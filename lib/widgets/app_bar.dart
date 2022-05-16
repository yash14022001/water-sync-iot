import 'package:flutter/material.dart';
import 'package:water_sync_iot/screens/sign_in.dart';

import 'notifications_icon.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  String _title;

  @override
  final Size preferredSize;

  CustomAppBar({String title}) : this.preferredSize = Size.fromHeight(60) {
    this._title = title;
  }

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

}

class _CustomAppBarState extends State<CustomAppBar> {
  final GlobalKey<ScaffoldState> _customAppBarScaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(this.widget._title),
      leading: NotificationBadge(
        scaffoldKey: this._customAppBarScaffoldKey,
      ),

      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {

          },
        ),
        IconButton(
          icon: Icon(Icons.power_settings_new),
          onPressed: () {
            //TODO : Logout
            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => SignIn()));
          },
        ),
      ],
    );
  }
}
