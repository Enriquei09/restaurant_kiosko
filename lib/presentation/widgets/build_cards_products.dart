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
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          
          Container(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
            alignment: Alignment.centerLeft,
            child: Text(
              textAlign: TextAlign.start,
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 260,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return CardProduct(product: products[index]);
            },
          ),
        ],
      ),
    );
  }
}
