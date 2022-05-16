import 'package:flutter/material.dart';

class NotificationBadge extends StatefulWidget {

  final GlobalKey<ScaffoldState> scaffoldKey;

  NotificationBadge({this.scaffoldKey});

  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();

}

class _NotificationBadgeState extends State<NotificationBadge> {

  int counter = 5;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        new IconButton(icon: Icon(Icons.notifications), onPressed: () {
          setState(() {
            counter++;
          });
          this.widget.scaffoldKey.currentState.openDrawer();
        }),
        counter != 0 ? new Positioned(
          right: 10,
          top: 14,
          child: new Container(
            padding: EdgeInsets.all(2),
            decoration: new BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: BoxConstraints(
              minWidth: 14,
              minHeight: 14,
            ),
            child: Text(
              '$counter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ) : new Container()
      ],
    );
  }
}