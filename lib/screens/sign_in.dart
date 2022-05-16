import 'package:water_sync_iot/mqtt/mqttView.dart';
import 'package:water_sync_iot/screens/register.dart';
import 'package:water_sync_iot/service/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:water_sync_iot/temp/home.dart';
import 'package:email_validator/email_validator.dart';
import 'package:water_sync_iot/service/password_validator.dart';
import 'package:water_sync_iot/temp/pre_home.dart';
import 'package:water_sync_iot/screens/reset_password.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthenticationService _auth = AuthenticationService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isEmailValid = true, _isPasswordValid = true;
  PasswordValidator passwordValidatorObject = PasswordValidator();

  @override
  Widget build(BuildContext context) {
//    print("Building Widget");
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: new DecorationImage(
            fit: BoxFit.cover,
            image: ExactAssetImage(
              "assets/images/splash-full-sml.jpg",
            ),
          ),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Sign in",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: emailController,
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
                            hintText: 'Email',
                            labelStyle: TextStyle(
                              color: Colors.white,
                            ),
                            errorText: _isEmailValid
                                ? null
                                : "Enter a valid email address",
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: passwordController,
                          textInputAction: TextInputAction.done,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.verified_user),
                            fillColor: Colors.white,
                            filled: true,
                            hintText: 'Password',
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
                            errorText: _isPasswordValid
                                ? null
                                : "Password cannot be empty",
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 40,
                            width: 100,
                            child: RaisedButton(
                              color: Colors.blue,
                              onPressed: _submitForm,
                              textColor: Colors.white,
                              padding: const EdgeInsets.all(0.0),
                              child: Text('Login'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 40,
                            width: 100,
                            child: InkWell(
                              child: Text(
                                "Sign up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => Registor()));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 40,
                            width: 100,
                            child: InkWell(
                              child: Text(
                                "Forgot password",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => ResetPassword()));
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const Spacer(),
                  //const Spacer(),
                ],
              ),
            ),
            /*Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Container(
                  alignment: Alignment.bottomCenter,
                  child: FutureBuilder<bool>(
                    future: _auth.isActive(),
                    builder: (_, snapshot) {
                      if (snapshot.hasData && snapshot.data) {
                        return IconButton(
                          icon: Icon(
                            Icons.fingerprint,
                            color: Colors.white,
                          ),
                          iconSize: 80,
                          onPressed: _touchIdAuth,
                        );
                      }
                      return Container();
                    },
                  ),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  _submitForm() async {
    setState(() {
      _isEmailValid = EmailValidator.validate(
          emailController.text);
      _isPasswordValid = passwordController.text.isNotEmpty;
    });
    if (!_isEmailValid || !_isPasswordValid) {
      return null;
    }

    try {
      var result = await _auth
          .signInEmailPassword(emailController.text, passwordController.text)
          .then((FirebaseUser user) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => PreHome()));
      });
    } on AuthException catch (error) {
//      print(error);
//      print("MESSAGE : " + error.message);
//      print("CODE : " +  error.code);
      return _buildErrorDialog(context, error.message);
    } on Exception catch (error) {
      // gracefully handle anything else that might happen..
      return _buildErrorDialog(context, error.toString());
    }
  }

  Future _buildErrorDialog(BuildContext context, _message) {
    return showDialog(
      builder: (context) {
        return AlertDialog(
          title: Text('Somthing went wrong!'),
          content: Text(_message),
          actions: <Widget>[
            FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                })
          ],
        );
      },
      context: context,
    );
  }

}
