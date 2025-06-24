import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/screens/menu/menu_screen.dart';
// import 'package:restaurant_kiosco/presentation/screens/menu/new_menu.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kiosko',
      home: MenuScreen(),
      // home: NewMenu(),
    );
  }
}
