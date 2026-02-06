import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/models/table_model.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/table_provider.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';
import '../table_detail_screen.dart';

class TablesScreen extends StatefulWidget {
  final void Function(BuildContext context, RestaurantTable table)? onTableSelected;

  const TablesScreen({super.key, this.onTableSelected});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    final restaurantId = await ConfigurationService.getRestaurantId();
    if (mounted) {
      Provider.of<TableProvider>(context, listen: false).fetchTables(restaurantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        if (tableProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tableProvider.error != null) {
          return Center(child: Text('Error: ${tableProvider.error}'));
        }

        if (tableProvider.tables.isEmpty) {
          return const Center(child: Text('No hay mesas configuradas'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Adjust based on screen size?
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: tableProvider.tables.length,
            itemBuilder: (context, index) {
              final table = tableProvider.tables[index];
              final isOccupied = table.status == 'occupied';
              final color = isOccupied ? Colors.red.shade100 : Colors.green.shade100;
              final textColor = isOccupied ? Colors.red.shade900 : Colors.green.shade900;
              final icon = isOccupied ? Icons.people : Icons.table_restaurant;

              return InkWell(
                onTap: () {
                  if (widget.onTableSelected != null) {
                    widget.onTableSelected!(context, table);
                  } else {
                    // Si la mesa está ocupada, mostrar detalle
                    if (isOccupied) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TableDetailScreen(
                            tableId: table.id,
                            tableName: table.name,
                          ),
                        ),
                      ).then((value) {
                        if (value == true) {
                          _loadTables(); // Recargar mesas si hubo cambios
                        }
                      });
                    } else {
                      // Mesa disponible: abrir para nueva orden
                      _openTable(context, table.id);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: textColor.withOpacity(0.5), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 48, color: textColor),
                      const SizedBox(height: 8),
                      Text(
                        table.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        isOccupied ? 'Ocupada' : 'Disponible',
                        style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openTable(BuildContext context, int tableId) {
    // Set table in Cart and navigate to Menu
    final cart = Provider.of<CartModel>(context, listen: false);
    cart.clear(); // Clear previous session
    cart.setTableId(tableId);
    
    // Navigate to Menu
    // We can push named or push replacement. Push named keeps Cashier stack.
    Navigator.pushNamed(context, '/menu');
  }
}
