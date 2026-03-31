import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/printer_service_v2.dart';

class PrinterConfigScreen extends StatefulWidget {
  const PrinterConfigScreen({super.key});

  @override
  State<PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<PrinterConfigScreen> with SingleTickerProviderStateMixin {
  final PrinterService _printerService = PrinterService();
  late TabController _tabController;
  
  // Bluetooth
  List<BluetoothInfo> _bluetoothPrinters = [];
  bool _isBluetoothScanning = false;
  
  // Red
  List<String> _networkPrinters = [];
  bool _isNetworkScanning = false;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '9100');
  final TextEditingController _subnetController = TextEditingController(text: '192.168.1');
  
  // General
  bool _isLoading = false;
  PrinterConfig? _savedPrinter;
  int _paperWidth = 80; // 58mm o 80mm

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedPrinter();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _subnetController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPrinter() async {
    final printer = await _printerService.getLastPrinter();
    setState(() {
      _savedPrinter = printer;
    });
  }

  // ============================================================================
  // BLUETOOTH
  // ============================================================================

  Future<void> _scanBluetoothPrinters() async {
    setState(() {
      _isBluetoothScanning = true;
    });

    try {
      final printers = await _printerService.getBluetoothPrinters();
      setState(() {
        _bluetoothPrinters = printers;
        _isBluetoothScanning = false;
      });
    } catch (e) {
      setState(() {
        _isBluetoothScanning = false;
      });
      _showError('Error al buscar impresoras Bluetooth: $e');
    }
  }

  Future<void> _connectBluetooth(BluetoothInfo printer) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = PrinterConfig(
        id: 'bt_${printer.macAdress}',
        name: printer.name,
        connectionType: PrinterConnectionType.bluetooth,
        bluetoothAddress: printer.macAdress,
        paperWidth: _paperWidth,
      );

