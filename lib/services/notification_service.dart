import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

class NotificationService {
  static const String baseUrl = "https://servicebookingapi.onrender.com/api/Notification";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return {"Authorization": "Bearer $token"};
  }

  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: await _headers());

      debugPrint("getNotifications -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) return jsonDecode(response.body);
      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
      }
      return [];
    } catch (e) {
      debugPrint("getNotifications -> exception: $e");
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/unread-count"), headers: await _headers());

      debugPrint("getUnreadCount -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
      }
      return 0;
    } catch (e) {
      debugPrint("getUnreadCount -> exception: $e");
      return 0;
    }
  }

  static Future<void> markAsRead(int id) async {
    try {
      final response = await http.put(Uri.parse("$baseUrl/$id/mark-read"), headers: await _headers());
      debugPrint("markAsRead -> status: ${response.statusCode}, body: ${response.body}");
      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
      }
    } catch (e) {
      debugPrint("markAsRead -> exception: $e");
    }
  }

  static Future<void> markAllRead() async {
    try {
      final response = await http.put(Uri.parse("$baseUrl/mark-all-read"), headers: await _headers());
      debugPrint("markAllRead -> status: ${response.statusCode}, body: ${response.body}");
      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
      }
    } catch (e) {
      debugPrint("markAllRead -> exception: $e");
    }
  }
}
