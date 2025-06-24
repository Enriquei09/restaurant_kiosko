import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/presentation/widgets/larger_button.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart';

class ProductDescription extends StatelessWidget {
  const ProductDescription({super.key});

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
                child: Row(children: [ImageContainer(), InfoProductContainer()]),
              ),
            ],
          ),
        ),
      )
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
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),

        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
                //print('Cuadro de Dialogo Cerrado');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ImageContainer extends StatelessWidget {
  const ImageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white),
      alignment: Alignment.topCenter,
      child: Image.asset('assets/products_img/sopes.jpg', width: 280),
    );
  }
}

class InfoProductContainer extends StatelessWidget {
  const InfoProductContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sopes de Chorizo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Description',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
          const Divider(height: 32),
          SizedBox(
            height: 250,
            child: SingleChildScrollView(child: ExtraSelector()),
          ),
          const Divider(height: 32),
          LargeButton(),
        ],
      ),
    );
  }
}

// class ItemList extends StatelessWidget {
//   const ItemList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 300,
//       child: ListView(
//         children: <Widget>[
//           Divider(height: 1),
//           Text("Extras"),
//           ListTile(
//             title: Text("Cebolla"),
//             trailing: Checkbox(value: false, onChanged: (bool? value) {}),
//           ),
//           ListTile(
//             title: Text("Cilandro"),
//             trailing: Checkbox(value: true, onChanged: (bool? value) {}),
//           ),
//           Divider(height: 1),
//           Text("Condimentos"),
//           ListTile(
//             title: Text("Cilandro"),
//             trailing: Checkbox(value: true, onChanged: (bool? value) {}),
//           ),
//           ListTile(
//             title: Text("Cilandro"),
//             trailing: Checkbox(value: true, onChanged: (bool? value) {}),
//           ),
//           ListTile(
//             title: Text("Cilandro"),
//             trailing: Checkbox(value: true, onChanged: (bool? value) {}),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class LargeButton extends StatelessWidget {
//   final bool enabled;
//   const LargeButton({super.key, this.enabled = false});
//   @override
//   Widget build(BuildContext context) {
//     final VoidCallback? onPressed = enabled ? () {} : null;

//     return Center(
//       child: FilledButton(
//         onPressed: onPressed,
//         // style: FilledButton.styleFrom(
//         //   backgroundColor: const Color.fromARGB(255, 192, 31, 31),
//         //   foregroundColor: Colors.white,
//         //   padding: const EdgeInsets.symmetric(horizontal: 24)
//         // ),
//         style: ButtonStyle(
//           padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
//             EdgeInsets.symmetric(horizontal: 80),
//           ),
//           backgroundColor: WidgetStateProperty.all<Color>(
//             const Color.fromARGB(255, 10, 10, 10),
//           ),
//           foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
//         ),
//         child: Text("Agregar al Carrito"),
//       ),
//     );
//   }
// }


/*

ListTile(
      title: const Text('Opción A'),
      trailing: Checkbox(
        value: true,
        onChanged: (bool? value) {},
      ),
    );

*/