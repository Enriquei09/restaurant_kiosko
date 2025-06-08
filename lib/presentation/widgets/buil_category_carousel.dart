//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BuilCategoryCarousel extends StatelessWidget {
  final categorias = ['Platillo tipico', 'Barbacoa', 'Bebida'];

  BuilCategoryCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          //creamos las cards
          return Container(
            alignment: AlignmentDirectional.centerStart,
            margin: const EdgeInsets.only(right: 12),
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 14)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ignore: sized_box_for_whitespace
                Container(
                  height: 140,
                  alignment: Alignment.topCenter,
                  
                  child: Image.asset(
                    "assets/img_comida/comida_mexicana.jpg",
                    height: 140,
                  ),
                  //color: Colors.grey,
                ),
                const SizedBox(),
                Text(
                  categorias[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
