import 'dart:async';

/// Timeseries chart example
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';
import 'package:water_sync_iot/models/data_constants.dart';
import 'package:water_sync_iot/models/tank_data.dart';
import 'package:water_sync_iot/mqtt/MQTTAppState.dart';
import 'package:water_sync_iot/service/data_base_queries.dart';
import 'package:water_sync_iot/temp/export_data.dart';
import 'package:water_sync_iot/widgets/notifications_icon.dart';

class Reports extends StatelessWidget {
  final GlobalKey<ScaffoldState> _reportScaffoldKey = new GlobalKey<ScaffoldState>();
  DataBaseConnection dbConnection;

  //Reports({Key key, @required this.dbConnection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    this.dbConnection = Provider.of<DataBaseConnection>(context);
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
          appBar: AppBar(
            title: Text("Reports"),
            leading: NotificationBadge(
              scaffoldKey: _reportScaffoldKey,
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  //TODO : Settings Panel
                  addNewDataValueInFirebase();
                },
              ),
              IconButton(
                icon: Icon(Icons.power_settings_new),
                onPressed: () {
                  //TODO : Logout
                },
              ),
            ],
          ),
          body: SimpleTimeSeriesChart(this.dbConnection.getTankData, this.dbConnection),
      ),
    );
  }

  void addNewDataValueInFirebase() {
    LatestTankDataDump itd;
    TankData td;

    itd = new LatestTankDataDump();
    itd.lastUpdated = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    itd.inletFLow = randomBetween(1, 1500).toString();
    itd.outletFlow = randomBetween(1, 1500).toString();
    itd.currentWaterLevel = getRandomWaterLevel();
    itd.pumpState = getRandomPumpValue();

    td = new TankData(macID: "testMAC1234", latestTankData: itd);
    this
        .dbConnection
        .getDatabase
        .reference()
        .child("/users/" +
            this.dbConnection.getFirebaseUser.uid +
            "/hardware/data_values/" +
            td.macID +
            "/" +
            td.latestTankData.lastUpdated)
        .set(td.latestTankData.toJSONFirebase());

    itd = new LatestTankDataDump();
    itd.lastUpdated = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    itd.inletFLow = randomBetween(1, 1500).toString();
    itd.outletFlow = randomBetween(1, 1500).toString();
    itd.currentWaterLevel = getRandomWaterLevel();
    itd.pumpState = getRandomPumpValue();

    td = new TankData(macID: "testMAC5678", latestTankData: itd);
    this
        .dbConnection
        .getDatabase
        .reference()
        .child("/users/" +
            this.dbConnection.getFirebaseUser.uid +
            "/hardware/data_values/" +
            td.macID +
            "/" +
            td.latestTankData.lastUpdated)
        .set(td.latestTankData.toJSONFirebase());

    itd = new LatestTankDataDump();
    itd.lastUpdated = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    itd.inletFLow = randomBetween(1, 1500).toString();
    itd.outletFlow = randomBetween(1, 1500).toString();
    itd.currentWaterLevel = getRandomWaterLevel();
    itd.pumpState = getRandomPumpValue();

    td = new TankData(macID: "testMAC9012", latestTankData: itd);
    this
        .dbConnection
        .getDatabase
        .reference()
        .child("/users/" +
            this.dbConnection.getFirebaseUser.uid +
            "/hardware/data_values/" +
            td.macID +
            "/" +
            td.latestTankData.lastUpdated)
        .set(td.latestTankData.toJSONFirebase());
  }

  Pump getRandomPumpValue() {
    switch (randomBetween(0, 2)) {
      case 0:
        return Pump.OFF;
      case 1:
        return Pump.ON;
    }
  }

  WaterLevel getRandomWaterLevel() {
    switch (randomBetween(0, 3)) {
      case 0:
        return WaterLevel.HIGH;
      case 1:
        return WaterLevel.LOW;
      case 2:
        return WaterLevel.MEDIUM;
    }
  }
}

class SimpleTimeSeriesChart extends StatefulWidget {
  List<TankData> _userTankData;
  DataBaseConnection db;

  List<IntegerDatetimeDataDump> inletData = [];
  List<IntegerDatetimeDataDump> outletData = [];
  List<IntegerDatetimeDataDump> usageData = [];
  List<IntegerDatetimeDataDump> pumpOnCountData = [];
  List<WaterLevelDateTimeDataDump> waterLevelData = [];

