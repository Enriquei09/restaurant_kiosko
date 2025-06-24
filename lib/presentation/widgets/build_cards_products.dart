import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product.dart';
import 'package:restaurant_kiosco/presentation/widgets/card_product.dart';

class BuildCardsProducts extends StatelessWidget {
  final String category;
  final List<Product> products;

  const BuildCardsProducts({super.key, required this.category, required this.products});

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
              mainAxisAlignment: MainAxisAlignment.start,
              children: products.map((Product){
                return CardProduct(
                  imagePath: Product.imagePath,
                  nameProduct: Product.name,
                  priceProduct: Product.price,

                );

              }
              ).toList(),
            )
          ),
          
        ],
      ),
    );
  }
}
