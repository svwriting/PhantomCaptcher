import 'package:flutter/cupertino.dart';
import 'dart:io';

class SignUpModel {
  String user_id;
  String user_password;
  String repeatPassword;
  File user_pic;

  SignUpModel(
    {
      this.user_id,
      this.user_password,
      this.repeatPassword,
      this.user_pic
    }
  );
}
