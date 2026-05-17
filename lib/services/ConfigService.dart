import 'package:shared_preferences/shared_preferences.dart';

// тут потом можно сохранять идентификатор сети, заданный пользователем
// чет типа static set net_id(String value) => _prefs.setString('net_id', value);
class ConfigService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static set isDarkMode(bool value) => _prefs.setBool('isDarkMode', value);
  static bool? get isDarkMode => _prefs.getBool('isDarkMode');
  //static Future<bool> setDarkMode(bool value) async => await _prefs.setBool('isDarkMode', value);

  static String? get netPass => _prefs.getString('network_password');
  static Future<bool> setNetPass(String value) async => await _prefs.setString('network_password', value);
  static Future<bool> removePass() async => await _prefs.remove('network_password');
}