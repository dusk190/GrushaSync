import 'package:flutter/material.dart';
import 'package:untitled3333333/screens/MyHomePage.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode myThemeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {

    const myTextTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 24),
      bodyMedium: TextStyle(fontSize: 24),
    );

    return MaterialApp(

        themeMode: myThemeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          textTheme: myTextTheme,
          colorScheme: ColorScheme.light(
              primary: Color(0xff8f8f8f),
              secondary: Color(0xfff4f4f4),
              surface: Color(0xffe6e6e6)
          ),
        ),

        darkTheme: ThemeData(
          brightness: Brightness.dark,
          textTheme: myTextTheme,
          colorScheme: ColorScheme.dark(
            primary: Color(0xff4e4e6a),
            onPrimary: Colors.white,

            //0xff313157
            secondary: Color(0xff383851),
            onSecondary: Colors.white,

            surface: Color(0xff2b2b35),
          ),

        ),

        debugShowCheckedModeBanner: false,
        home: MyHomePage(changeTheme: changeTheme)
        //home: MyFilesPage(),
    );
  }

  void changeTheme() {
    setState(() {
      myThemeMode = myThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }
}

void main() {
  print("hii");
  runApp(MyApp());
}