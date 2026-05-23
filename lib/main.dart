// Найти build gradle и прописать ьам
// перед sdk 31
// namespace 'com.haberey.flutter.nsd_android'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/dualModeService.dart';
import '../screens/MyHomePage.dart';
import 'dart:io';
import '../services/ConfigService.dart';
import 'package:window_manager/window_manager.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.init();
  if (Platform.isWindows){
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(550, 600));
    await windowManager.setSize(const Size(900, 700));
  }
  runApp(
    // Че этот провайдер делает, вопрос к беку. Важное
    ChangeNotifierProvider(
      create: (_) => DualModeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  // Смотрим на то, светлая или темная тема по умолчанию выбрана в ОС устройства
  ThemeMode myThemeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    // Если юзер менял тему, смотрим в конфиг
    if (ConfigService.isDarkMode != null) {
      myThemeMode = ConfigService.isDarkMode! ? ThemeMode.dark : ThemeMode.light;;
    }

    // Темы для текстов
    const myTextTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 24),
      bodyMedium: TextStyle(fontSize: 24),
      bodySmall: TextStyle(fontSize: 16),
    );

    return MaterialApp(
        themeMode: myThemeMode,
        // Светлая тема
        theme: ThemeData(
          brightness: Brightness.light,
          textTheme: myTextTheme,
          colorScheme: ColorScheme.light(
              primary: Color(0xff8f8f8f),
              secondary: Color(0xfff4f4f4),
              onSecondary: Color(0xff171717),
              surface: Color(0xffe6e6e6)
          ),
        ),

        // Темная тема
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          textTheme: myTextTheme,
          colorScheme: ColorScheme.dark(
            primary: Color(0xff5b5b5e),
            onPrimary: Colors.white,

            //0xff313157
            secondary: Color(0xff39393a),
            onSecondary: Colors.white,

            surface: Color(0xff2d2d2e),
          ),

        ),

        debugShowCheckedModeBanner: false,
        // Экран главного меню MyHomePage
        home: MyHomePage(changeTheme: changeTheme)
    );
  }

  // Функция переключения темы, которую мы передаем в экран главного меню
  void changeTheme() {
    setState(() {
      if (myThemeMode == ThemeMode.dark) {
        myThemeMode = ThemeMode.light;
        ConfigService.isDarkMode = false;
      }
      else {
        myThemeMode = ThemeMode.dark;
        ConfigService.isDarkMode = true;
      }
      //myThemeMode = myThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }
}
