import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/table_provider.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';

class TableInputScreen extends StatefulWidget {
  const TableInputScreen({super.key});

  @override
  State<TableInputScreen> createState() => _TableInputScreenState();
}

class _TableInputScreenState extends State<TableInputScreen> {
  String _input = '';

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

  void _onKeyPress(String value) {
    if (_input.length < 3) {
      setState(() {
        _input += value;
      });
    }
  }

  void _onBackspace() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  void _onSubmit() {
    if (_input.isEmpty) return;

    final provider = Provider.of<TableProvider>(context, listen: false);
    try {
      // Validate against loaded tables
      // We assume Tracker Number matches Table Name
      final table = provider.tables.firstWhere((t) => t.name == _input);
      
      // Found! Assign table ID to cart
      context.read<CartModel>().setTableId(table.id);
      
      // Navigate to Checkout
      Navigator.pushNamed(context, '/checkout');
    
    } catch (e) {
      // Not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Número de localizador no válido (Mesa no encontrada)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3d5a80),
        foregroundColor: Colors.white,
        title: const Text('Número de Localizador / Mesa'),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'Ingresa tu número de localizador o mesa',
            style: TextStyle(fontSize: 24, color: Color(0xFF3d5a80)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Display
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 2)),
            ),
            child: Text(
              _input,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8),
              textAlign: TextAlign.center,
            ),
          ),
          
          const Spacer(),
          
          // Keypad
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                const SizedBox(height: 16),
                _buildRow(['4', '5', '6']),
                const SizedBox(height: 16),
                _buildRow(['7', '8', '9']),
                const SizedBox(height: 16),
                _buildRow(['', '0', 'back']),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Continue Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _input.isNotEmpty ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3d5a80),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('CONTINUAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox(width: 80, height: 80);
        
        if (key == 'back') {
          return SizedBox(
            width: 80,
            height: 80,
            child: IconButton(
              onPressed: _onBackspace,
              icon: const Icon(Icons.backspace_outlined, size: 32),
              color: Colors.grey.shade700,
            ),
          );
        }
        
        return SizedBox(
          width: 80,
          height: 80,
          child: OutlinedButton(
            onPressed: () => _onKeyPress(key),
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text(
              key,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.normal, color: Colors.black87),
            ),
          ),
        );
      }).toList(),
    );
  }
}
