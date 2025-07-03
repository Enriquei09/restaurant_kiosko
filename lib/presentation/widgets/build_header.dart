import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/button_icon.dart';

class BuildHeader extends StatelessWidget {
  const BuildHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 30.0),
      decoration: BoxDecoration(
        color:  Colors.white,
        border: Border(bottom: BorderSide(color: const Color.fromARGB(157, 0, 0, 0), width: 2.0)),
        boxShadow:[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset('assets/img_comida/img_log.png', height: 60),
            const Spacer(),
            Image.asset('assets/img_comida/Img_logo2.png', height: 80),
            const Spacer(),
            // ElevatedButton(
            //   onPressed: () {},
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.purple,
            //     foregroundColor: Colors.white,
            //   ),
            //   child: const Text('Orden'),
            // ),
            ButtonIcon(),
            const SizedBox(width: 12),
            const Icon(Icons.person_3_outlined),
          ],
        ),
      ),
    );
  }
}
