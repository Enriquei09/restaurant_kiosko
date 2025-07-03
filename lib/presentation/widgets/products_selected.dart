import 'package:flutter/material.dart';

class ProductsSelected extends StatelessWidget {
  const ProductsSelected({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 400,
        height: 700,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Productos Seleccionados",
                style: TextStyle(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 19, 3, 22),
                ),
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(5),
                children: [                  
                  NewCardProductSelected(impProduct: "assets/products_img/sopes.jpg", product: "Sopes", priceProduct: "45.44"),
                  NewCardProductSelected(impProduct: "assets/products_img/sopes.jpg", product: "Sopes", priceProduct: "45.44"),
                  NewCardProductSelected(impProduct: "assets/products_img/sopes.jpg", product: "Sopes", priceProduct: "45.44")
                ],
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 10.0,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text("Total"), Text("\$45.00")],
                  ),
                  Center(
                    child: Column(
                      spacing: 10.0,
                      //mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: Text("Confirmar"),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: Text("Cancelar"),
                        ),
                      ],
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

// widget de listview para productos seleccionados
/*-------------------------------------------------------------------*/

class NewCardProductSelected extends StatefulWidget {
  final String impProduct;
  final String product;
  final String priceProduct;

  const NewCardProductSelected({
    super.key,
    required this.impProduct,
    required this.product,
    required this.priceProduct,
  });

  @override
  State<NewCardProductSelected> createState() => _ListTitleProductState();
}

class _ListTitleProductState extends State<NewCardProductSelected> {
  int quantity = 1;
  bool isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: quantity.toString());
  }

  void _saveQuantity() {
    final newQuantity = int.tryParse(_controller.text);
    if (newQuantity != null && newQuantity >= 0 && newQuantity <= 100) {
      setState(() {
        quantity = newQuantity;
        isEditing = false;
      });
    }
  }

  void _increaseQuantity() {
    if (quantity < 100) {
      setState(() {
        quantity++;
        _controller.text = quantity.toString();
      });
    }
  }

  void _decreaseQuantity() {
    if (quantity > 0) {
      setState(() {
        quantity--;
        _controller.text = quantity.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                // IconButton(
                //   icon: const Icon(Icons.close, color: Colors.red),
                //   onPressed: () {
                //     // lógica para eliminar
                //   },
                // ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    widget.impProduct,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("\$ ${widget.priceProduct}"),
                    ],
                  ),
                ),
                if (!isEditing) Text("x $quantity"),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing;
                      _controller.text = quantity.toString();
                    });
                  },
                  child: Text(isEditing ? "Guardar" : "Editar"),
                ),
              ],
            ),

            // Sección de edición si está activo
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    const Text("Cantidad: "),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _decreaseQuantity,
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        ),
                        onSubmitted: (_) => _saveQuantity(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _increaseQuantity,
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _saveQuantity,
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
