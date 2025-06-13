//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/card_category.dart';

//Contenedor del carrusel de categorias

class BuilCategoryCarousel extends StatelessWidget {
  final categorias = ['Platillo ', 'tortas', 'tortillas'];

  BuilCategoryCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Align(
        alignment: Alignment.center,
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            //creamos las cards
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                NewCard(
                  imagePath: 'assets/img_comida/comida_mexicana.jpg',
                  nameCategory: categorias[index],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
