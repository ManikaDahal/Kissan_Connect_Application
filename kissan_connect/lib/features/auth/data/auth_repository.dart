import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/services/api_service.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('users/login/', {
      'email': email,
      'password': password,
    });
    if (response['access'] != null) {
      await ApiService.saveTokens(response['access'], response['refresh']);
    }
    return response;
  }

  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final response = await ApiService.post('users/register/', {
      'full_name': name,
      'email': email,
      'password': password,
    });
    if (response['access'] != null) {
      await ApiService.saveTokens(response['access'], response['refresh']);
    }
    return response;
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await ApiService.post('users/login/google/', {
      'id_token': idToken,
    });
    if (response['access'] != null) {
      await ApiService.saveTokens(response['access'], response['refresh']);
    }
    return response;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await ApiService.post('users/password/forgot/', {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    return await ApiService.post('users/password/verify-otp/', {
      'email': email,
      'otp': otp,
    });
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    return await ApiService.post('users/password/reset/', {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  Future<void> logout() async {
    // Optional: Call backend logout to blacklist token
    await ApiService.clearTokens();
  }
}
