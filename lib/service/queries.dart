import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class Queries {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String userID;

  Queries({@required this.userID});


}