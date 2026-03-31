import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/printer_service.dart';

class PrinterConfigScreen extends StatefulWidget {
  const PrinterConfigScreen({super.key});

  @override
  State<PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<PrinterConfigScreen> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothInfo> _printers = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _selectedPrinterMac;
  String? _savedPrinterMac;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
    _checkConnection();
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPrinterMac = prefs.getString('printer_mac_address');
    });
  }

  Future<void> _savePrinter(String macAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_mac_address', macAddress);
    setState(() {
      _savedPrinterMac = macAddress;
    });
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isConnected = _printerService.isConnected;
    });
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final printers = await _printerService.getAvailablePrinters();
      setState(() {
        _printers = printers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar impresoras: $e')),
        );
      }
    }
  }

  Future<void> _connectToPrinter(BluetoothInfo printer) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _printerService.connectToPrinter(printer.macAdress);
      
      setState(() {
        _isLoading = false;
        _isConnected = success;
      });

      if (success) {
        await _savePrinter(printer.macAdress);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conectado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al conectar con la impresora'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    setState(() {
      _isConnected = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Desconectado')),
      );
    }
  }

  Future<void> _testPrint() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _printerService.printTest();
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Ticket de prueba impreso' : 'Error al imprimir'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Impresora'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado de conexión
            Card(
              color: _isConnected ? Colors.green.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.cancel,
                      color: _isConnected ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected ? 'Impresora conectada' : 'Sin conexión',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_savedPrinterMac != null)
                            Text(
                              'MAC: $_savedPrinterMac',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isConnected)
                      IconButton(
                        onPressed: _disconnect,
                        icon: const Icon(Icons.link_off, color: Colors.red),
                        tooltip: 'Desconectar',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _scanPrinters,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(_isLoading ? 'Buscando...' : 'Buscar Impresoras'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),

            if (_isConnected)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testPrint,
                icon: const Icon(Icons.print),
                label: const Text('Imprimir Prueba'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

            const SizedBox(height: 24),

            // Lista de impresoras
            const Text(
              'Impresoras Disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _printers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print_disabled, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron impresoras',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Presiona "Buscar Impresoras" para escanear',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _printers.length,
                      itemBuilder: (context, index) {
                        final printer = _printers[index];
                        final isSaved = printer.macAdress == _savedPrinterMac;

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.print,
                              color: isSaved ? Colors.purple : Colors.grey,
                            ),
                            title: Text(
                              printer.name,
                              style: TextStyle(
                                fontWeight: isSaved ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(printer.macAdress),
                            trailing: isSaved
                                ? const Chip(
                                    label: Text('Guardada'),
                                    backgroundColor: Colors.purple,
                                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                                  )
                                : null,
                            onTap: _isLoading
                                ? null
                                : () => _connectToPrinter(printer),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
