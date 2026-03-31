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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFirstCategory();
  }

  Future<void> _loadFirstCategory() async {
    try {
      // Obtener todas las categorías del restaurante actual
      final categories = await ApiService.fetchCategories();
      
      if (!mounted) return;
      
      if (categories.isEmpty) {
        setState(() {
          _isLoading = false;
          selectedCategoryName = 'Sin categorías';
        });
        return;
      }
      
      // Cargar la primera categoría disponible
      loadCategory(categories.first.id);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error al cargar categorías: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el menú: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

      debugPrint('Error al cargar categoría $categoryId: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede cargar esta categoría'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // No intentar recargar, dejar que el usuario seleccione otra categoría
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
