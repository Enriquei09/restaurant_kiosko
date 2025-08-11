// produc_description.dart
import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product.dart';
import 'package:restaurant_kiosco/presentation/widgets/larger_button.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart'; // ExtraSelector

class ProductDescription extends StatelessWidget {
  const ProductDescription({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        child: Container(
          width: 600,
          height: 500,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 155, 128, 32),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const IconsViewCard(),
              Expanded(
                child: Row(
                  children: [
                    ImageContainer(imagePath: product.imagePath),
                    InfoProductContainer(product: product),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconsViewCard extends StatelessWidget {
  const IconsViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 750,
      height: 50,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageContainer extends StatelessWidget {
  const ImageContainer({super.key, required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Colors.white),
      alignment: Alignment.topCenter,
      child: isNetwork
          ? Image.network(imagePath, width: 280, fit: BoxFit.cover)
          : Image.asset(imagePath, width: 280, fit: BoxFit.cover),
    );
  }
}

class InfoProductContainer extends StatelessWidget {
  const InfoProductContainer({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            (product.description.isEmpty ? 'Description' : product.description),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
          const Divider(height: 32),
          SizedBox(
            height: 250,
            child: SingleChildScrollView(
              child: ExtraSelector(
                key: ValueKey(product.id), // fuerza rebuild entre productos
                productId: product.id,     // 🔑 para traer modificadores 
              ),
            ),
          ),
          const Divider(height: 32),
          const LargeButton(),
        ],
      ),
    );
  }
}
