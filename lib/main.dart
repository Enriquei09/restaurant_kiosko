import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/screens/menu/menu_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'kike',
      home: MenuScreen(),
    );
  }
}
