import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product_group.dart';
import 'package:restaurant_kiosco/models/category.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import '../../widgets/build_category_carousel.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_cards_products.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_header.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategoryName = '';
  List<ProductGroup> productGroups = [];

  @override
  void initState() {
    super.initState();
    loadCategory(1); // cargar categoría 1 por defecto
  }

  void loadCategory(int categoryId) async {
    try {
      final Category categoryDetail = await ApiService.fetchCategoryWithProducts(categoryId);

      if (!mounted) return;

      setState(() {
        selectedCategoryName = categoryDetail.name;
        productGroups = categoryDetail.productGroups;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar productos')),
      );
    }
  }

  // void loadCategory(int categoryId) async {
  //   try {
  //     final Category categoryDetail = await ApiService.fetchCategoryWithProducts(categoryId);

  //     setState(() {
  //       selectedCategoryName = categoryDetail.name;
  //       productGroups = categoryDetail.productGroups;
  //     });
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error al cargar productos')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Encabezado
            SliverToBoxAdapter(child: BuildHeader()),

            // Categorías
            SliverToBoxAdapter(
              child: BuildCategoryCarousel(
                onCategoryTap: loadCategory, // ejecuta sin cambiar pantalla
              ),
            ),

            // Productos por grupo
            ...productGroups.map((group) {
              return SliverToBoxAdapter(
                child: BuildCardsProducts(
                  category: group.name,
                  products: group.products,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
