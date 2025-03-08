
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ApiChecker {
  static void checkApi(Response response, {bool getXSnackBar = false}) async {
    if (response.statusCode != 200) {
      switch (response.statusCode) {
        case 400: // Bad Request
          _handleBadRequest(response, getXSnackBar);
          break;
        case 401: // Unauthorized
          _handleUnauthorized(response);
          break;
        case 403: // Forbidden
          _handleForbidden(response, getXSnackBar);
          break;
        case 404: // Not Found
          _handleNotFound(response, getXSnackBar);
          break;
        case 408: // Request Timeout
          _handleTimeout(response, getXSnackBar);
          break;
        case 409: // Conflict
          _handleConflict(response, getXSnackBar);
          break;
        case 422: // Unprocessable Entity (often for validation errors)
          _handleUnprocessableEntity(response, getXSnackBar);
          break;
        case 500: // Internal Server Error
          _handleInternalServerError(response, getXSnackBar);
          break;
        case 502: // Bad Gateway
          _handleBadGateway(response, getXSnackBar);
          break;
        case 503: // Service Unavailable
          _handleServiceUnavailable(response, getXSnackBar);
          break;
        case 504: // Gateway Timeout
          _handleGatewayTimeout(response, getXSnackBar);
          break;
        default: // Handle other error codes generically
          _handleDefaultError(response, getXSnackBar);
          break;
      }
    }
  }

  static void _handleBadRequest(Response response, bool getXSnackBar) {
    _showError('Bad Request', response, getXSnackBar);
  }

  static void _handleUnauthorized(Response response) {
    Get.snackbar("Error", response.body['message'], colorText: Colors.white, backgroundColor: Colors.red);
    // Get.offAllNamed(Routes.LOGIN);
  }

  static void _handleForbidden(Response response, bool getXSnackBar) {
    _showError('Forbidden', response, getXSnackBar);
  }

  static void _handleNotFound(Response response, bool getXSnackBar) {
    _showError('Not Found', response, getXSnackBar);
  }

  static void _handleTimeout(Response response, bool getXSnackBar) {
    _showError('Request Timeout', response, getXSnackBar);
  }

  static void _handleConflict(Response response, bool getXSnackBar) {
    _showError('Conflict', response, getXSnackBar);
  }

  static void _handleUnprocessableEntity(Response response, bool getXSnackBar) {
    String errorMessage = 'Validation Error';
    if (response.body != null) {
      errorMessage = _getErrorMessageFromBody(response.body) ?? errorMessage;
    }
    _showError(errorMessage, response, getXSnackBar);
  }

  static void _handleInternalServerError(Response response, bool getXSnackBar) {
    _showError('Internal Server Error', response, getXSnackBar);
  }

  static void _handleBadGateway(Response response, bool getXSnackBar) {
    _showError('Bad Gateway', response, getXSnackBar);
  }

  static void _handleServiceUnavailable(Response response, bool getXSnackBar) {
    _showError('Service Unavailable', response, getXSnackBar);
  }

  static void _handleGatewayTimeout(Response response, bool getXSnackBar) {
    _showError('Gateway Timeout', response, getXSnackBar);
  }

  static void _handleDefaultError(Response response, bool getXSnackBar) {
    _showError('API Error', response, getXSnackBar);
  }

  static void _showError(String title, Response response, bool? getXSnackBar,
      {String? messages}) {
    // showWarning("Message Passed ======>> ${messages.toString()}");
    String message = 'Something went wrong';
    if (response.bodyString != null) {
      message = response.bodyString!;
    } else if (response.statusText != null) {
      message = response.statusText!;
    }

    if (getXSnackBar!) {
      Get.snackbar(
        title,
        messages ?? message,
        backgroundColor:
            Get.theme.snackBarTheme.backgroundColor ?? Colors.redAccent,
        colorText: Get.theme.snackBarTheme.actionTextColor ?? Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } else {
      print(
          'API Error - $title: Status Code ${response.statusCode}, Message: $message');
    }
  }

  static String? _getErrorMessageFromBody(dynamic body) {
    if (body is Map<String, dynamic> && body.containsKey('message')) {
      return body['message']?.toString();
    }

    return null;
  }
}
