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
  // ── Constantes de diseño ──────────────────────────────────
  static const _kPink    = Color(0xFFE91E63);
  static const _kDark    = Color(0xFF212121);
  static const _kSub     = Color(0xFF757575);
  static const _kEmerald = Color(0xFF2E7D32);

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
          return const Center(
              child: CircularProgressIndicator(color: _kPink));
        }

        if (tableProvider.error != null) {
          return Center(
            child: Text('Error: ${tableProvider.error}',
                style: const TextStyle(color: _kSub, fontFamily: 'Inter')),
          );
        }

        if (tableProvider.tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'No hay mesas configuradas',
                  style: TextStyle(
                      fontSize: 16, color: _kSub, fontFamily: 'Inter'),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 600
                    ? 3
                    : 2;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.3,
                ),
                itemCount: tableProvider.tables.length,
                itemBuilder: (context, index) {
                  final table = tableProvider.tables[index];
                  return _buildTableCard(table);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTableCard(RestaurantTable table) {
    final isOccupied = table.status == 'occupied';
    final Color accent = isOccupied ? _kPink : _kEmerald;
    final Color accentBg =
        isOccupied ? const Color(0xFFFCE4EC) : const Color(0xFFE8F5E9);
    final String statusLabel = isOccupied ? 'Ocupada' : 'Disponible';
    final IconData icon = isOccupied
        ? Icons.people_outline_rounded
        : Icons.table_restaurant_outlined;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _handleTableTap(table),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: accent, width: 5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 26, color: accent),
              ),
              const SizedBox(height: 10),
              Text(
                table.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTableTap(RestaurantTable table) {
    if (widget.onTableSelected != null) {
      widget.onTableSelected!(context, table);
      return;
    }

    final isOccupied = table.status == 'occupied';
    if (isOccupied) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TableDetailScreen(
            tableId: table.id,
            tableName: table.name,
          ),
        ),
      ).then((value) {
        if (value == true) _loadTables();
      });
    } else {
      _openTable(context, table.id);
    }
  }

  void _openTable(BuildContext context, int tableId) {
    final cart = Provider.of<CartModel>(context, listen: false);
    cart.clear();
    cart.setTableId(tableId);
    cart.setOrderType(OrderType.dineIn);
    Navigator.pushNamed(context, '/menu');
  }
}
