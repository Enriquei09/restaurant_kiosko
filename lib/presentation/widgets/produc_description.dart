import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product.dart';
import 'package:restaurant_kiosco/presentation/widgets/larger_button.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart';

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

class InfoProductContainer extends StatefulWidget {
  const InfoProductContainer({super.key, required this.product});
  final Product product;

  @override
  State<InfoProductContainer> createState() => _InfoProductContainerState();
}

class _InfoProductContainerState extends State<InfoProductContainer> {
  // estado recibido desde el selector
  List<int> selectedModifiers = [];
  List<String> _modsLabels = [];
  int qty = 1;
  String? note;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Container(
      width: 300,
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // título y descripción (idéntico a tu versión)
          Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            p.description.isEmpty ? 'Description' : p.description,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
          const Divider(height: 32),

          // selector (scrollable) — devuelve extras, qty y nota
          SizedBox(
            height: 250,
            child: SingleChildScrollView(
              child: ExtraSelector(
                key: ValueKey(p.id),
                productId: p.id,
                onChanged: (mods) => setState(() => selectedModifiers = mods),
                onLabelsChanged: (labels) => setState(()=> _modsLabels = labels),
                onQtyChanged: (q) => setState(() => qty = q),
                onNoteChanged: (n) => setState(() => note = n),
                // si tu ExtraSelector soporta initialQty/initialNote, puedes pasarlos
                // initialQty: qty,
                // initialNote: note,
              ),
            ),
          ),

          const Divider(height: 32),

          // botón que agrega al carrito con todo lo elegido
          // OJO: si tu clase se llama LargeButton dentro de larger_button.dart, esto compila bien.
          LargeButton(
            productId: p.id,
            name: p.name,
            price: p.price,
            imagePath: p.imagePath,
            modifierIds: selectedModifiers,
            modifierLabels: _modsLabels, 
            qty: qty,
            note: note,
            openCartAfterAdd: true, // abre el modal del carrito al agregar
            closeCurrentDialog: true,
          ),
        ],
      ),
    );
  }
}
