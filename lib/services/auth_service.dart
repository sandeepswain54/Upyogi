import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl => dotenv.env['AUTH_BASE_URL']!;

  static Future<Map<String, dynamic>> register(
      String fullName, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Registered successfully"};
      } else {
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        await prefs.setString("role", data["user"]["role"]);
        await prefs.setString("fullName", data["user"]["fullName"]);
        if (data["user"]["profileImageUrl"] != null) {
          await prefs.setString("profileImageUrl", data["user"]["profileImageUrl"]);
        }
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}