import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_jj/core/constants/colors.dart';


void showToast(String message, {bool isError = false}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: isError ? AppColors.errorColor : AppColors.successColor,
    textColor: Colors.white,
  );
}