  List<charts.Series<IntegerDatetimeDataDump, DateTime>> inletOutletSeriesList;
  List<charts.Series<IntegerDatetimeDataDump, DateTime>> usageSeriesList;
  List<charts.Series<IntegerDatetimeDataDump, String>> pumpOnCountSeriesList;
  List<charts.Series<WaterLevelDateTimeDataDump, DateTime>> waterLevelSeriesList;

  List<String> tankNames = [];
  String selectedTankItem;
  int selectedTankItemIndex = 0;

  bool animate = false;
  //DateTime dt = DateTime.now();

  SimpleTimeSeriesChart(List<TankData> td, DataBaseConnection passedDb) {
    this._userTankData = td;
    this.db = passedDb;

    selectedTankItem = this._userTankData[0].tankName;
    for (int i = 0; i < this._userTankData.length; i++) {
      tankNames.add(this._userTankData[i].tankName);
    }

    populateDataInDataList();
  }

  void populateDataInDataList() {
    inletData.clear();
    outletData.clear();
    usageData.clear();
//    pumpOnCountData.clear();
    waterLevelData.clear();

    double usageCounter = this._userTankData[this.selectedTankItemIndex].aggregateTankData.usage;
    for (int i = this._userTankData[this.selectedTankItemIndex].todaysTankData.length - 1, count = 0;
        i >= 0 && count < 10;
        i--, count++) {
      inletData.add(IntegerDatetimeDataDump(
          convertTimeStampToDateTime(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].lastUpdated),
          int.parse((double.parse(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].inletFLow) * 1000)
              .toStringAsFixed(0))));
      outletData.add(IntegerDatetimeDataDump(
          convertTimeStampToDateTime(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].lastUpdated),
          int.parse((double.parse(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].outletFlow) * 1000)
              .toStringAsFixed(0))));
      usageData.add(IntegerDatetimeDataDump(
          convertTimeStampToDateTime(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].lastUpdated),
          usageCounter ~/ 1));
      usageCounter -= double.parse(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].outletFlow);
//      pumpOnCountData.add(IntegerDatetimeDataDump(convertTimeStampToDateTime(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].lastUpdated), this._userTankData[this.selectedTankItemIndex].aggregateTankData.numberOfTimesSwitchOn));
      waterLevelData.add(WaterLevelDateTimeDataDump(
          convertTimeStampToDateTime(this._userTankData[this.selectedTankItemIndex].todaysTankData[i].lastUpdated),
          this._userTankData[this.selectedTankItemIndex].todaysTankData[i].currentWaterLevel));
    }

    bindWaterlevelSeriesList();
    bindUsageSeriesList();
//    bindPumpOnCountSeriesList();
    bindInletOutletSeriesList();
  }

  void bindInletOutletSeriesList() {
//    print("----------------inletoutlet binding" + this.inletData.length.toString() + "------------------");
    this.inletOutletSeriesList = [
      new charts.Series<IntegerDatetimeDataDump, DateTime>(
        id: 'Inlet Flow',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => sales.time,
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.inletData,
      ),
      new charts.Series<IntegerDatetimeDataDump, DateTime>(
        id: 'Outlet Flow',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => sales.time,
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.outletData,
      ),
    ];
  }

  void bindUsageSeriesList() {
//    print("----------------usage binding" + this.usageData.length.toString() + "------------------");
    this.usageSeriesList = [
      new charts.Series<IntegerDatetimeDataDump, DateTime>(
        id: 'Usage',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => sales.time,
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.usageData,
      ),
    ];
  }

  void bindWaterlevelSeriesList() {
//    print("----------------waterlevel binding" + this.waterLevelData.length.toString() + "------------------");
    this.waterLevelSeriesList = [
      new charts.Series<WaterLevelDateTimeDataDump, DateTime>(
        id: 'Water Level',
        colorFn: (WaterLevelDateTimeDataDump sales, __) {
          switch (sales.waterLevel) {
            case WaterLevel.HIGH:
              {
                return charts.MaterialPalette.blue.shadeDefault;
              }
            case WaterLevel.LOW:
              {
                return charts.MaterialPalette.deepOrange.shadeDefault;
              }
            case WaterLevel.MEDIUM:
              {
                return charts.MaterialPalette.yellow.shadeDefault;
              }
            default:
              {
                return charts.MaterialPalette.red.shadeDefault;
              }
          }
        },
        domainFn: (WaterLevelDateTimeDataDump sales, _) => sales.time,
        measureFn: (WaterLevelDateTimeDataDump sales, _) => sales.integerLevel,
        data: this.waterLevelData,
      ),
    ];
  }

  void bindPumpOnCountSeriesList() {
//    print("----------------pumponoff binding" + this.pumpOnCountData.length.toString() + "------------------");
    this.pumpOnCountSeriesList = [
      new charts.Series<IntegerDatetimeDataDump, String>(
        id: 'Pump On Count',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => DateFormat.E().format(sales.time).toString(),
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.pumpOnCountData,
      ),
    ];
  }

  DateTime convertTimeStampToDateTime(String timeStamp) {
    return DateTime.fromMillisecondsSinceEpoch(int.parse(timeStamp) * 1000);
  }

  @override
  _SimpleTimeSeriesChartState createState() => _SimpleTimeSeriesChartState();
}

