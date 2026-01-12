import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:restaurant_kiosco/presentation/screens/menu/menu_screen.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart'; // <-- asegúrate de tener este archivo
import 'package:restaurant_kiosco/presentation/screens/checkout/checkout_screen.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Restaura el carrito guardado al iniciar
        ChangeNotifierProvider(create: (_) => CartModel()..restore()),
        ChangeNotifierProvider(create: (_) => PaymentModel()),
        ChangeNotifierProvider(create: (_) => TipModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kiosko',
      home: 
        const CheckoutScreen(),
        //const MenuScreen(),
    );
  }
}