      final success = await _printerService.connectToPrinter(config);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        setState(() {
          _savedPrinter = config;
        });
        _showSuccess('Conectado a ${printer.name}');
        await _testPrint();
      } else {
        _showError('No se pudo conectar');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: $e');
    }
  }

  // ============================================================================
  // RED (IP)
  // ============================================================================

  Future<void> _scanNetworkPrinters() async {
    setState(() {
      _isNetworkScanning = true;
      _networkPrinters = [];
    });

    try {
      final subnet = _subnetController.text.trim();
      
      // Mostrar progreso
      _showInfo('Escaneando red $subnet.1-254...');

      final printers = await _printerService.scanNetworkPrinters(
        subnet: subnet,
        startRange: 1,
        endRange: 254,
        timeout: const Duration(milliseconds: 300),
      );

      setState(() {
        _networkPrinters = printers;
        _isNetworkScanning = false;
      });

      if (printers.isEmpty) {
        _showInfo('No se encontraron impresoras en la red');
      } else {
        _showSuccess('Encontradas ${printers.length} impresoras');
      }
    } catch (e) {
      setState(() {
        _isNetworkScanning = false;
      });
      _showError('Error al escanear red: $e');
    }
  }

  Future<void> _connectManualIP() async {
    final ip = _ipController.text.trim();
    final portText = _portController.text.trim();

    if (ip.isEmpty) {
      _showError('Ingresa una dirección IP');
      return;
    }

    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      _showError('Puerto inválido');
      return;
    }

    // Primero verificar que responda
    setState(() {
      _isLoading = true;
    });

    try {
      final responds = await _printerService.testNetworkPrinter(ip, port);
      
      if (!responds) {
        setState(() {
          _isLoading = false;
        });
        _showError('No hay impresora en $ip:$port');
        return;
      }

      // Conectar
      final config = PrinterConfig(
        id: 'net_${ip}_$port',
        name: 'Impresora $ip',
        connectionType: PrinterConnectionType.network,
        ipAddress: ip,
        port: port,
        paperWidth: _paperWidth,
      );

      final success = await _printerService.connectToPrinter(config);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        setState(() {
          _savedPrinter = config;
        });
        _showSuccess('Conectado a $ip:$port');
        await _testPrint();
      } else {
        _showError('No se pudo conectar');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: $e');
    }
  }

  Future<void> _connectNetworkIP(String ip) async {
    _ipController.text = ip;
    await _connectManualIP();
  }

  // ============================================================================
  // ACCIONES GENERALES
  // ============================================================================

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    setState(() {
      _savedPrinter = null;
    });
    _showInfo('Desconectado');
  }

  Future<void> _testPrint() async {
    if (!_printerService.isConnected) {
      _showError('No hay impresora conectada');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _printerService.printTest();
      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccess('Ticket de prueba impreso ✓');
      } else {
        _showError('Error al imprimir');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: $e');
    }
  }

  // ============================================================================
  // UI HELPERS
  // ============================================================================

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Impresora'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
            Tab(icon: Icon(Icons.wifi), text: 'Red (IP)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Estado de conexión
          _buildConnectionStatus(),
          
          // Configuración de papel
          _buildPaperWidthSelector(),
          
          // Contenido de pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBluetoothTab(),
                _buildNetworkTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected = _printerService.isConnected;
    final printer = _savedPrinter;

    return Card(
      margin: const EdgeInsets.all(16),
      color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.check_circle : Icons.cancel,
              color: isConnected ? Colors.green : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Impresora conectada' : 'Sin conexión',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (printer != null) ...[
                    Text(
                      printer.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      printer.connectionType == PrinterConnectionType.bluetooth
                          ? 'Bluetooth: ${printer.bluetoothAddress}'
                          : 'Red: ${printer.ipAddress}:${printer.port}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isConnected) ...[
              IconButton(
                onPressed: _testPrint,
                icon: const Icon(Icons.print, color: Colors.blue),
                tooltip: 'Probar impresión',
              ),
              IconButton(
                onPressed: _disconnect,
                icon: const Icon(Icons.link_off, color: Colors.red),
                tooltip: 'Desconectar',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaperWidthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Ancho de papel:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('58mm'),
            selected: _paperWidth == 58,
            onSelected: (selected) {
              if (selected) setState(() => _paperWidth = 58);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('80mm'),
            selected: _paperWidth == 80,
            onSelected: (selected) {
              if (selected) setState(() => _paperWidth = 80);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isBluetoothScanning || _isLoading ? null : _scanBluetoothPrinters,
            icon: _isBluetoothScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(_isBluetoothScanning ? 'Buscando...' : 'Buscar Impresoras Bluetooth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Impresoras Bluetooth Disponibles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _bluetoothPrinters.isEmpty
                ? _buildEmptyState(
                    icon: Icons.bluetooth_disabled,
                    message: 'No se encontraron impresoras Bluetooth',
                    hint: 'Asegúrate de emparejarlas primero en configuración del dispositivo',
                  )
                : ListView.builder(
                    itemCount: _bluetoothPrinters.length,
                    itemBuilder: (context, index) {
                      final printer = _bluetoothPrinters[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.print, color: Colors.purple),
                          title: Text(printer.name),
                          subtitle: Text(printer.macAdress),
                          trailing: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isLoading ? null : () => _connectBluetooth(printer),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Escaneo automático
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escaneo Automático',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subnetController,
                          decoration: const InputDecoration(
                            labelText: 'Subred',
                            hintText: '192.168.1',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('.1-254', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isNetworkScanning || _isLoading ? null : _scanNetworkPrinters,
                    icon: _isNetworkScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isNetworkScanning ? 'Escaneando...' : 'Escanear Red'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  if (_isNetworkScanning)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Esto puede tardar 1-2 minutos...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Conexión manual
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conexión Manual',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección IP',
                      hintText: '192.168.1.100',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Puerto',
                      hintText: '9100',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.power),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _connectManualIP,
                    icon: const Icon(Icons.link),
                    label: const Text('Conectar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Resultados de escaneo
          const Text(
            'Impresoras Encontradas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _networkPrinters.isEmpty
                ? _buildEmptyState(
                    icon: Icons.wifi_off,
                    message: 'No se han encontrado impresoras',
                    hint: 'Usa el escaneo automático o ingresa la IP manualmente',
                  )
                : ListView.builder(
                    itemCount: _networkPrinters.length,
                    itemBuilder: (context, index) {
                      final ip = _networkPrinters[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.print, color: Colors.blue),
                          title: Text(ip),
                          subtitle: const Text('Puerto 9100 abierto'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isLoading ? null : () => _connectNetworkIP(ip),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? hint,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                hint,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
