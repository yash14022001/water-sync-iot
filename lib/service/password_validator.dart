class PasswordValidator{

  /*String initialPasswordString, confirmPasswordString;

  PasswordValidator(String initialPassword, dynamic confirmPassword){
    this.initialPasswordString = initialPassword;
    this.confirmPasswordString = confirmPassword;
  }


  default PasswordValidator(){

  }*/

  String getPasswordValidationError(bool forPassword, String initialPasswordString, dynamic confirmPasswordString) {
    if(forPassword){
      if(initialPasswordString.isEmpty){
        return "Password cannot be empty";
      }
      if(initialPasswordString.length < 6) {
        return "Password should be of 6 Characters or More";
      }
      return "";
    }
    else {
      if (initialPasswordString != confirmPasswordString) {
        return "Password and Confirm Password do not match";
      }
      return "";
    }
  }

  String getInitialPasswordValidationError( String initialPassword) => getPasswordValidationError(true,initialPassword, null);
  String getConfirmPasswordValidationError( String initialPassword, dynamic confirmPassword) => getPasswordValidationError(false, initialPassword, confirmPassword);
}