class _SimpleTimeSeriesChartState extends State<SimpleTimeSeriesChart> {
  Timer _timer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.blue,
              child: Text("Export data to pdf"),
              textColor: Colors.white,
              onPressed: () => Navigator.push(context, new MaterialPageRoute(builder: (context) => ExportDataForm())),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(
                  "Select Tank :",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                flex: 7,
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text(this.widget.selectedTankItem),
                  items: this.widget.tankNames.map((String value) {
                    return new DropdownMenuItem<String>(
                      value: value,
                      child: new Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      this.widget.selectedTankItem = val;
                      this.widget.selectedTankItemIndex = this.widget.tankNames.indexOf(val);
                      this.widget.populateDataInDataList();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 9,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              this.drawUsageGraph(),
              this.drawInletOutletGraph(),
//              this.drawPumpOnCountGraph(),
//              this.drawWaterLevelGraph(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    bindInletOutletSeriesList();
//    bindPumpOnCountSeriesList();
    bindUsageSeriesList();
    bindWaterlevelSeriesList();

    /*_timer = Timer.periodic(Duration(seconds: 2), (_) {
      print("Called entry adder");
      this.widget.dt = this.widget.dt.add(Duration(minutes: 1));
      if (this.mounted) {
        this.setState(() {
          this.widget.inletData.removeAt(0);
          this.widget.inletData.add(IntegerDatetimeDataDump(this.widget.dt, randomBetween(1, 100)));
          this.widget.outletData.removeAt(0);
          this.widget.outletData.add(IntegerDatetimeDataDump(this.widget.dt, randomBetween(1, 100)));
          this.widget.usageData.removeAt(0);
          this.widget.usageData.add(IntegerDatetimeDataDump(this.widget.dt, randomBetween(1, 100)));
          this.widget.waterLevelData.removeAt(0);
          this
              .widget
              .waterLevelData
              .add(WaterLevelDateTimeDataDump(this.widget.dt, WaterLevel.values[randomBetween(0, 4)]));

          bindInletOutletSeriesList();
          bindPumpOnCountSeriesList();
          bindUsageSeriesList();
          bindWaterlevelSeriesList();
        });
      }
    });*/
  }

  @override
  void dispose() {
    //_timer.cancel();
    super.dispose();
  }

  Widget drawInletOutletGraph() {
    return Container(
      height: 300,
      width: double.infinity,
      child: Card(
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: new charts.TimeSeriesChart(
          widget.inletOutletSeriesList,
          animate: widget.animate,
          // Optionally pass in a [DateTimeFactory] used by the chart. The factory
          // should create the same type of [DateTime] as the data provided. If none
          // specified, the default creates local date time.
          primaryMeasureAxis:
              new charts.NumericAxisSpec(tickProviderSpec: new charts.BasicNumericTickProviderSpec(zeroBound: false)),
          domainAxis: new charts.DateTimeAxisSpec(
              tickFormatterSpec: new charts.AutoDateTimeTickFormatterSpec(
            hour: new charts.TimeFormatterSpec(
              format: 'mm',
              transitionFormat: 'HH:mm',
            ),
          )),
          dateTimeFactory: const charts.LocalDateTimeFactory(),
          behaviors: [
            new charts.ChartTitle('Inlet-Outlet FLow',
                subTitle: '',
                behaviorPosition: charts.BehaviorPosition.top,
                titleOutsideJustification: charts.OutsideJustification.middle,
                titleStyleSpec: charts.TextStyleSpec(
                  color: charts.ColorUtil.fromDartColor(Colors.deepPurpleAccent),
                  fontWeight: "bold",
                ),
                // Set a larger inner padding than the default (10) to avoid
                // rendering the text too close to the top measure axis tick label.
                // The top tick label may extend upwards into the top margin region
                // if it is located at the top of the draw area.
                innerPadding: 18),
            new charts.ChartTitle('Time',
                titleStyleSpec: charts.TextStyleSpec(
                  fontSize: 15,
                  color: charts.ColorUtil.fromDartColor(Colors.deepPurpleAccent),
                ),
                behaviorPosition: charts.BehaviorPosition.bottom,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.ChartTitle('Water Flow(Litres)',
                titleStyleSpec: charts.TextStyleSpec(
                  fontSize: 15,
                  color: charts.ColorUtil.fromDartColor(Colors.deepPurpleAccent),
                ),
                behaviorPosition: charts.BehaviorPosition.start,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.SeriesLegend(
              position: charts.BehaviorPosition.bottom,
              horizontalFirst: true,
              cellPadding: new EdgeInsets.only(right: 4.0, bottom: 4.0),
              showMeasures: true,
              measureFormatter: (num value) {
                return value == null ? '-' : '${value}k';
              },
            ),
            /*new charts.ChartTitle('End title',
                    behaviorPosition: charts.BehaviorPosition.end,
                    titleOutsideJustification:
                    charts.OutsideJustification.middleDrawArea),*/
          ],
        ),
      ),
    );
  }

  Widget drawUsageGraph() {
    return Container(
      height: 300,
      width: double.infinity,
      child: Card(
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: new charts.TimeSeriesChart(
          widget.usageSeriesList,
          animate: widget.animate,
          // Optionally pass in a [DateTimeFactory] used by the chart. The factory
          // should create the same type of [DateTime] as the data provided. If none
          // specified, the default creates local date time.
          primaryMeasureAxis:
              new charts.NumericAxisSpec(tickProviderSpec: new charts.BasicNumericTickProviderSpec(zeroBound: false)),
          domainAxis: new charts.DateTimeAxisSpec(
              tickFormatterSpec: new charts.AutoDateTimeTickFormatterSpec(
            hour: new charts.TimeFormatterSpec(
              format: 'mm',
              transitionFormat: 'HH:mm',
            ),
          )),
          dateTimeFactory: const charts.LocalDateTimeFactory(),
          behaviors: [
            new charts.ChartTitle('Water Usage',
                subTitle: '',
                behaviorPosition: charts.BehaviorPosition.top,
                titleOutsideJustification: charts.OutsideJustification.middle,
                titleStyleSpec: charts.TextStyleSpec(
                  color: charts.Color.fromHex(code: "#1299e5"),
                  fontWeight: "bold",
                ),
                // Set a larger inner padding than the default (10) to avoid
                // rendering the text too close to the top measure axis tick label.
                // The top tick label may extend upwards into the top margin region
                // if it is located at the top of the draw area.
                innerPadding: 18),
            new charts.ChartTitle('Time',
                behaviorPosition: charts.BehaviorPosition.bottom,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.ChartTitle('Usage in Litres',
                behaviorPosition: charts.BehaviorPosition.start,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.SeriesLegend(),
            /*new charts.ChartTitle('End title',
                    behaviorPosition: charts.BehaviorPosition.end,
                    titleOutsideJustification:
                    charts.OutsideJustification.middleDrawArea),*/
          ],
        ),
      ),
    );
  }

  Widget drawPumpOnCountGraph() {
    return Container(
      height: 300,
      width: double.infinity,
      child: Card(
        elevation: 2.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: new charts.BarChart(
          widget.pumpOnCountSeriesList,
          animate: widget.animate,
          // Optionally pass in a [DateTimeFactory] used by the chart. The factory
          // should create the same type of [DateTime] as the data provided. If none
          // specified, the default creates local date time.
          /*primaryMeasureAxis: new charts.NumericAxisSpec(
              tickProviderSpec: new charts.BasicNumericTickProviderSpec(zeroBound: false)),
          domainAxis: new charts.DateTimeAxisSpec(
              tickFormatterSpec: new charts.AutoDateTimeTickFormatterSpec(
                hour: new charts.TimeFormatterSpec(
                  format: 'mm',
                  transitionFormat: 'HH:mm',
                ),
              )),
          */
          behaviors: [
            new charts.ChartTitle('Pump ON/OFF count',
                subTitle: '',
                behaviorPosition: charts.BehaviorPosition.top,
                titleOutsideJustification: charts.OutsideJustification.middle,
                titleStyleSpec: charts.TextStyleSpec(
                  color: charts.Color.fromHex(code: "#1299e5"),
                  fontWeight: "bold",
                ),
                // Set a larger inner padding than the default (10) to avoid
                // rendering the text too close to the top measure axis tick label.
                // The top tick label may extend upwards into the top margin region
                // if it is located at the top of the draw area.
                innerPadding: 18),
            new charts.ChartTitle('Counts',
                behaviorPosition: charts.BehaviorPosition.bottom,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.ChartTitle('Days',
                behaviorPosition: charts.BehaviorPosition.start,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.SeriesLegend(),
            /*new charts.ChartTitle('End title',
                    behaviorPosition: charts.BehaviorPosition.end,
                    titleOutsideJustification:
                    charts.OutsideJustification.middleDrawArea),*/
          ],
        ),
      ),
    );
  }

  Widget drawWaterLevelGraph() {
    final staticTicks = <charts.TickSpec<String>>[
      new charts.TickSpec(
        // Value must match the domain value.
        'LOW',
      ),
      new charts.TickSpec('MEDIUM'),
      new charts.TickSpec('HIGH'),
    ];

    return Container(
      height: 300,
      width: double.infinity,
      child: Card(
        elevation: 2.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: new charts.TimeSeriesChart(
          widget.waterLevelSeriesList,
          animate: widget.animate,
          // Optionally pass in a [DateTimeFactory] used by the chart. The factory
          // should create the same type of [DateTime] as the data provided. If none
          // specified, the default creates local date time.
          // Set the default renderer to a bar renderer.
          // This can also be one of the custom renderers of the time series chart.
          defaultRenderer: new charts.BarRendererConfig<DateTime>(),
          // It is recommended that default interactions be turned off if using bar
          // renderer, because the line point highlighter is the default for time
          // series chart.
          defaultInteractions: false,
          // If default interactions were removed, optionally add select nearest
          // and the domain highlighter that are typical for bar charts.
          primaryMeasureAxis:
              new charts.NumericAxisSpec(tickProviderSpec: new charts.BasicNumericTickProviderSpec(zeroBound: false)),
          domainAxis: new charts.DateTimeAxisSpec(
              tickFormatterSpec: new charts.AutoDateTimeTickFormatterSpec(
            hour: new charts.TimeFormatterSpec(
              format: 'mm',
              transitionFormat: 'HH:mm',
            ),
          )),
          dateTimeFactory: const charts.LocalDateTimeFactory(),
          behaviors: [
            new charts.ChartTitle('Water Level',
                subTitle: '',
                behaviorPosition: charts.BehaviorPosition.top,
                titleOutsideJustification: charts.OutsideJustification.middle,
                titleStyleSpec: charts.TextStyleSpec(
                  color: charts.Color.fromHex(code: "#1299e5"),
                  fontWeight: "bold",
                ),
                // Set a larger inner padding than the default (10) to avoid
                // rendering the text too close to the top measure axis tick label.
                // The top tick label may extend upwards into the top margin region
                // if it is located at the top of the draw area.
                innerPadding: 18),
            new charts.ChartTitle('Time',
                behaviorPosition: charts.BehaviorPosition.bottom,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.ChartTitle('Water level',
                behaviorPosition: charts.BehaviorPosition.start,
                titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
            new charts.SeriesLegend(),
            /*new charts.ChartTitle('End title',
                    behaviorPosition: charts.BehaviorPosition.end,
                    titleOutsideJustification:
                    charts.OutsideJustification.middleDrawArea),*/
          ],
        ),
      ),
    );
  }

  void bindInletOutletSeriesList() {
//    print("----------------inletoutlet binding" + this.widget.inletData.length.toString() + "------------------");
    this.widget.inletOutletSeriesList = [
      new charts.Series<IntegerDatetimeDataDump, DateTime>(
        id: 'Inlet Flow',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => sales.time,
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.widget.inletData,
      ),
      new charts.Series<IntegerDatetimeDataDump, DateTime>(
        id: 'Outlet Flow',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => sales.time,
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.widget.outletData,
      ),
    ];
  }

  void bindUsageSeriesList() {
//    print("----------------usage binding" + this.widget.usageData.length.toString() + "------------------");
    this.widget.usageSeriesList = [
      new charts.Series<IntegerDatetimeDataDump, DateTime>(
        id: 'Usage',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => sales.time,
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.widget.usageData,
      ),
    ];
  }

  void bindWaterlevelSeriesList() {
//    print("----------------waterlevel binding" + this.widget.waterLevelData.length.toString() + "------------------");
    this.widget.waterLevelSeriesList = [
      new charts.Series<WaterLevelDateTimeDataDump, DateTime>(
        id: 'Water Level',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (WaterLevelDateTimeDataDump sales, _) => sales.time,
        measureFn: (WaterLevelDateTimeDataDump sales, _) => sales.integerLevel,
        data: this.widget.waterLevelData,
      ),
    ];
  }

  void bindPumpOnCountSeriesList() {
//    print("----------------pumponoff binding" + this.widget.pumpOnCountData.length.toString() + "------------------");
    this.widget.pumpOnCountSeriesList = [
      new charts.Series<IntegerDatetimeDataDump, String>(
        id: 'Pump On Count',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (IntegerDatetimeDataDump sales, _) => DateFormat.E().format(sales.time).toString(),
        measureFn: (IntegerDatetimeDataDump sales, _) => sales.flow,
        data: this.widget.pumpOnCountData,
      ),
    ];
  }
}

class TableChart extends StatefulWidget {
  List<WaterUsageTableRecords> waterUsageRecords = [];

  String selectedDropDown = "Water Usage";
  Widget tableWidget;

  @override
  _TableChartState createState() => _TableChartState();
}

class _TableChartState extends State<TableChart> {
  List<String> lstChoice = [
    'Water Usage',
    'Water Level',
    'Pump Status',
    'Flow meter readings',
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 10; i++) {
      this.widget.waterUsageRecords.add(WaterUsageTableRecords(
          tankName: "A-Wing",
          time: DateTime.now().subtract(Duration(days: randomBetween(5, 45))),
          waterUsage: randomBetween(0, 1000)));
    }
    setState(() {
      this.widget.tableWidget = buildUsageTable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(5),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    "Select Data :",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(this.widget.selectedDropDown),
                    items: lstChoice.map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        this.widget.selectedDropDown = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: Container(
            child: this.widget.tableWidget,
          ),
        ),
      ],
    );
  }

  Widget buildUsageTable() {
    TextStyle ts = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    TextStyle toggleStyle1 = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.purpleAccent,
    );
    TextStyle toggleStyle2 = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.deepPurpleAccent,
    );
    TextStyle currentToggleStyle;

    bool colorFlag = true;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 2,
        columns: [
          DataColumn(
              label: Text(
                "Tank Name",
                style: ts,
              ),
              numeric: false,
              onSort: (i, b) {},
              tooltip: "Tank name associated to data"),
          DataColumn(
              label: Text(
                "Date/Time",
                style: ts,
              ),
              numeric: false,
              onSort: (i, b) {},
              tooltip: "Tank name associated to data"),
          DataColumn(
              label: Text(
                "Water Usage",
                style: ts,
              ),
              numeric: true,
              onSort: (i, b) {},
              tooltip: "Tank name associated to data"),
        ],
        rows: this.widget.waterUsageRecords.map((ele) {
          if (colorFlag) {
            currentToggleStyle = toggleStyle1;
            colorFlag = false;
          } else {
            currentToggleStyle = toggleStyle2;
            colorFlag = true;
          }
          return DataRow(cells: [
            DataCell(
              Text(
                ele.tankName,
                style: currentToggleStyle,
              ),
            ),
            DataCell(
              Text(
                DateFormat("MMMM d y\nH:m:s").format(ele.time),
                style: currentToggleStyle,
              ),
            ),
            DataCell(
              Text(
                ele.waterUsage.toString(),
                style: currentToggleStyle,
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

class WaterUsageTableRecords {
  final DateTime time;
  final int waterUsage;
  final String tankName;

  WaterUsageTableRecords({this.time, this.tankName, this.waterUsage});
}

/// Sample time series data type.
class IntegerDatetimeDataDump {
  final DateTime time;
  final int flow;

  IntegerDatetimeDataDump(this.time, this.flow);
}

class WaterLevelDateTimeDataDump {
  final DateTime time;
  final WaterLevel waterLevel;
  int integerLevel;

  WaterLevelDateTimeDataDump(this.time, this.waterLevel) {
    switch (this.waterLevel) {
      case WaterLevel.LOW:
        integerLevel = 30;
        break;
      case WaterLevel.HIGH:
        integerLevel = 90;
        break;
      case WaterLevel.MEDIUM:
        integerLevel = 60;
        break;
      default:
        integerLevel = 10;
    }
  }
}
