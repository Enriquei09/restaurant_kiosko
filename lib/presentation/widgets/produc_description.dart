import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product.dart';
import 'package:restaurant_kiosco/presentation/widgets/larger_button.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart';

class ProductDescription extends StatelessWidget {
  const ProductDescription({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 760,
          height: 720,
          color: Colors.white,
          child: Column(
            children: [
              _HeaderImage(product: product),
              Expanded(child: InfoProductContainer(product: product)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  final Product product;
  const _HeaderImage({required this.product});

  @override
  Widget build(BuildContext context) {
    final isNetwork = product.imagePath.startsWith('http');
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del producto
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: isNetwork
                      ? Image.network(
                          product.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : Image.asset(
                          product.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                ),
                // Botón cerrar sobre la imagen
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nombre y descripción sobre fondo blanco
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if (product.description.isNotEmpty) ...
                  [
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.restaurant_menu, size: 64, color: Color(0xFFCCCCCC)),
        ),
      );
}

class InfoProductContainer extends StatefulWidget {
  const InfoProductContainer({super.key, required this.product});
  final Product product;

  @override
  State<InfoProductContainer> createState() => _InfoProductContainerState();
}

class _InfoProductContainerState extends State<InfoProductContainer> {
  List<int> selectedModifiers = [];
  List<String> _modsLabels = [];
  int qty = 1;
  String? note;
  double _extraTotal = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final total = (p.price + _extraTotal) * qty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base: \$${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A6D),
                  ),
                ),
                const SizedBox(height: 12),
                ExtraSelector(
                  key: ValueKey(p.id),
                  productId: p.id,
                  onChanged: (mods) => setState(() => selectedModifiers = mods),
                  onLabelsChanged: (labels) => setState(() => _modsLabels = labels),
                  onQtyChanged: (q) => setState(() => qty = q),
                  onNoteChanged: (n) => setState(() => note = n),
                  onExtraTotalChanged: (value) => setState(() => _extraTotal = value),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              LargeButton(
                productId: p.id,
                name: p.name,
                price: p.price,
                imagePath: p.imagePath,
                modifierIds: selectedModifiers,
                modifierLabels: _modsLabels,
                qty: qty,
                note: note,
                openCartAfterAdd: true,
                closeCurrentDialog: true,
                buttonText: 'Agregar al carrito • \$${total.toStringAsFixed(2)}',
                backgroundColor: const Color(0xFFE91E63),
                minHeight: 64,
                fontSize: 22,
              ),
            ],
          ),
        ),
      ],
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

// Mantener clase para compatibilidad en imports antiguos
class IconsViewCard extends StatelessWidget {
  const IconsViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
