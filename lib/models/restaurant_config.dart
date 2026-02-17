import 'package:flutter/material.dart';

/// Modelo de configuración del restaurante.
/// Cargado desde /api/restaurants/{id}/settings al seleccionar restaurante.
class RestaurantConfig {
  final int restaurantId;
  final String restaurantName;
  final String? restaurantCode;
  final String? businessName;
  final String? logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String currency;
  final String currencySymbol;
  final String timezone;
  final double taxRate;
  final bool taxIncluded;
  final double defaultTipPercentage;
  final List<int> tipOptions;
  final bool tipsEnabled;
  final bool kioskEnabled;
  final bool tableServiceEnabled;
  final bool takeoutEnabled;
  final bool deliveryEnabled;
  final Map<String, String>? operatingHours;
  final List<String> enabledPaymentMethods;
  final String? receiptHeader;
  final String? receiptFooter;

  const RestaurantConfig({
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantCode,
    this.businessName,
    this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.currency,
    required this.currencySymbol,
    required this.timezone,
    required this.taxRate,
    required this.taxIncluded,
    required this.defaultTipPercentage,
    required this.tipOptions,
    required this.tipsEnabled,
    required this.kioskEnabled,
    required this.tableServiceEnabled,
    required this.takeoutEnabled,
    required this.deliveryEnabled,
    this.operatingHours,
    required this.enabledPaymentMethods,
    this.receiptHeader,
    this.receiptFooter,
  });

  /// Nombre a mostrar (business_name > restaurant_name).
  String get displayName => businessName ?? restaurantName;

  /// Defaults para cuando no hay config cargada.
  static RestaurantConfig defaults() {
    return const RestaurantConfig(
      restaurantId: 0,
      restaurantName: 'THALO',
      primaryColor: Color(0xFF3d5a80),
      secondaryColor: Color(0xFFee6c4d),
      accentColor: Color(0xFF98c1d9),
      currency: 'MXN',
      currencySymbol: '\$',
      timezone: 'America/Mexico_City',
      taxRate: 16.0,
      taxIncluded: true,
      defaultTipPercentage: 10.0,
      tipOptions: [10, 15, 20],
      tipsEnabled: true,
      kioskEnabled: true,
      tableServiceEnabled: true,
      takeoutEnabled: true,
      deliveryEnabled: false,
      enabledPaymentMethods: ['cash', 'card'],
    );
  }

  /// Parsear color hex (#3d5a80) a Color de Flutter.
  static Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final hexStr = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexStr', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  factory RestaurantConfig.fromJson(Map<String, dynamic> json) {
    return RestaurantConfig(
      restaurantId: json['restaurant_id'] ?? 0,
      restaurantName: json['restaurant_name'] ?? 'Restaurant',
      restaurantCode: json['restaurant_code'],
      businessName: json['business_name'],
      logoUrl: json['logo_url'],
      primaryColor: _parseColor(
        json['primary_color'],
        const Color(0xFF3d5a80),
      ),
      secondaryColor: _parseColor(
        json['secondary_color'],
        const Color(0xFFee6c4d),
      ),
      accentColor: _parseColor(
        json['accent_color'],
        const Color(0xFF98c1d9),
      ),
      currency: json['currency'] ?? 'MXN',
      currencySymbol: json['currency_symbol'] ?? '\$',
      timezone: json['timezone'] ?? 'America/Mexico_City',
      taxRate: (json['tax_rate'] ?? 16.0).toDouble(),
      taxIncluded: json['tax_included'] ?? true,
      defaultTipPercentage: (json['default_tip_percentage'] ?? 10.0).toDouble(),
      tipOptions: (json['tip_options'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [10, 15, 20],
      tipsEnabled: json['tips_enabled'] ?? true,
      kioskEnabled: json['kiosk_enabled'] ?? true,
      tableServiceEnabled: json['table_service_enabled'] ?? true,
      takeoutEnabled: json['takeout_enabled'] ?? true,
      deliveryEnabled: json['delivery_enabled'] ?? false,
      operatingHours: json['operating_hours'] != null
          ? Map<String, String>.from(json['operating_hours'])
          : null,
      enabledPaymentMethods: (json['enabled_payment_methods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['cash', 'card'],
      receiptHeader: json['receipt_header'],
      receiptFooter: json['receipt_footer'],
    );
  }

  /// Generar ThemeData a partir de los colores del restaurante.
  ThemeData toThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Formatear precio con moneda.
  String formatPrice(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
}
