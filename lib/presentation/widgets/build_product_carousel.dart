import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../widgets/build_cards_products.dart';

class BuildProductCarousel extends StatelessWidget {
  final Category category;

  const BuildProductCarousel({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos de ${category.name}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: category.productGroups.isEmpty
          ? const Center(child: Text('No hay productos en esta categoría'))
          : ListView.builder(
              itemCount: category.productGroups.length,
              itemBuilder: (context, index) {
                final group = category.productGroups[index];

                return BuildCardsProducts(
                  category: group.name,
                  products: group.products,
                );
              },
            ),
    );
  }
}
