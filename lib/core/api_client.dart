import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? transform,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && transform != null
          ? transform(json['data'])
          : json['data'] as T?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}

class ApiClient {
  static String baseUrl = 'http://localhost/textiledrop-api/public/api/v1';
  static bool useMockData = true; // Defaults to high-fidelity in-memory demo engine
  static String? authToken;

  static Map<String, String> get headers {
    final map = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  static Future<ApiResponse<dynamic>> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri, headers: headers);
      final json = jsonDecode(response.body);
      return ApiResponse.fromJson(json, null);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse<dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      final json = jsonDecode(response.body);
      return ApiResponse.fromJson(json, null);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse<dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      final json = jsonDecode(response.body);
      return ApiResponse.fromJson(json, null);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse<dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(uri, headers: headers);
      final json = jsonDecode(response.body);
      return ApiResponse.fromJson(json, null);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}

