import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';

/// Servicio de impresión para tickets térmicos
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  bool _isConnected = false;
  String? _connectedPrinterAddress;

  /// Obtener impresoras Bluetooth disponibles
  Future<List<BluetoothInfo>> getAvailablePrinters() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      print('Error obteniendo impresoras: $e');
      return [];
    }
  }

  /// Conectar a una impresora por su dirección MAC
  Future<bool> connectToPrinter(String macAddress) async {
    try {
      final result = await PrintBluetoothThermal.connect(macAddress: macAddress);
      if (result) {
        _isConnected = true;
        _connectedPrinterAddress = macAddress;
      }
      return result;
    } catch (e) {
      print('Error conectando a impresora: $e');
      return false;
    }
  }

  /// Desconectar impresora
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _isConnected = false;
      _connectedPrinterAddress = null;
    } catch (e) {
      print('Error desconectando impresora: $e');
    }
  }

  /// Verificar si está conectado
  bool get isConnected => _isConnected;

  /// Imprimir ticket de orden (recibo para cliente)
  Future<bool> printOrderReceipt({
    required String restaurantName,
    required String restaurantAddress,
    required String restaurantPhone,
    required String orderNumber,
    required DateTime orderDate,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double tip,
    required double total,
    required String paymentMethod,
    String? cashierName,
    String? tableName,
  }) async {
    if (!_isConnected) {
      print('Impresora no conectada');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Encabezado del restaurante
      bytes += generator.text(
        restaurantName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      bytes += generator.text(
        restaurantAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Tel: $restaurantPhone',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.hr(ch: '=');

      // Información de la orden
      bytes += generator.text(
        'ORDEN #$orderNumber',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      );
      bytes += generator.text(
        DateFormat('dd/MM/yyyy HH:mm').format(orderDate),
        styles: const PosStyles(align: PosAlign.center),
      );
      
      if (cashierName != null) {
        bytes += generator.text('Cajero: $cashierName');
      }
      if (tableName != null) {
        bytes += generator.text('Mesa: $tableName');
      }
      
      bytes += generator.hr(ch: '-');

      // Items de la orden
      bytes += generator.text(
        'DETALLE DE CONSUMO',
        styles: const PosStyles(bold: true),
      );
      bytes += generator.emptyLines(1);

      for (var item in items) {
        String name = item['name'] ?? '';
        int quantity = item['quantity'] ?? 1;
        double price = (item['price'] ?? 0.0).toDouble();
        double itemTotal = quantity * price;

        // Nombre del producto
        bytes += generator.text(
          name,
          styles: const PosStyles(bold: true),
        );

        // Cantidad x Precio = Total
        String line = '  $quantity x \$${price.toStringAsFixed(2)} = \$${itemTotal.toStringAsFixed(2)}';
        bytes += generator.text(line);

        // Modificadores si existen
        if (item['modifiers'] != null && item['modifiers'].isNotEmpty) {
          for (var mod in item['modifiers']) {
            String modName = mod['name'] ?? '';
            double modPrice = (mod['price'] ?? 0.0).toDouble();
            if (modPrice > 0) {
              bytes += generator.text('    + $modName (\$${modPrice.toStringAsFixed(2)})');
            } else {
              bytes += generator.text('    + $modName');
            }
          }
        }

        // Notas especiales
        if (item['notes'] != null && item['notes'].isNotEmpty) {
          bytes += generator.text(
            '    Nota: ${item['notes']}',
            styles: const PosStyles(italic: true),
          );
        }

        bytes += generator.emptyLines(1);
      }

      bytes += generator.hr(ch: '-');

      // Totales
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 8, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: '\$${subtotal.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (tax > 0) {
        bytes += generator.row([
          PosColumn(text: 'Impuestos:', width: 8, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: '\$${tax.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      if (tip > 0) {
        bytes += generator.row([
          PosColumn(text: 'Propina:', width: 8, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: '\$${tip.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr(ch: '=');
      
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
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

      bytes += generator.hr(ch: '=');

      // Método de pago
      bytes += generator.text(
        'Método de pago: $paymentMethod',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      bytes += generator.emptyLines(2);

      // Pie de página
      bytes += generator.text(
        '¡Gracias por su visita!',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Vuelva pronto',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.emptyLines(2);

      // QR Code (opcional - si tienes URL de seguimiento)
      // bytes += generator.qrcode('https://ejemplo.com/orden/$orderNumber');

      bytes += generator.cut();

      // Enviar a la impresora
      await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
      return true;
    } catch (e) {
      print('Error imprimiendo ticket: $e');
      return false;
    }
  }

  /// Imprimir ticket de cierre de caja
  Future<bool> printCashRegisterReport({
    required String restaurantName,
    required String cashierName,
    required DateTime openedAt,
    required DateTime closedAt,
    required double openingBalance,
    required double expectedBalance,
    required double actualBalance,
    required double difference,
    required Map<String, dynamic> salesSummary,
  }) async {
    if (!_isConnected) {
      print('Impresora no conectada');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Encabezado
      bytes += generator.text(
        restaurantName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'REPORTE DE CIERRE DE CAJA',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      );
      bytes += generator.hr(ch: '=');

      // Información del cajero y fechas
      bytes += generator.text('Cajero: $cashierName');
      bytes += generator.text('Apertura: ${DateFormat('dd/MM/yyyy HH:mm').format(openedAt)}');
      bytes += generator.text('Cierre: ${DateFormat('dd/MM/yyyy HH:mm').format(closedAt)}');
      bytes += generator.hr(ch: '-');

      // Balance de caja
      bytes += generator.text(
        'BALANCE DE CAJA',
        styles: const PosStyles(bold: true),
      );
      bytes += generator.row([
        PosColumn(text: 'Fondo inicial:', width: 8),
        PosColumn(text: '\$${openingBalance.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Balance esperado:', width: 8),
        PosColumn(text: '\$${expectedBalance.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Balance real:', width: 8),
        PosColumn(text: '\$${actualBalance.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr(ch: '-');
      
      bytes += generator.row([
        PosColumn(
          text: 'Diferencia:',
          width: 8,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '\$${difference.toStringAsFixed(2)}',
          width: 4,
          styles: PosStyles(
            align: PosAlign.right,
            bold: true,
            reverse: difference != 0,
          ),
        ),
      ]);

      bytes += generator.hr(ch: '-');

      // Resumen de ventas
      bytes += generator.text(
        'RESUMEN DE VENTAS',
        styles: const PosStyles(bold: true),
      );
      
      if (salesSummary['total_orders'] != null) {
        bytes += generator.text('Total órdenes: ${salesSummary['total_orders']}');
      }
      if (salesSummary['cash_sales'] != null) {
        bytes += generator.row([
          PosColumn(text: 'Ventas efectivo:', width: 8),
          PosColumn(text: '\$${salesSummary['cash_sales'].toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      if (salesSummary['card_sales'] != null) {
        bytes += generator.row([
          PosColumn(text: 'Ventas tarjeta:', width: 8),
          PosColumn(text: '\$${salesSummary['card_sales'].toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      if (salesSummary['tips'] != null && salesSummary['tips'] > 0) {
        bytes += generator.row([
          PosColumn(text: 'Propinas:', width: 8),
          PosColumn(text: '\$${salesSummary['tips'].toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr(ch: '=');
      bytes += generator.emptyLines(3);
      
      // Firmas
      bytes += generator.text('_______________________', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Firma Cajero', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(2);
      bytes += generator.text('_______________________', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Firma Supervisor', styles: const PosStyles(align: PosAlign.center));

      bytes += generator.emptyLines(3);
      bytes += generator.cut();

      // Enviar a la impresora
      await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
      return true;
    } catch (e) {
      print('Error imprimiendo reporte de caja: $e');
      return false;
    }
  }

  /// Test de impresión
  Future<bool> printTest() async {
    if (!_isConnected) {
      print('Impresora no conectada');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text(
        'TEST DE IMPRESIÓN',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.text('Esta es una prueba de impresión',
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(2);
      bytes += generator.text('¡Impresora configurada correctamente!',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
      return true;
    } catch (e) {
      print('Error en test de impresión: $e');
      return false;
    }
  }
}
