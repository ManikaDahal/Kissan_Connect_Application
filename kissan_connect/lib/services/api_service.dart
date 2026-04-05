import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissan_connect/core/utils/const.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = '${Constants.apiBaseUrl}/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
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

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final Map<String, dynamic> body = decoded is Map<String, dynamic>
          ? decoded
          : {};
          
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
