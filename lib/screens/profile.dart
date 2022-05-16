import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:water_sync_iot/widgets/app_bar.dart';
import '../service/authentication_service.dart';

class Profile extends StatefulWidget {
  TextEditingController _email = new TextEditingController();
  TextEditingController _password = new TextEditingController();
  TextEditingController _confirmPassword = new TextEditingController();
  TextEditingController _newPassword = new TextEditingController();
  AuthenticationService _auth;
  FirebaseUser _user;

  Profile() {
    _auth = AuthenticationService();
    this.initAsynchronousFields();
  }

  Future<void> initAsynchronousFields() async {
    _user = await _auth.getLoggedInUser();
    _email.text = _user.email;
  }

  @override
  _ProfileState createState() => _ProfileState();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => null;
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Profile",
      ),
      body: SingleChildScrollView(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            TextField(
              controller: this.widget._email,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.group),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                hintText: this.widget._email.text,
                labelStyle: TextStyle(
                  color: Colors.white,
                ),
                /*errorText: _isEmailValid
                    ? null
                    : "Enter a valid email address",*/
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: this.widget._password,
              textInputAction: TextInputAction.next,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.verified_user),
                fillColor: Colors.white,
                filled: true,
                hintText: 'Old Password',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                labelStyle: TextStyle(
                  color: Colors.white,
                ),
                /*errorText: _isPasswordValid
                    ? null
                    : "Password cannot be empty",*/
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: this.widget._newPassword,
              textInputAction: TextInputAction.next,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.verified_user),
                fillColor: Colors.white,
                filled: true,
                hintText: 'New Password',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                labelStyle: TextStyle(
                  color: Colors.white,
                ),
                /*errorText: _isPasswordValid
                    ? null
                    : "Password cannot be empty",*/
              ),
            ),
            SizedBox(
              height: 16,
            ),
            TextField(
              controller: this.widget._confirmPassword,
              textInputAction: TextInputAction.next,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.verified_user),
                fillColor: Colors.white,
                filled: true,
                hintText: 'Confirm Password',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                labelStyle: TextStyle(
                  color: Colors.white,
                ),
                /*errorText: _isPasswordValid
                        ? null
                        : "Password cannot be empty",*/
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(5.0),
                    ),
                    color: Theme.of(context).accentColor,
                    onPressed: () {
                      this._changePassword();
                    },
                    textColor: Colors.white,
                    padding: const EdgeInsets.all(0.0),
                    child: Text('Update Information'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() async{
    //Create an instance of the current user.
    AuthCredential authCredential = EmailAuthProvider.getCredential(
      email: this.widget._email.text,
      password: this.widget._password.text,
    );
//    print("Auth Credential: ${authCredential.toString()}");
    await this.widget._user.reauthenticateWithCredential(authCredential).then((result) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Reauthentiation successfull...",style: TextStyle(fontWeight: FontWeight.bold),),
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      ));

      if(this.widget._newPassword.text.length < 6){
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Password should be atleast 6 characters long",style: TextStyle(fontWeight: FontWeight.bold),),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        ));
        return;
      }
      else if(this.widget._newPassword.text != this.widget._confirmPassword.text){
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("New password and confirm password should be same",style: TextStyle(fontWeight: FontWeight.bold),),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        ));
        return;
      }

      //Pass in the password to updatePassword.
      this.widget._user.updatePassword(this.widget._newPassword.text).then((_){
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Password update successfull...",style: TextStyle(fontWeight: FontWeight.bold),),
          duration: Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        ));
      }).catchError((error){
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Password update unsuccessfull...Some error occured..try again",style: TextStyle(fontWeight: FontWeight.bold),),
          duration: Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        ));
        //This might happen, when the wrong password is in, the user isn't found, or if the user hasn't logged in recently.
      });

    }).catchError((error) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Reauthentication unsuccessfull...try again",style: TextStyle(fontWeight: FontWeight.bold),),
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      ));
      return;
    });
  }
}
