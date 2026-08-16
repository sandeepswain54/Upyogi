import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

class ProviderService {
  static const String baseUrl = "https://servicebookingapi.onrender.com/api/Provider";

  static Future<Map<String, dynamic>> saveProfile({
    required String bio,
    required int experienceYears,
    required String serviceCategory,
    required double priceFrom,
    required double priceTo,
    required int serviceRadiusKm,
    required String workingDays,
    required String workingHoursStart,
    required String workingHoursEnd,
    double? latitude,
    double? longitude,
    String? address,
    dynamic profileImage, // XFile
    dynamic kycDocument, // XFile
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      debugPrint("saveProfile -> token present: ${token != null && token.isNotEmpty}, length: ${token?.length}");

      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/profile"));
      request.headers["Authorization"] = "Bearer $token";

      request.fields["Bio"] = bio;
      request.fields["ExperienceYears"] = experienceYears.toString();
      request.fields["ServiceCategory"] = serviceCategory;
      request.fields["PriceFrom"] = priceFrom.toString();
      request.fields["PriceTo"] = priceTo.toString();
      request.fields["ServiceRadiusKm"] = serviceRadiusKm.toString();
      request.fields["WorkingDays"] = workingDays;
      request.fields["WorkingHoursStart"] = workingHoursStart;
      request.fields["WorkingHoursEnd"] = workingHoursEnd;
      if (latitude != null) request.fields["Latitude"] = latitude.toString();
      if (longitude != null) request.fields["Longitude"] = longitude.toString();
      if (address != null) request.fields["Address"] = address;

      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath("profileImage", profileImage.path));
      }
      if (kycDocument != null) {
        request.files.add(await http.MultipartFile.fromPath("kycDocument", kycDocument.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("saveProfile -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        return {"success": false, "sessionExpired": true, "message": "Session expired"};
      } else {
        return {"success": false, "message": "(${response.statusCode}) ${response.body}"};
      }
    } catch (e) {
      debugPrint("saveProfile -> exception: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$baseUrl/profile/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("getMyProfile -> status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        return {"success": false, "sessionExpired": true, "message": "Session expired"};
      } else {
        return {"success": false, "message": "No profile found"};
      }
    } catch (e) {
      debugPrint("getMyProfile -> exception: $e");
      return {"success": false, "message": "Error: $e"};
    }
  }
}
