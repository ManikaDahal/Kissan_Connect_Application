import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissan_connect/core/utils/const.dart';
import 'package:kissan_connect/services/notification_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = '${Constants.apiBaseUrl}/api';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = Constants.apiBaseUrl;
    if (path.startsWith('/')) {
      return '$base$path';
    }
    return '$base/$path';
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    // Register this device's FCM push token with the backend
    NotificationService.sendTokenToServer();
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } catch (e) {
      if (e is TimeoutException) {
        throw ApiException("The server is taking too long to respond. It might be waking up, please try again in a few seconds.");
      }
      if (e is http.ClientException) {
        throw ApiException("Cannot connect to server. Please check your network or if the server is running.");
      }
      rethrow;
    }
  }

  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: (params != null && params.isNotEmpty) ? params : null,
    );
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } catch (e) {
      if (e is TimeoutException) {
        throw ApiException("The server is taking too long to respond. It might be waking up, please try again in a few seconds.");
      }
      if (e is http.ClientException) {
        throw ApiException("Cannot connect to server. Please check your network or if the server is running.");
      }
      rethrow;
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final token = await _getToken();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } catch (e) {
      if (e is TimeoutException) {
        throw ApiException("The server is taking too long to respond. It might be waking up, please try again in a few seconds.");
      }
      if (e is http.ClientException) {
        throw ApiException("Cannot connect to server.");
      }
      rethrow;
    }
  }

  static Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } catch (e) {
      if (e is TimeoutException) {
        throw ApiException("The server is taking too long to respond. It might be waking up, please try again in a few seconds.");
      }
      if (e is http.ClientException) {
        throw ApiException("Cannot connect to server.");
      }
      rethrow;
    }
  }

  static Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields,
    Map<String, String> files,
  ) async {
    final token = await _getToken();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$endpoint'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      for (var entry in files.entries) {
        if (entry.value.isNotEmpty) {
          final isImage = entry.value.toLowerCase().endsWith('.jpg') || 
                          entry.value.toLowerCase().endsWith('.jpeg') || 
                          entry.value.toLowerCase().endsWith('.png');
          
          MediaType? contentType;
          if (isImage) {
            contentType = MediaType('image', entry.value.toLowerCase().endsWith('.png') ? 'png' : 'jpeg');
          }

          request.files.add(await http.MultipartFile.fromPath(
            entry.key, 
            entry.value,
            contentType: contentType,
          ));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      if (e is TimeoutException) {
        throw ApiException("Request timed out. Please try again.");
      }
      rethrow;
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body; 
      }
    } else {
      Map<String, dynamic> body = {};
      try {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        body = decoded is Map<String, dynamic> ? decoded : {};
      } catch (e) {
        // Not a JSON response (likely HTML error page)
        if (response.statusCode == 500) {
          throw ApiException("Server Error (500). Please check backend logs.");
        } else if (response.statusCode == 404) {
          throw ApiException("Endpoint not found (404).");
        }
        throw ApiException("Server returned an unexpected response (${response.statusCode}).");
      }
          
      String errorMessage = body['error'] ?? body['detail'] ?? 'An error occurred';
      
      if (body['error'] == null && body['detail'] == null && body.isNotEmpty) {
        final firstKey = body.keys.first;
        final firstError = body[firstKey];
        final cleanKey = firstKey[0].toUpperCase() + firstKey.substring(1).replaceAll('_', ' ');
        if (firstError is List && firstError.isNotEmpty) {
           errorMessage = '$cleanKey: ${firstError.first}';
        } else {
           errorMessage = '$cleanKey: $firstError';
        }
      }
      throw ApiException(errorMessage);
    }
  }
}
