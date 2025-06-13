import 'package:flutter/material.dart';

class CardProduct extends StatelessWidget {
  final String nameProduct;
  final double priceProduct;
  final String description;
  final String imagePath;

  const CardProduct({
    super.key,
    this.nameProduct = '',
    this.priceProduct = 0,
    this.description = '',
    this.imagePath = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.only(left: 10.0, right: 10.0),

      child: Container(
        width: 200,
        //
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 253, 252, 252),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: SizedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  imagePath,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text( 
                      nameProduct,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '\$${priceProduct.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),                    
                    ),
                  ],
                ),

              )
            ],
          ),
        ),
      ),
    );
  }
}
