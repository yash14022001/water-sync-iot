import 'package:flutter/material.dart';
import 'package:water_sync_iot/screens/sign_in.dart';
import 'package:water_sync_iot/service/authentication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:water_sync_iot/service/password_validator.dart';

class Registor extends StatefulWidget {
  @override
  _RegistorState createState() => _RegistorState();
}

class _RegistorState extends State<Registor> {
  final AuthenticationService _auth = AuthenticationService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  PasswordValidator passwordValidatorObject = PasswordValidator();
  bool _isEmailValid = true, _isPasswordValid = true, _isConfirmPasswordValid = true;

  @override
  Widget build(BuildContext context) {
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
                            "Register here",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              //decorationStyle: ,
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
                            errorText: (_isEmailValid)
                                ? null
                                : "Insert valid email address",
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
                              errorText: (_isPasswordValid)
                                  ? null
                                  : passwordValidatorObject
                                      .getInitialPasswordValidationError(
                                          passwordController.text)),
                        ),
                        const SizedBox(height: 16.0),

                        TextField(
                          controller: confirmPasswordController,
                          textInputAction: TextInputAction.next,
                          obscureText: true,
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
                            hintText: 'Confirm Password',
                            labelStyle: TextStyle(
                              color: Colors.white,
                            ),
                            errorText: (_isConfirmPasswordValid)
                                ? null
                                : "Confirm password do not match with Password",
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
                              child: Text('Sign up'),
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
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SignIn()));
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
      _isPasswordValid = passwordValidatorObject
          .getInitialPasswordValidationError(
          passwordController.text) ==
          ""
          ? true
          : false;
      _isConfirmPasswordValid = passwordValidatorObject.getConfirmPasswordValidationError(passwordController.text, confirmPasswordController.text) == "";
    });

    if(!_isConfirmPasswordValid || !_isPasswordValid || !_isEmailValid){
      return null;
    }
    try {
      var result = await _auth
          .signUpEmailPassword(emailController.text,
          passwordController.text)
          .then((FirebaseUser user) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SignIn()));
      });
    } on AuthException catch(e){
//      print(e);
//      print(e.message);
//      print(e.code);
      return _buildErrorDialog(context, e.message);
    } on Exception catch (e) {
      // gracefully handle anything else that might happen..
      return _buildErrorDialog(context, e.toString());
    }
  }

  Future _buildErrorDialog(BuildContext context, _message) {
//    print("called for dialog messsage!");
    return showDialog(
      builder: (context) {
        return AlertDialog(
          title: Text('Something went wrong!'),
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
