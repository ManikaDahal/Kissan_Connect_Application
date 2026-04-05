import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:kissan_connect/services/api_service.dart';

import 'package:kissan_connect/core/utils/display_snackbar.dart';

class ErrorHelper {
  static String getErrorMessage(dynamic e) {
    if (e is StripeException) {
      if (e.error.code == FailureCode.Canceled) {
        return "Payment was cancelled.";
      } else if (e.error.code == FailureCode.Failed) {
        return "Payment failed. Please check your details and try again.";
      }
      return e.error.localizedMessage ?? "A payment error occurred.";
    } else if (e is ApiException) {
      return e.message;
    } else if (e is SocketException || e.toString().contains('SocketException')) {
      return "No internet connection. Please check your network.";
    } else if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      return "Connection timed out. Please try again later.";
    } else if (e.toString().startsWith("Exception: ")) {
      return e.toString().substring(11); // Remove the "Exception: " prefix
    }
    
    // For raw strings or Unknown errors
    final msg = e.toString();
    if (msg.contains("Connection refused")) {
      return "Server is unreachable right now.";
    }
    
    return msg;
  }

  static void showSnackBarError(BuildContext context, dynamic e, {String? prefix}) {
    final message = getErrorMessage(e);
    final finalMessage = prefix != null ? "$prefix: $message" : message;
    
    DisplaySnackbar.show(
      context, 
      finalMessage, 
      isError: true,
      icon: Icons.error_outline,
    );
  }
}
