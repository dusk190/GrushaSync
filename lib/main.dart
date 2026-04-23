// Найти build gradle и прописать ьам
// перед sdk 31
// namespace 'com.haberey.flutter.nsd_android'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/dualModeService.dart';
import 'screens/mainScreen.dart';
import 'package:flutter/semantics.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DualModeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrushaSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
// Backend
// import 'package:flutter/material.dart';
// import 'screens/serverScreen.dart';
// import 'screens/clientScreen.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Локальный обмен сообщениями',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: MainScreen(),
//     );
//   }
// }
//
// class MainScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Локальный обмен сообщениями'),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Выберите режим работы',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 40),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ServerScreen()),
//                 );
//               },
//               icon: Icon(Icons.wifi),
//               label: Text('Запустить сервер (приём сообщений)'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ClientScreen()),
//                 );
//               },
//               icon: Icon(Icons.phone_android),
//               label: Text('Подключиться как клиент (отправка)'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             SizedBox(height: 40),
//             Text(
//               '⚠️ Оба устройства должны быть в одной Wi-Fi сети',
//               style: TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Frontend old version
// import 'package:flutter/material.dart';
// import 'package:untitled3333333/screens/MyHomePage.dart';
//
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//   @override
//   createState() => MyAppState();
// }
//
// class MyAppState extends State<MyApp> {
//   ThemeMode myThemeMode = ThemeMode.system;
//   @override
//   Widget build(BuildContext context) {
//
//     const myTextTheme = TextTheme(
//       displayLarge: TextStyle(fontSize: 24),
//       bodyMedium: TextStyle(fontSize: 24),
//     );
//
//     return MaterialApp(
//
//         themeMode: myThemeMode,
//         theme: ThemeData(
//           brightness: Brightness.light,
//           textTheme: myTextTheme,
//           colorScheme: ColorScheme.light(
//               primary: Color(0xff8e8e8e),
//               secondary: Color(0xffffffff),
//               surface: Color(0xffe6e6e6)
//           ),
//         ),
//
//         darkTheme: ThemeData(
//           brightness: Brightness.dark,
//           textTheme: myTextTheme,
//           colorScheme: ColorScheme.dark(
//             primary: Color(0xff4e4e6a),
//             onPrimary: Colors.white,
//
//             //0xff313157
//             secondary: Color(0xff383851),
//             onSecondary: Colors.white,
//
//             surface: Color(0xff2b2b35),
//           ),
//
//         ),
//
//         debugShowCheckedModeBanner: false,
//         home: MyHomePage(changeTheme: changeTheme)
//       //home: MyFilesPage(),
//     );
//   }
//
//   void changeTheme() {
//     setState(() {
//       myThemeMode = myThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
//     });
//   }
// }
//
// void main() {
//   print("hii");
//   runApp(MyApp());
// }