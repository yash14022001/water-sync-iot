import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:water_sync_iot/models/data_constants.dart';
import 'package:water_sync_iot/mqtt/MQTTAppState.dart';
import '../models/tank_data.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class _Example01Tile extends StatelessWidget {
  const _Example01Tile(this.backgroundColor, this.iconData);

  final Color backgroundColor;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return new Card(
      color: backgroundColor,
      child: new InkWell(
        onTap: () {},
        child: new Center(
          child: new Padding(
            padding: const EdgeInsets.all(4.0),
            child: new Icon(
              iconData,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class QuickAccessTank extends StatefulWidget {
  final MQTTAppConnectionState state;
  final Function onOnOffPressHandler;

  final TankData tankData;

  bool switchStatus;

  /*List<StaggeredTile> _staggeredTiles = const <StaggeredTile>[
    const StaggeredTile.count(2, 2),
    const StaggeredTile.count(2, 1),
    const StaggeredTile.count(2, 1),
    const StaggeredTile.count(2, 2),
    const StaggeredTile.count(2, 1),
    const StaggeredTile.count(2, 1),
    const StaggeredTile.count(2, 1),
    const StaggeredTile.count(2, 1),
  ];

  List<Widget> _tiles = const <Widget>[
    const _Example01Tile(Colors.green, Icons.widgets),
    const _Example01Tile(Colors.lightBlue, Icons.wifi),
    const _Example01Tile(Colors.amber, Icons.panorama_wide_angle),
    const _Example01Tile(Colors.brown, Icons.map),
    const _Example01Tile(Colors.deepOrange, Icons.send),
    const _Example01Tile(Colors.indigo, Icons.airline_seat_flat),
    const _Example01Tile(Colors.red, Icons.bluetooth),
    const _Example01Tile(Colors.pink, Icons.battery_alert),
    /*const _Example01Tile(Colors.purple, Icons.desktop_windows),
    const _Example01Tile(Colors.blue, Icons.radio),*/
  ];*/


  QuickAccessTank({this.tankData, this.state, this.onOnOffPressHandler}) {
//    print("Passed tank data is :" + tankData.latestTankData.toJSON().toString());
    switchStatus = (this.tankData.latestTankData.pumpState == Pump.ON) ? true : false;
  }

  @override
  _QuickAccessTankState createState() => _QuickAccessTankState();
}

class _QuickAccessTankState extends State<QuickAccessTank> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /*setState(() {
      switchStatus = this.widget.tankData.latestTankData.pumpState == Pump.ON ? true : false;
    });*/
    return Container(
      padding: EdgeInsets.all(2),
      height: 320,
      width: double.infinity,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        borderOnForeground: true,
        child: Column(
          children: <Widget>[
            //TITLE BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 9,
                  child: Text(
                    this.widget.tankData.tankName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_right),
                  onPressed: () {
                    // TODO : Specific tank page route
                  },
                ),
              ],
            ),
            /*Expanded(
              child: new StaggeredGridView.count(
                crossAxisCount: 4,
                staggeredTiles: this.widget._staggeredTiles,
                children: this.widget._tiles,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
              ),
            ),*/
            //BODY
            //STATUS AND SINCE_ON
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Status"),
                          Expanded(
                            flex: 6,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 4,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Text(this.widget.tankData.latestTankData.getPumpState),
                                  ),
                                ),
                                Expanded(
                                  flex: 6,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Semantics(
                                      child: Switch(
                                        value: this.widget.switchStatus,
                                        /*onChanged: (value) {
                                          //TODO : OnChanged
                                        },*/
                                        onChanged: (this.widget.state == MQTTAppConnectionState.connected)
                                            ? this._onCupertinoSwitchPress
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  rowVerticalDivider(),
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Last Updated"),
                          cellBody(
                              numValue: (this.widget.tankData.latestTankData.lastUpdated == "--")
                                  ? "-- "
                                  : parseFormattedDate(timeStamp: this.widget.tankData.latestTankData.lastUpdated)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            columnHorizontalDivider(),
            //INLET_FLOW AND OUTLET_FLOW
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Inlet Flow"),
                          cellBody(numValue: this.widget.tankData.latestTankData.inletFLow, unitValue: "L/sec"),
                        ],
                      ),
                    ),
                  ),
                  rowVerticalDivider(),
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Outlet Flow"),
                          cellBody(numValue: this.widget.tankData.latestTankData.outletFlow, unitValue: "L/sec"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            columnHorizontalDivider(),

            //WATER_LEVEL AND NO_OF_TIMES
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Total Usage"),
                          //cellBody(numValue: this.widget.aggregateTankState.usage.toString(), unitValue: "litres"),
                          cellBody(
                              numValue: this.widget.tankData.aggregateTankData.usage.toString(), unitValue: "L"),
                        ],
                      ),
                    ),
                  ),
                  rowVerticalDivider(),
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Total Loss"),
                          cellBody(
                              numValue: this.widget.tankData.aggregateTankData.loss.toString(), unitValue: "L"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            columnHorizontalDivider(),
            //
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Number of times switched on :"),
                          cellBody(numValue: this.widget.tankData.aggregateTankData.numberOfTimesSwitchOn.toString()),
                        ],
                      ),
                    ),
                  ),
                  rowVerticalDivider(),
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Current Water Level"),
                          cellBody(numValue: this.widget.tankData.latestTankData.getWaterLevel),
                          //getWaterLevelLabel(this.widget.tankData.latestTankData.currentWaterLevel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            /*columnHorizontalDivider(),
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Today's Max. Level"),
                          cellBody(numValue: "Level 7"),
                        ],
                      ),
                    ),
                  ),
                  rowVerticalDivider(),
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellTitle(title: "Today's Min. Level"),
                          cellBody(numValue: "Level 1"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  Widget rowCards() {
    return Expanded(
      flex: 5,
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
            /*border: Border.all(
            color: Colors.black87,
          ),*/
            ),
      ),
    );
  }

  Widget rowVerticalDivider() {
    return VerticalDivider(
      width: 1,
      color: Colors.grey,
    );
  }

  Widget columnHorizontalDivider() {
    return Divider(
      height: 1,
      color: Colors.grey,
    );
  }

  Widget cellTitle({String title}) {
    return Expanded(
      flex: 2,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget cellBody({String numValue, String unitValue}) {
    if (unitValue == null) {
      return Expanded(
        flex: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(numValue),
              ),
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        flex: 8,
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                child: Text(numValue),
              ),
            ),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    unitValue,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  String parseFormattedDate({String timeStamp}) {
    return DateFormat('yyyy-MM-dd \n kk:mm:ss')
        .format((DateTime.fromMillisecondsSinceEpoch(int.parse(timeStamp) * 1000)).subtract(Duration(hours: 1)));
  }

  Expanded getWaterLevelLabel(WaterLevel waterLevel) {
    return Expanded(
      flex: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                "HIGH",
                style: TextStyle(
                  color: (waterLevel == WaterLevel.HIGH) ? Colors.greenAccent : Colors.grey,
                ),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                "MEDIUM",
                style: TextStyle(
                  color: (waterLevel == WaterLevel.MEDIUM) ? Colors.yellowAccent : Colors.grey,
                ),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                "LOW",
                style: TextStyle(
                  color: (waterLevel == WaterLevel.LOW) ? Colors.redAccent : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCupertinoSwitchPress(value) {
    setState(() {
      this.widget.switchStatus = value;
    });
    this.widget.onOnOffPressHandler(value);
  }
}
