import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product_group.dart';
import 'package:restaurant_kiosco/models/category.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import '../../widgets/build_category_carousel.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_cards_products.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_header.dart';
import 'package:restaurant_kiosco/presentation/widgets/button_icon.dart';

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

      bool loaded = false;
      for (final category in categories) {
        loaded = await loadCategory(category.id, showError: false);
        if (loaded) break;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (!loaded) {
          selectedCategoryName = 'Sin categorías válidas';
          productGroups = [];
        }
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

  Future<bool> loadCategory(int categoryId, {bool showError = true}) async {
    try {
      final Category categoryDetail = await ApiService.fetchCategoryWithProducts(categoryId);

      if (!mounted) return false;

      setState(() {
        selectedCategoryName = categoryDetail.name;
        productGroups = categoryDetail.productGroups;
        _isLoading = false;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;

      debugPrint('Error al cargar categoría $categoryId: $e');

      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede cargar esta categoría'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
      
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
      backgroundColor: const Color(0xFFF6F6F6),
      floatingActionButton: const ButtonIcon(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
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
