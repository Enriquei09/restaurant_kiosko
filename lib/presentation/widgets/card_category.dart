import 'package:flutter/material.dart';

class CardCategory extends StatelessWidget {
  final String imagePath; // ruta de la imagen
  final String nameCategory; // Nombre categoria
  final String subtitle;
  final VoidCallback? onTap;

  const CardCategory({
    super.key,
    required this.imagePath,
    this.nameCategory = '',
    this.subtitle = "",
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        //color: Colors.amber,
        child: NewCard(imagePath: imagePath, nameCategory: nameCategory),
      ),
    );
  }
}

class NewCard extends StatelessWidget {
  final String imagePath;
  final String nameCategory;

  const NewCard({super.key, required this.imagePath, this.nameCategory = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.white,
      width: 110,
      // margin: EdgeInsets.only(left: 5.0, right: 5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(color: const Color.fromARGB(228, 221, 25, 25), blurRadius: 10, spreadRadius: 2),
        // ],
      ),
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              //Ruta de la Imagen
              child: Image.asset(
                imagePath,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameCategory,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
