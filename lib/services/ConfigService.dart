import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static set isDarkMode(bool value) => _prefs.setBool('isDarkMode', value);
  static bool? get isDarkMode => _prefs.getBool('isDarkMode');

  static String? get netPass => _prefs.getString('network_password');
  static Future<bool> setNetPass(String value) async => await _prefs.setString('network_password', value);
  static Future<bool> removePass() async => await _prefs.remove('network_password');

  static String? get customDeviceName => _prefs.getString('custom_device_name');
  static Future<bool> setCustomDeviceName(String value) async => await _prefs.setString('custom_device_name', value);
  static Future<bool> removeCustomDeviceName() async => await _prefs.remove('custom_device_name');
}
