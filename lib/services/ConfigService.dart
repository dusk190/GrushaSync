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

}