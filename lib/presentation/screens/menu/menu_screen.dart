import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/buil_category_carousel.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_cards_products.dart';
import 'package:restaurant_kiosco/presentation/widgets/build_header.dart';
//import 'package:restaurant_kiosco/presentation/widgets/card_category.dart';

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
            SliverToBoxAdapter(child: BuilCategoryCarousel()),
            
            

            //PRODUCTS
            SliverToBoxAdapter(child: BuildCardsProducts(category: 'Barbacoa'))
          ]  
        )
      
      ),
    );
  }
}
