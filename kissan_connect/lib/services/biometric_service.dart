import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device supports biometrics.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Stores a flag so next launch the user can use biometric login.
  static Future<void> enableBiometricLogin(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_phone', phoneNumber);
    await prefs.setBool('biometric_enabled', true);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  static Future<String?> getBiometricPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_phone');
  }

  /// Prompts the user to authenticate using biometrics.
  /// Returns true if authentication succeeds.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access KissanConnect',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/pattern fallback
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
