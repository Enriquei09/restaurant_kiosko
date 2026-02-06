import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../models/cash_register_terminal.dart';
import '../../service/api_service.dart';
import 'terminal/pin_entry_screen.dart';

class TerminalSelectionScreen extends StatefulWidget {
  const TerminalSelectionScreen({Key? key}) : super(key: key);

  @override
  State<TerminalSelectionScreen> createState() => _TerminalSelectionScreenState();
}

class _TerminalSelectionScreenState extends State<TerminalSelectionScreen> {
  List<CashRegisterTerminal> terminals = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTerminals();
  }

  Future<void> _loadTerminals() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      
      final response = await ApiService.getTerminals(
        tenantId: posProvider.tenantId,
        restaurantId: posProvider.restaurantId,
      );
      
      if (response['success'] == true) {
        setState(() {
          terminals = (response['terminals'] as List)
              .map((terminal) => CashRegisterTerminal.fromJson(terminal))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Error al cargar terminales';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  void _selectTerminal(CashRegisterTerminal terminal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(terminal: terminal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Terminal'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : errorMessage.isNotEmpty
                  ? _buildError()
                  : _buildTerminalsList(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadTerminals,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalsList() {
    if (terminals.isEmpty) {
      return const Center(
        child: Text(
          'No hay terminales disponibles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tu terminal de trabajo:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: terminals.length,
              itemBuilder: (context, index) {
                final terminal = terminals[index];
                return _buildTerminalCard(terminal);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalCard(CashRegisterTerminal terminal) {
    // Temporalmente forzamos disponible
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _selectTerminal(terminal),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.point_of_sale,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                terminal.terminalNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                terminal.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Disponible',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (terminal.location?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  terminal.location!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}