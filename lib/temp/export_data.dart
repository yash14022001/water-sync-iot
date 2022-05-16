import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_sync_iot/screens/sign_in.dart';
import 'package:water_sync_iot/service/authentication_service.dart';
import 'package:water_sync_iot/widgets/app_bar.dart';
import 'package:water_sync_iot/widgets/notifications_icon.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:directory_picker/directory_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


class ExportDataForm extends StatefulWidget {
  @override
  _ExportDataFormState createState() => _ExportDataFormState();
}

class _ExportDataFormState extends State<ExportDataForm> {
  final GlobalKey<ScaffoldState> _homeScaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  Directory selectedDirectory;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  DateTime startDate=new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), endDate=DateTime.now();
  FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseUser _user;
  AuthenticationService _authService;
  List<TankDataForPDF> tankDataDump = new List<TankDataForPDF>();
  List<String> tankNames = [], tankMACid=[];
  String selectedTankItem, selectedTankMacID;
  int selectedTankItemIndex;

  void initState(){
    _authService = AuthenticationService();
    this._database = FirebaseDatabase.instance;
    initAsynchronousFields();
  }

  initAsynchronousFields() async {
    this._user = await this._authService.getLoggedInUser();
    int c=0;
    await this._database.reference().child("/users/"+this._user.uid+"/hardware/mac_id/").onChildAdded.listen((event) {
      setState(() {
        tankMACid.add(event.snapshot.key);
        tankNames.add(event.snapshot.value["associated_tank_name"].toString());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar:AppBar(
        title: Text("Water Sync"),
        leading: NotificationBadge(
          scaffoldKey: _homeScaffoldKey,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              //Navigator.push(context, new MaterialPageRoute(builder: (context) => SettingsPanel()));
              //TODO : Settings Panel
//              addNewDataValueInFirebase();
            },
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              //TODO : Logout
              Navigator.push(context, new MaterialPageRoute(builder: (context) => SignIn()));
            },
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(5),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: Text(
                        "Pick location to save pdf file..."
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: RaisedButton(
                    color: Theme.of(context).accentColor,
                    padding: EdgeInsets.all(2),
                    child:  Text("Browse"),
                    textColor: Colors.white,
                    onPressed: ()=>_pickDirectory(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(5),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: Text(
                        "Picked Location : "
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: Text(
                      (this.selectedDirectory==null)?"None":this.selectedDirectory.path,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: Text(
                        "Select Tank : "
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: (this.selectedTankItem == null) ? Text("Not Selected"): Text(this.selectedTankItem),
                    items: this.tankNames.map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        this.selectedTankItem = val;
                        this.selectedTankItemIndex = this.tankNames.indexOf(val);
                        this.selectedTankMacID=tankMACid[this.selectedTankItemIndex];
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: Text(
                        "Start Date : "
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: RaisedButton(
                      onPressed: ()=>_selectStartDate(context),
                      color: Theme.of(context).accentColor,
                      child: Text(
                          DateFormat.yMMMd().format(startDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: Text(
                        "End Date : "
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    child: RaisedButton(
                      onPressed: ()=>_selectEndDate(context),
                      color: Theme.of(context).accentColor,
                      child: Text(
                        DateFormat.yMMMd().format(endDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            RaisedButton(
              color: Theme.of(context).accentColor,
              child:Text("Export"),
              textColor: Colors.white,
              onPressed: (){
                _doExport(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDirectory(BuildContext context) async {
    Directory directory = selectedDirectory;
    if (directory == null) {
      directory = await getExternalStorageDirectory();
    }

    Directory newDirectory = await DirectoryPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    setState(() {
      selectedDirectory = newDirectory;
    });
  }

  Future<void> _doExport(BuildContext context) async {
    try {
//      Dialogs.showLoadingDialog(context, _keyLoader);//invoking login
      // check for nulls
      if(this.selectedDirectory == null){
        throw Exception("");
      }

      await this._getDataFromFirbase();
      print("getDataFromFIrebase performed");

      if(tankDataDump.length>1){
        tankDataDump.sort((a,b) {
          return a.dateTime.compareTo(b.dateTime);
        });
        double usage=0.0,loss=0.0;
        for(int i=0;i<tankDataDump.length;i++){
          usage+=tankDataDump[i].intletFlow;
          if(tankDataDump[i].intletFlow > tankDataDump[i].outletFlow) loss += tankDataDump[i].intletFlow-tankDataDump[i].outletFlow;
          tankDataDump[i].usage = usage;
          tankDataDump[i].loss = loss;
        }
      }
      print("Arranging data done");
      if(tankDataDump.length == 0) throw Exception("");

        this.makePDF();
        print("PDF making is done");
        this.tankDataDump.clear();

//        Future.delayed(const Duration(milliseconds: 500), () {
//          Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop();//close the dialoge
//        });
    }
    catch (errorEx) {
      print(errorEx);
      String error;
      if(this.selectedTankItem == null) error = "Please select tank from dropdown";
      else if(this.tankDataDump == null) error = "There is no data from this time range";
      else if(this.selectedDirectory == null) error = "Choose path for saving pdf...";
      else if(this.tankDataDump.length == 0) error = "There is no data to be shown...";
      else error="Some error occured....try again later";

      final snackBar = SnackBar(content: Text(error));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  makePDF(){
    //Create a new PDF document
    PdfDocument document = PdfDocument();

    var introDateFormatter = new DateFormat("yyyy-MMM-dd");
    String intro = "";
    intro += "Exported on :"+introDateFormatter.format(DateTime.now())+"\n";
    intro += "Data is from :"+introDateFormatter.format(startDate)+" to "+introDateFormatter.format(endDate)+"\n";
    intro += "Data is for :"+tankNames[selectedTankItemIndex]+"\n";

    document.pages.add().graphics.drawString(
        intro, PdfStandardFont(PdfFontFamily.helvetica, 16),
        brush: PdfBrushes.black, bounds: Rect.fromLTWH(2, 10, 400, 100));
    //Create a PdfGrid class
    PdfGrid grid = PdfGrid();

    //Add the columns to the grid
    grid.columns.add(count: 5);
    //Add header to the grid
    grid.headers.add(1);

    //Add the rows to the grid
    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Time';
    header.cells[1].value = 'Inlet FLow';
    header.cells[2].value = 'Outlet Flow';
    header.cells[3].value = 'Usage';
    header.cells[4].value = 'Loss';

    PdfGridRow row;
    var formatter = new DateFormat('yyyy-MMM-dd H:m:s');
    for(int i=0;i<tankDataDump.length;i++){
//      print("my_string :"+tankDataDump[i].dateTime.toString());
      String formatted = formatter.format(tankDataDump[i].dateTime);
//      print("Adding "+i.toString());
      row = grid.rows.add();
//      print(formatted);
      row.cells[0].value = formatted;
      row.cells[1].value = tankDataDump[i].intletFlow.toStringAsFixed(3);
      row.cells[2].value = tankDataDump[i].outletFlow.toStringAsFixed(3);
      row.cells[3].value = tankDataDump[i].usage.toStringAsFixed(3);
      row.cells[4].value = tankDataDump[i].loss.toStringAsFixed(3);
//      print("Added "+i.toString());
    }

    //Set the grid style
    grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 2, right: 2, top: 2, bottom: 2),
        backgroundBrush: PdfBrushes.whiteSmoke,
        textBrush: PdfBrushes.black,
        font: PdfStandardFont(PdfFontFamily.timesRoman, 16));

    //Draw the grid
    grid.draw(
        page: document.pages.add(), bounds: const Rect.fromLTWH(0, 0, 500, 0),);


    //Save and dispose the PDF document
    print("new path ="+selectedDirectory.path.toString()+"/SampleOutput.pdf");
    File f = new File(selectedDirectory.path.toString()+"/SampleOutput.pdf");
    f.writeAsBytes(document.save(), flush: true);
//    File('$selectedDirectory/SampleOutput.pdf').writeAsBytes(document.save());
    document.dispose();
    final snackBar = SnackBar(content: Text("PDF created"));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future<Null> _selectStartDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: startDate,
        firstDate: DateTime(2018, 8),
        lastDate: DateTime.now(),
    );

      setState(() {
        startDate = picked;
        print("New start Dtae picked "+startDate.toString());
      });
  }

  Future<Null> _selectEndDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now(),
    );
      setState(() {
        endDate = picked;
        print("New enddate is picked "+endDate.toString());
      });
  }

  Future<Null> _getDataFromFirbase() async {
//    print("Current date :"+(DateTime.now().millisecondsSinceEpoch~/1000).toString());

    print("Created Query for "+this.tankMACid[this.selectedTankItemIndex]);
    Query q = await this._database
        .reference()
        .child("/users/" + this._user.uid + "/hardware/data_values/"+ tankMACid[this.selectedTankItemIndex]+"/")
        .orderByKey()
        .startAt((startDate.millisecondsSinceEpoch~/1000).toString());

    DataSnapshot ds = await q.once();
    Map values = ds.value;
    print("Map length :"+values.length.toString());

    double usage=0.0,inlet,outlet,loss=0.0;

    values.forEach((key, value) {
//      print(key.toString()+" --> "+value.toString());
      if(DateTime.fromMillisecondsSinceEpoch(int.parse(key.toString())*1000).isBefore(endDate.add(Duration(days: 1)))) {
        inlet = double.parse(value["inlet_flow"].toString()) / 1000;
        outlet = double.parse(value["outlet_flow"].toString()) / 1000;
        usage += outlet;
        if (inlet > outlet) {
          loss += inlet - outlet;
        }
        TankDataForPDF obj = new TankDataForPDF(key: key.toString(),
            usage: usage,
            inlet: inlet,
            outlet: outlet,
            loss: loss);
        this.tankDataDump.add(obj);
//      print("value added for "+DateFormat.yMMMd(DateTime.fromMillisecondsSinceEpoch(int.parse(key))).toString());
      }
    });
    
  }
}

class TankDataForPDF {
  double intletFlow,outletFlow,usage,loss;
  DateTime dateTime;
  
  TankDataForPDF({@required String key, @required double inlet, @required double outlet, @required double loss, @required usage}) {
    this.intletFlow = inlet;
    this.outletFlow = outlet;
    this.dateTime = new DateTime.fromMillisecondsSinceEpoch(int.parse(key.toString())*1000);
    this.usage = usage;
    this.loss = loss;
  }
}

class Dialogs {
  static Future<void> showLoadingDialog(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(
                  key: key,
                  backgroundColor: Colors.black54,
                  children: <Widget>[
                    Center(
                      child: Column(children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10,),
                        Text("Please Wait....writing and saving pdf...",style: TextStyle(color: Colors.blueAccent),)
                      ]),
                    )
                  ]));
        });
  }
}
