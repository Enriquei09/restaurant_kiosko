import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/card_product.dart';

class BuildCardsProducts extends StatelessWidget {
  final String category;

  const BuildCardsProducts({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(50.0),
      alignment: Alignment.centerLeft,
      child: Column(
        children: [          
          Container(
            padding: const EdgeInsets.all(20.0),
            alignment: Alignment.centerLeft,
            child: Text(
              textAlign: TextAlign.start,
              category,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CardProduct(
                  imagePath: 'assets/products_img/sopes.jpg',
                  nameProduct: 'Sopes',
                ),
                CardProduct(
                  imagePath: 'assets/products_img/sopes.jpg',
                  nameProduct: 'Sopes',
                ),
                CardProduct(
                  imagePath: 'assets/products_img/sopes.jpg',
                  nameProduct: 'Sopes',
                ),
                CardProduct(
                  imagePath: 'assets/products_img/sopes.jpg',
                  nameProduct: 'Sopes',
                ),
                CardProduct(
                  imagePath: 'assets/products_img/sopes.jpg',
                  nameProduct: 'Sopes',
                ),
              ],
            )
          ),
          
        ],
      ),
    );
  }
}
