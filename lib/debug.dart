class DebugLog {
  final bool DEBUG;

  DebugLog({this.DEBUG});

  void PRINT({String msg, String tag}){
    if(DEBUG){
      print(tag+" \t\t: "+msg);
    }
  }
}