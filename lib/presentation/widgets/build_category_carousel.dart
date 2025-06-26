import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import '../../models/category.dart';
import '../widgets/card_category.dart';

class BuildCategoryCarousel extends StatefulWidget {
  final void Function(int categoryId) onCategoryTap;

  const BuildCategoryCarousel({super.key, required this.onCategoryTap});

  @override
  State<BuildCategoryCarousel> createState() => _BuildCategoryCarouselState();
}


class _BuildCategoryCarouselState extends State<BuildCategoryCarousel> {
  late Future<List<Category>> futureCategories;

  @override
  void initState() {
    super.initState();
    futureCategories = ApiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Align(
        alignment: Alignment.center,
        child: FutureBuilder<List<Category>>(
          future: futureCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No categories found'));
            }

            final categorias = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CardCategory(
                      imagePath: categoria.imagePath ,
                      nameCategory: categoria.name,
                      onTap: () => widget.onCategoryTap(categoria.id),

                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
