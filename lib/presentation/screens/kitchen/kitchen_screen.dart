import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/models/kitchen_order.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<KitchenOrder> orders = [];
  Map<String, int> counts = {};
  bool isLoading = true;
  String? error;
  Timer? _pollTimer;
  Timer? _elapsedTimer; // Refreshes urgency colors every minute
  String selectedTab = 'active'; // 'active' (En Curso) or 'completed' (Completados)

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders());
    _elapsedTimer = Timer.periodic(const Duration(seconds: 30), (_) {
       if (mounted) setState(() {}); // Refresh UI for timestamps
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      // Map 'active' to statuses that are 'En Curso'
      String statusFilter = selectedTab == 'active' 
          ? 'confirmed,preparing' 
          : 'ready,delivered'; 
      
      final restaurantId = await ConfigurationService.getRestaurantId();
      final response = await ApiService.fetchKitchenOrders(
        restaurantId: restaurantId,
        status: statusFilter,
      );

      if (mounted) {
        setState(() {
          orders = response.orders;
          counts = response.counts;
          isLoading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }
  
   Future<void> _advanceOrder(int orderId) async {
      // Move to next state automatically?
      // Confirmed -> Preparing -> Ready -> Delivered?
      // Or just active -> ready?
      // User requested "En Curso" (Active) vs "Completados".
      // If I click "Terminar" on an active order, it should go to 'ready'.
      try {
        await ApiService.updateOrderStatus(orderId: orderId, status: 'ready');
        _loadOrders();
      } catch (e) {
         // Show error
      }
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos conteos para los tabs
    // Active = confirmed + preparing
    // Completed = ready + delivered
    final activeCount = (counts['confirmed'] ?? 0) + (counts['preparing'] ?? 0);
    final completedCount = (counts['ready'] ?? 0) + (counts['delivered'] ?? 0);
    
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final userName = posProvider.currentCashRegister?.user?.name ?? 'Usuario';
    final userRole = 'Cocinero'; // TODO: Obtener del rol real

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 24,
        title: Row(
          children: [
            // Time (Mock or Real)
            Text(
              _formatTime(DateTime.now()),
              style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Cocina',
              style: TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.normal
              ),
            ),
            const Spacer(),
            
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                   _buildTab('Completados', 'completed', completedCount),
                   _buildTab('En Curso', 'active', activeCount),
                ],
              ),
            ),
            const Spacer(),
            
            // User Profile con nombre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    radius: 16,
                    child: const Icon(Icons.person, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$userRole - $userName',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : error != null 
              ? Center(child: Text('Error: $error')) 
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // 5 columns as per image roughly
                      childAspectRatio: 0.60, // Tall cards
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return KitchenOrderCard(
                        order: orders[index],
                        onAdvance: () => _advanceOrder(orders[index].id),
                      );
                    },
                  ),
                ),
    );
  }
  
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTab(String label, String value, int count) {
    final isSelected = selectedTab == value;
    final color = isSelected ? Colors.black87 : Colors.grey.shade200;
    final textColor = isSelected ? Colors.white : Colors.black54;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = value;
          isLoading = true;
        });
        _loadOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          count > 0 ? '$label($count)' : label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class KitchenOrderCard extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback onAdvance;

  const KitchenOrderCard({
    super.key,
    required this.order,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = order.elapsedMinutes;
    // Urgency Logic
    // Default: Black/Green (Safe)
    // Warning: > 10 mins (Orange)
    // Critical: > 20 mins (Red)
    Color headerColor = Colors.black; // Default "Safe" or "New"
    if (elapsed > 20) {
      headerColor = Colors.red.shade700;
    } else if (elapsed > 10) {
      headerColor = Colors.orange.shade800;
    } else {
      headerColor = const Color(0xFF1B1B1B); // Blackish
    }

    final timeStr = "${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2,'0')}";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#Orden ${order.id}', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)
                    ),
                  ],
                ),
                Text(
                  order.orderTypeLabel, // "Llevar" vs "Comer Aquí"
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                   // Truncate logic if needed, but ListView handles scroll.
                   // The image showed +7 products.
                   // If activity requires viewing all, scroll is better.
                   // Getting strict to design:
                   if (index > 5) {
                     if (index == 6) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                             '+ ${order.items.length - 6} productos mas',
                             style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        );
                     }
                     return const SizedBox.shrink();
                   }
                   
                   final item = order.items[index];
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 12.0),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           '${item.quantity}',
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 item.productName,
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                               ),
                               // Modifiers / Notes in Red
                               if (item.modifiers.isNotEmpty)
                                 ...item.modifiers.map((m) => Text(m, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
                               
                               // Parse extra notes (like [PARA LLEVAR]) and hide if redundant, or show.
                               // We appended [PARA LLEVAR] to the note. We probably want to hide it here since it's in header.
                               if (item.notes != null)
                                  _buildNoteText(item.notes!),
                             ],
                           ),
                         ),
                       ],
                     ),
                   );
                },
              ),
            ),
          ),
          
          // Footer (Action)
          // Double Tap to complete? Or Button?
          // Image implies interaction.
          // I'll add a "Terminar" button or InkWell on Header?
          // Let's make the whole card tappable or adding a footer button.
          InkWell(
            onTap: onAdvance,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const Text('MARCAR LISTO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteText(String note) {
    // Remove tags we added
    final clean = note.replaceAll('[PARA COMER AQUÍ]', '').replaceAll('[PARA LLEVAR]', '').trim();
    if (clean.isEmpty) return const SizedBox.shrink();
    
    return Text(
      clean,
      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
    );
  }
}
