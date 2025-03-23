import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class AlertHelper {
  static void showSuccessAlert(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: message,
      // confirmBtnColor: Theme.of(context).colorScheme.primary,
      // autoCloseDuration: Duration(seconds: 2), // Cierra automáticamente después de 2 segundos
    );
  }

  static void showErrorAlert(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Oops...',
      text: message,
    );
  }

  static void showWarningAlert(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      text: message,
    );
  }

  static void showInfoAlert(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      text: message,
    );
  }

  static void showLoadingAlert(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Cargando',
      text: message,
    );
  }

  static Future<bool> showConfirmAlert(
    BuildContext context,
    String message, {
    String confirmBtnText = 'Sí',
    String cancelBtnText = 'No',
    Color confirmBtnColor = Colors.green,
  }) async {
    bool result = false;
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: message,
      confirmBtnText: confirmBtnText,
      cancelBtnText: cancelBtnText,
      confirmBtnColor: confirmBtnColor,
      onConfirmBtnTap: () {
        result = true;
        Navigator.pop(context);
      },
      onCancelBtnTap: () {
        result = false;
        Navigator.pop(context);
      },
    );
    return result;
  }
}
