import 'dart:io';
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum para tipos de conexión de impresora
enum PrinterConnectionType {
  bluetooth,
  network, // IP/Ethernet
  usb
}

/// Modelo para configuración de impresora
class PrinterConfig {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final String? bluetoothAddress;  // Para Bluetooth
  final String? ipAddress;         // Para red
  final int? port;                 // Puerto (default 9100 para ESC/POS)
  final int paperWidth;            // 58mm o 80mm

  PrinterConfig({
    required this.id,
    required this.name,
    required this.connectionType,
    this.bluetoothAddress,
    this.ipAddress,
    this.port = 9100,
    this.paperWidth = 80,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'connectionType': connectionType.name,
    'bluetoothAddress': bluetoothAddress,
    'ipAddress': ipAddress,
    'port': port,
    'paperWidth': paperWidth,
  };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) => PrinterConfig(
    id: json['id'],
    name: json['name'],
    connectionType: PrinterConnectionType.values.firstWhere(
      (e) => e.name == json['connectionType']
    ),
    bluetoothAddress: json['bluetoothAddress'],
    ipAddress: json['ipAddress'],
    port: json['port'] ?? 9100,
    paperWidth: json['paperWidth'] ?? 80,
  );
}

/// Servicio de impresión unificado para Bluetooth y Red
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  bool _isConnected = false;
  PrinterConfig? _currentPrinter;
  NetworkPrinter? _networkPrinter;

  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;

  // ============================================================================
  // DESCUBRIMIENTO DE IMPRESORAS
  // ============================================================================

  /// Obtener impresoras Bluetooth disponibles
  Future<List<BluetoothInfo>> getBluetoothPrinters() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      print('Error obteniendo impresoras Bluetooth: $e');
      return [];
    }
  }

  /// Escanear red local en busca de impresoras (puerto 9100)
  /// Retorna lista de IPs que responden en puerto 9100
  Future<List<String>> scanNetworkPrinters({
    String subnet = '192.168.1', // Ej: 192.168.1
    int startRange = 1,
    int endRange = 254,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    final List<String> foundPrinters = [];
    
    for (int i = startRange; i <= endRange; i++) {
      final String ip = '$subnet.$i';
      try {
        final socket = await Socket.connect(
          ip,
          9100,
          timeout: timeout,
        );
        foundPrinters.add(ip);
        socket.destroy();
      } catch (e) {
        // No responde, continuar
      }
    }
    
    return foundPrinters;
  }

  /// Verificar si una IP específica tiene impresora ESC/POS
  Future<bool> testNetworkPrinter(String ipAddress, int port) async {
    try {
      final socket = await Socket.connect(
        ipAddress,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // CONEXIÓN
  // ============================================================================

  /// Conectar a impresora (Bluetooth o Red según configuración)
  Future<bool> connectToPrinter(PrinterConfig config) async {
    try {
      _currentPrinter = config;

      switch (config.connectionType) {
        case PrinterConnectionType.bluetooth:
          return await _connectBluetooth(config.bluetoothAddress!);
        
        case PrinterConnectionType.network:
          return await _connectNetwork(config.ipAddress!, config.port!);
        
        case PrinterConnectionType.usb:
          throw UnimplementedError('USB aún no implementado');
      }
    } catch (e) {
      print('Error conectando a impresora: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Conectar a impresora Bluetooth
  Future<bool> _connectBluetooth(String macAddress) async {
    try {
      final result = await PrintBluetoothThermal.connect(macAddress: macAddress);
      if (result) {
        _isConnected = true;
        await _saveLastPrinter();
        return true;
      }
      return false;
    } catch (e) {
      print('Error conectando Bluetooth: $e');
      return false;
    }
  }

  /// Conectar a impresora de red
  Future<bool> _connectNetwork(String ipAddress, int port) async {
    try {
      final profile = await CapabilityProfile.load();
      _networkPrinter = NetworkPrinter(
        PaperSize.mm80,
        profile,
      );
      
      final PosPrintResult result = await _networkPrinter!.connect(
        ipAddress,
        port: port,
        timeout: const Duration(seconds: 5),
      );

      if (result == PosPrintResult.success) {
        _isConnected = true;
        await _saveLastPrinter();
        return true;
      }
      
      print('Error de conexión: ${result.msg}');
      return false;
    } catch (e) {
      print('Error conectando a red: $e');
      return false;
    }
  }

  /// Desconectar impresora actual
  Future<void> disconnect() async {
    if (_currentPrinter?.connectionType == PrinterConnectionType.bluetooth) {
      await PrintBluetoothThermal.disconnect;
    } else if (_currentPrinter?.connectionType == PrinterConnectionType.network) {
      _networkPrinter?.disconnect();
      _networkPrinter = null;
    }
    
    _isConnected = false;
    _currentPrinter = null;
  }

  // ============================================================================
  // IMPRESIÓN DE TICKETS
  // ============================================================================

  /// Imprimir ticket de orden completo
  Future<bool> printOrderReceipt({
    required String restaurantName,
    required String orderNumber,
    required DateTime orderDate,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    String? customerName,
    String? tableName,
    String? notes,
  }) async {
    if (!_isConnected || _currentPrinter == null) {
      throw Exception('No hay impresora conectada');
    }

    try {
      final bytes = await _buildOrderReceipt(
        restaurantName: restaurantName,
        orderNumber: orderNumber,
        orderDate: orderDate,
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
        customerName: customerName,
        tableName: tableName,
        notes: notes,
      );

      return await _printBytes(bytes);
    } catch (e) {
      print('Error imprimiendo orden: $e');
      return false;
    }
  }

  /// Imprimir reporte de cierre de caja
  Future<bool> printCashRegisterReport({
    required String terminalName,
    required DateTime openedAt,
    required DateTime closedAt,
    required double initialBalance,
    required double expectedBalance,
    required double actualBalance,
    required double difference,
    required int totalOrders,
    required Map<String, double> paymentMethodTotals,
  }) async {
    if (!_isConnected || _currentPrinter == null) {
      throw Exception('No hay impresora conectada');
    }

    try {
      final bytes = await _buildCashRegisterReport(
        terminalName: terminalName,
        openedAt: openedAt,
        closedAt: closedAt,
        initialBalance: initialBalance,
        expectedBalance: expectedBalance,
        actualBalance: actualBalance,
        difference: difference,
        totalOrders: totalOrders,
        paymentMethodTotals: paymentMethodTotals,
      );

      return await _printBytes(bytes);
    } catch (e) {
      print('Error imprimiendo reporte: $e');
      return false;
    }
  }

  /// Imprimir ticket de prueba
  Future<bool> printTest() async {
    if (!_isConnected || _currentPrinter == null) {
      throw Exception('No hay impresora conectada');
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
        _currentPrinter!.paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80,
        profile,
      );
      
      List<int> bytes = [];
      bytes += generator.text(
        'TEST DE IMPRESIÓN',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
      bytes += generator.text('━' * (_currentPrinter!.paperWidth == 58 ? 32 : 48));
      bytes += generator.text('Impresora: ${_currentPrinter!.name}');
      bytes += generator.text('Tipo: ${_currentPrinter!.connectionType.name.toUpperCase()}');
      
      if (_currentPrinter!.connectionType == PrinterConnectionType.bluetooth) {
        bytes += generator.text('MAC: ${_currentPrinter!.bluetoothAddress}');
      } else if (_currentPrinter!.connectionType == PrinterConnectionType.network) {
        bytes += generator.text('IP: ${_currentPrinter!.ipAddress}:${_currentPrinter!.port}');
      }
      
      bytes += generator.text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      bytes += generator.text('━' * (_currentPrinter!.paperWidth == 58 ? 32 : 48));
      bytes += generator.text('Estado: CONECTADO ✓', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);
      bytes += generator.cut();

      return await _printBytes(bytes);
    } catch (e) {
      print('Error en test de impresión: $e');
      return false;
    }
  }

  // ============================================================================
  // CONSTRUCCIÓN DE TICKETS
  // ============================================================================

  Future<List<int>> _buildOrderReceipt({
    required String restaurantName,
    required String orderNumber,
    required DateTime orderDate,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    String? customerName,
    String? tableName,
    String? notes,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      _currentPrinter!.paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    
    final int lineWidth = _currentPrinter!.paperWidth == 58 ? 32 : 48;
    List<int> bytes = [];

    // Encabezado
    bytes += generator.text(
      restaurantName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text('━' * lineWidth);
    
    // Info de la orden
    bytes += generator.row([
      PosColumn(text: 'Orden:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: orderNumber, width: 8),
    ]);
    
    if (tableName != null) {
      bytes += generator.row([
        PosColumn(text: 'Mesa:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: tableName, width: 8),
      ]);
    }
    
    if (customerName != null) {
      bytes += generator.row([
        PosColumn(text: 'Cliente:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: customerName, width: 8),
      ]);
    }
    
    bytes += generator.text(DateFormat('dd/MM/yyyy HH:mm').format(orderDate));
    bytes += generator.text('━' * lineWidth);
    
    // Items
    bytes += generator.row([
      PosColumn(text: 'CANT', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'PRODUCTO', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'PRECIO', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.text('-' * lineWidth);
    
    for (var item in items) {
      final quantity = item['quantity'] ?? 1;
      final name = item['name'] ?? '';
      final price = item['price'] ?? 0.0;
      final modifiers = item['modifiers'] as List<dynamic>? ?? [];
      
      bytes += generator.row([
        PosColumn(text: '$quantity', width: 2),
        PosColumn(text: name, width: 6),
        PosColumn(
          text: '\$${price.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      
      // Modificadores
      for (var modifier in modifiers) {
        final modName = modifier['name'] ?? '';
        final modPrice = modifier['price'] ?? 0.0;
        bytes += generator.row([
          PosColumn(text: '', width: 2),
          PosColumn(text: '  + $modName', width: 6, styles: const PosStyles(fontSize: PosFontSize.font1)),
          PosColumn(
            text: modPrice > 0 ? '\$${modPrice.toStringAsFixed(2)}' : '',
            width: 4,
            styles: const PosStyles(align: PosAlign.right, fontSize: PosFontSize.font1),
          ),
        ]);
      }
    }
    
    bytes += generator.text('━' * lineWidth);
    
    // Totales
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '\$${subtotal.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Impuesto:', width: 8),
      PosColumn(
        text: '\$${tax.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    
    bytes += generator.text('━' * lineWidth);
    
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 8,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: '\$${total.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]);
    
    bytes += generator.text('━' * lineWidth);
    
    // Notas
    if (notes != null && notes.isNotEmpty) {
      bytes += generator.text(
        'Nota: $notes',
        styles: const PosStyles(fontSize: PosFontSize.font1),
      );
      bytes += generator.text('━' * lineWidth);
    }
    
    // Pie
    bytes += generator.text(
      '¡Gracias por su preferencia!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    
    bytes += generator.feed(2);
    bytes += generator.cut();
    
    return bytes;
  }

  Future<List<int>> _buildCashRegisterReport({
    required String terminalName,
    required DateTime openedAt,
    required DateTime closedAt,
    required double initialBalance,
    required double expectedBalance,
    required double actualBalance,
    required double difference,
    required int totalOrders,
    required Map<String, double> paymentMethodTotals,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      _currentPrinter!.paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    
    final int lineWidth = _currentPrinter!.paperWidth == 58 ? 32 : 48;
    List<int> bytes = [];

    // Encabezado
    bytes += generator.text(
      'CIERRE DE CAJA',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text('━' * lineWidth);
    
    // Info del terminal
    bytes += generator.text(
      'Terminal: $terminalName',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text('Apertura: ${DateFormat('dd/MM/yyyy HH:mm').format(openedAt)}');
    bytes += generator.text('Cierre: ${DateFormat('dd/MM/yyyy HH:mm').format(closedAt)}');
    bytes += generator.text('━' * lineWidth);
    
    // Resumen
    bytes += generator.text(
      'RESUMEN DE OPERACIONES',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text('-' * lineWidth);
    
    bytes += generator.row([
      PosColumn(text: 'Total órdenes:', width: 8),
      PosColumn(text: '$totalOrders', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    bytes += generator.text('━' * lineWidth);
    
    // Métodos de pago
    bytes += generator.text(
      'DESGLOSE POR MÉTODO',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text('-' * lineWidth);
    
    paymentMethodTotals.forEach((method, amount) {
      bytes += generator.row([
        PosColumn(text: method, width: 8),
        PosColumn(
          text: '\$${amount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    });
    
    bytes += generator.text('━' * lineWidth);
    
    // Balance
    bytes += generator.text(
      'BALANCE DE CAJA',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text('-' * lineWidth);
    
    bytes += generator.row([
      PosColumn(text: 'Saldo inicial:', width: 8),
      PosColumn(
        text: '\$${initialBalance.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Saldo esperado:', width: 8),
      PosColumn(
        text: '\$${expectedBalance.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Saldo real:', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '\$${actualBalance.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    
    bytes += generator.text('━' * lineWidth);
    
    // Diferencia
    final diffStyles = PosStyles(
      bold: true,
      align: PosAlign.right,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    );
    
    bytes += generator.row([
      PosColumn(
        text: 'DIFERENCIA:',
        width: 8,
        styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      ),
      PosColumn(
        text: '\$${difference.toStringAsFixed(2)}',
        width: 4,
        styles: diffStyles,
      ),
    ]);
    
    if (difference != 0) {
      bytes += generator.text(
        difference > 0 ? 'SOBRANTE' : 'FALTANTE',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    
    bytes += generator.text('━' * lineWidth);
    
    bytes += generator.feed(2);
    bytes += generator.cut();
    
    return bytes;
  }

  // ============================================================================
  // ENVÍO DE DATOS
  // ============================================================================

  /// Enviar bytes a la impresora (Bluetooth o Red)
  Future<bool> _printBytes(List<int> bytes) async {
    try {
      if (_currentPrinter!.connectionType == PrinterConnectionType.bluetooth) {
        return await PrintBluetoothThermal.writeBytes(bytes);
      } else if (_currentPrinter!.connectionType == PrinterConnectionType.network) {
        if (_networkPrinter == null) {
          throw Exception('Impresora de red no conectada');
        }
        
        // Para NetworkPrinter, los bytes ya fueron escritos durante la generación
        // Necesitamos reconstruir el ticket directamente en el NetworkPrinter
        return await _printToNetworkPrinter(bytes);
      }
      
      return false;
    } catch (e) {
      print('Error enviando bytes: $e');
      return false;
    }
  }

  /// Imprimir a impresora de red usando esc_pos_printer
  Future<bool> _printToNetworkPrinter(List<int> bytes) async {
    try {
      // NetworkPrinter requiere usar sus propios métodos
      // Los bytes ya están generados, solo enviamos
      await _networkPrinter!.rawBytes(Uint8List.fromList(bytes));
      _networkPrinter!.disconnect();
      
      // Reconectar para próxima impresión
      await _connectNetwork(
        _currentPrinter!.ipAddress!,
        _currentPrinter!.port!,
      );
      
      return true;
    } catch (e) {
      print('Error imprimiendo en red: $e');
      return false;
    }
  }

  // ============================================================================
  // PERSISTENCIA
  // ============================================================================

  Future<void> _saveLastPrinter() async {
    if (_currentPrinter == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final json = _currentPrinter!.toJson();
    await prefs.setString('last_printer', json.toString());
  }

  Future<PrinterConfig?> getLastPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('last_printer');
      if (json != null) {
        // Aquí deberías parsear el JSON correctamente
        // Por ahora retorna null, implementa según tus necesidades
        return null;
      }
    } catch (e) {
      print('Error obteniendo última impresora: $e');
    }
    return null;
  }
}
