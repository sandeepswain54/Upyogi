import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

class ReviewService {
  static const String baseUrl = "https://servicebookingapi.onrender.com/api/Review";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>> submitReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _headers(),
        body: jsonEncode({
          "bookingId": bookingId,
          "rating": rating,
          "comment": comment,
        }),
      );

      debugPrint("submitReview -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true};
      } else if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        return {"success": false, "sessionExpired": true, "message": "Session expired"};
      }
      return {"success": false, "message": response.body};
    } catch (e) {
      debugPrint("submitReview -> exception: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<List<dynamic>> getServiceReviews(int serviceId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/service/$serviceId"));

      debugPrint("getServiceReviews -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("getServiceReviews -> exception: $e");
      return [];
    }
  }

  static Future<bool> hasReviewed(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/booking/$bookingId"),
        headers: await _headers(),
      );

      debugPrint("hasReviewed -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("hasReviewed -> exception: $e");
      return false;
    }
  }
}
