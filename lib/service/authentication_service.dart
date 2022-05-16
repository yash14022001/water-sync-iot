import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthenticationService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;

  // SIGN ANON
  Future signInAnon() async {
    try {
      AuthResult result = await _authentication.signInAnonymously();
//      print(result);
      FirebaseUser user = result.user;
      return user;
    } catch (e) {
//      print(e.toString());
      return null;
    }
  }

  // SIGN IN WITH EMAIL/PASSWORD
  Future<FirebaseUser> signInEmailPassword(email, password) async {
    try {
      AuthResult result = await _authentication.signInWithEmailAndPassword(email: email, password: password);
      final FirebaseUser user = result.user;

      assert(user != null);
      assert(await user.getIdToken() != null);

      return user;
    } catch (e) {
//      print("Error from signInEmailPassword");
//      print(e.toString());
      throw new AuthException(e.code, e.message);
    }
  }

  // REGISTERING WITH EMAIL/PASSWORD
  Future<FirebaseUser> signUpEmailPassword(email, password) async {
    try {
      AuthResult result = await _authentication.createUserWithEmailAndPassword(email: email, password: password);
      final FirebaseUser user = result.user;
      assert(user != null);
      assert(await user.getIdToken() != null);

      final databaseReference = FirebaseDatabase.instance.reference();
      databaseReference.child("/users/" + user.uid.toString()).set({
        "email": user.email,
        "password": password,
      });

      return user;
    } catch (e) {
//      print(e.toString());
//      print("Error from signUpEmailPassword");
      throw new AuthException(e.code, e.message);
    }
  }

  // SIGN OUT
  signOut() async {
    await _authentication.signOut();
  }

  //GET EXISTING USER
  Future<FirebaseUser> getLoggedInUser() async {
    return await _authentication.currentUser();
  }
  
  resetPassword(String requestedEmail) async {
    await this._authentication.sendPasswordResetEmail(email: requestedEmail);
  }

}
