import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

class BookingService {
  static const String baseUrl = "https://servicebookingapi.onrender.com/api/Booking";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>> createBooking({
    required int serviceId,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String serviceAddress,
    String? notes,
    required String customerPhone,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _headers(),
        body: jsonEncode({
          "serviceId": serviceId,
          "appointmentDate": appointmentDate.toIso8601String(),
          "appointmentTime": appointmentTime,
          "serviceAddress": serviceAddress,
          "notes": notes,
          "customerPhone": customerPhone,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      debugPrint("createBooking -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        return {"success": false, "sessionExpired": true, "message": "Session expired"};
      } else {
        return {"success": false, "message": "(${response.statusCode}) ${response.body}"};
      }
    } catch (e) {
      debugPrint("createBooking -> exception: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> getCustomerBookings() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/customer"), headers: await _headers());

      debugPrint("getCustomerBookings -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        return {"success": false, "sessionExpired": true, "message": "Session expired"};
      }
      return {"success": false, "message": response.body};
    } catch (e) {
      debugPrint("getCustomerBookings -> exception: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> getProviderBookings() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/provider"), headers: await _headers());

      debugPrint("getProviderBookings -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        return {"success": false, "sessionExpired": true, "message": "Session expired"};
      }
      return {"success": false, "message": response.body};
    } catch (e) {
      debugPrint("getProviderBookings -> exception: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<bool> _updateStatus(int id, String action) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$id/$action"),
        headers: await _headers(),
      );

      debugPrint("$action booking $id -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("$action booking $id -> exception: $e");
      return false;
    }
  }

  static Future<bool> acceptBooking(int id) => _updateStatus(id, "accept");
  static Future<bool> rejectBooking(int id) => _updateStatus(id, "reject");
  static Future<bool> completeBooking(int id) => _updateStatus(id, "complete");
  static Future<bool> cancelBooking(int id) => _updateStatus(id, "cancel");
}
