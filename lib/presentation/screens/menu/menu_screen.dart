import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/buil_category_carousel.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_header.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            //Encabezado
            SliverToBoxAdapter(child: BuildHeader()),

            //Categorias
            SliverToBoxAdapter(child: BuilCategoryCarousel())
          ],
        )
      
      ),
    );
  }
}
