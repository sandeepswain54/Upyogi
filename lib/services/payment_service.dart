import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

class PaymentService {
  static const String baseUrl = "https://servicebookingapi.onrender.com/api/Payment";

  static Future<Map<String, dynamic>> createPaymentIntent(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse("$baseUrl/create-payment-intent/$bookingId"),
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("createPaymentIntent -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        return {"success": false, "sessionExpired": true, "message": "Session expired"};
      }
      return {"success": false, "message": response.body};
    } catch (e) {
      debugPrint("createPaymentIntent -> exception: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<bool> confirmPayment(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse("$baseUrl/confirm/$bookingId"),
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("confirmPayment -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("confirmPayment -> exception: $e");
      return false;
    }
  }
}
