# 🍽️ Restaurant Kiosko - THALO Frontend

Aplicación Flutter multi-plataforma para el sistema de kioscos THALO. Incluye módulos de Kiosko, Caja, Cocina y Mesero.

---

## 📋 Requisitos

- Flutter SDK 3.x o superior
- Dart SDK 3.x o superior
- Android Studio / Xcode (para apps móviles)
- Chrome (para desarrollo web)

---

## 🚀 Instalación y Configuración

### 1. Verificar Instalación de Flutter
```bash
flutter doctor
```
Asegúrate de que no haya errores críticos.

### 2. Instalar Dependencias
```bash
cd restaurant_kiosko
flutter pub get
```

### 3. Configurar Conexión al Backend

**Archivo**: `lib/constants.dart`

```dart
// URL del backend
const String baseUrl = 'http://localhost:8000';  // Desarrollo local
// const String baseUrl = 'http://10.0.2.2:8000';  // Android Emulator
// const String baseUrl = 'https://api.thalo.com';  // Producción

// Configuración por defecto
const int defaultTenantId = 1;
const int defaultRestaurantId = 1;
```

**Importante**: 
- Para desarrollo en Chrome: `http://localhost:8000`
- Para Android Emulator: `http://10.0.2.2:8000`
- Para dispositivos físicos: IP de tu máquina (ej: `http://192.168.1.100:8000`)

### 4. Ejecutar la Aplicación

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en Chrome (recomendado para desarrollo)
flutter run -d chrome

# Ejecutar en dispositivo específico
flutter run -d <device-id>

# Modo release (más rápido)
flutter run --release
```

---

## 🗂️ Estructura del Proyecto

```
lib/
├── main.dart                    # Entry point de la aplicación
├── constants.dart               # Configuración y URLs
│
├── models/                      # Modelos de datos
│   ├── cart_item.dart
│   ├── cash_register.dart
│   ├── kitchen_order.dart
│   ├── product.dart
│   └── table_model.dart
│
├── providers/                   # Gestión de estado (Provider)
│   ├── cart_model.dart          # Carrito de compras
│   ├── payment_model.dart       # Métodos de pago
│   ├── pos_provider.dart        # Sesión POS (usuario, caja, terminal)
│   └── table_provider.dart      # Gestión de mesas
│
├── service/                     # Servicios API
│   ├── api_service.dart         # Comunicación con backend
│   ├── configuration_service.dart
│   └── polling_service.dart     # Actualización en tiempo real
│
├── presentation/                # UI
│   ├── screens/                 # Pantallas principales
│   │   ├── terminal/
│   │   │   ├── terminal_selection_screen.dart
│   │   │   └── pin_entry_screen.dart
│   │   ├── cash_register_screen.dart  # Gestión de caja
│   │   ├── cashier/
│   │   │   └── cashier_screen.dart    # Cobro de órdenes
│   │   ├── kitchen/
│   │   │   └── kitchen_screen.dart    # Pantalla de cocina
│   │   ├── waiter/
│   │   │   └── waiter_screen.dart     # Pantalla de mesero
│   │   └── kiosk/
│   │       └── ...                    # Kiosko de autoservicio
│   │
│   └── widgets/                 # Widgets reutilizables
│       ├── discount_dialog.dart
│       ├── products_selected.dart
│       └── checkout/
│
└── utils/                       # Utilidades
    └── constants.dart
```

---

## 🎯 Módulos de la Aplicación

### 1. Selección de Terminal
**Pantalla**: `terminal_selection_screen.dart`
- Muestra terminales disponibles del restaurante
- Selección de terminal POS

### 2. Autenticación PIN
**Pantalla**: `pin_entry_screen.dart`
- Ingreso de PIN (4-6 dígitos)
- Autenticación con el backend
- Recuperación de caja abierta si existe

### 3. Caja Registradora
**Pantalla**: `cash_register_screen.dart`
- Apertura de caja con monto inicial
- Registro de transacciones
- Cierre de caja con arqueo

### 4. Cajero (Pagos)
**Pantalla**: `cashier_screen.dart`
- Lista de órdenes pendientes de pago
- Procesamiento de pagos (efectivo, tarjeta, QR)
- División de pagos múltiples
- Aplicación de descuentos
- Reembolsos

### 5. Cocina
**Pantalla**: `kitchen_screen.dart`
- Órdenes nuevas en tiempo real
- Cambio de estado (preparando → lista)
- Tabs por área (Cocina / Bar)

### 6. Mesero
**Pantalla**: `waiter_screen.dart`
- Gestión de mesas
- Toma de órdenes
- Visualización de pedidos por mesa

---

## 🔧 Providers (Gestión de Estado)

### PosProvider
Gestiona la sesión del usuario en el sistema POS:
```dart
// Acceso a datos de sesión
final posProvider = Provider.of<PosProvider>(context);

int userId = posProvider.userId;
int restaurantId = posProvider.restaurantId;
CashRegister? currentCashRegister = posProvider.currentCashRegister;
CashRegisterTerminal? terminal = posProvider.selectedTerminal;
```

**Métodos importantes:**
- `setUserId(int id)`
- `setCurrentCashRegister(CashRegister register)`
- `clearSession()` - Cierra sesión
- `getSessionData()` - Retorna Map con todos los datos

### CartModel
Gestiona el carrito de compras:
```dart
final cart = Provider.of<CartModel>(context);

// Agregar producto
cart.addItem(product, quantity);

// Totales
double subtotal = cart.subtotal;
double tax = cart.tax;
double total = cart.total;
```

### PaymentModel
Gestiona métodos de pago y propinas:
```dart
final payment = Provider.of<PaymentModel>(context);

payment.setPaymentMethod('Efectivo');
payment.setTipPercentage(10);
```

---

## 🌐 Servicios API

### ApiService
Comunicación con el backend Laravel.

**Métodos principales:**

```dart
// Órdenes
Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData)
Future<List<KitchenOrder>> getKitchenOrders(int restaurantId)
Future<List<KitchenOrder>> getPendingPaymentOrders(int restaurantId)
Future<bool> updateOrderStatus(int orderId, String status)

// Caja Registradora
Future<Map<String, dynamic>> openCashRegister(Map<String, dynamic> data)
Future<Map<String, dynamic>> closeCashRegister(int registerId, Map<String, dynamic> data)
Future<Map<String, dynamic>> getCurrentCashRegister(int restaurantId, int userId)

// Terminales
Future<List<CashRegisterTerminal>> getTerminals(int restaurantId)
Future<Map<String, dynamic>> authenticateByPin(Map<String, dynamic> data)

// Pagos
Future<Map<String, dynamic>> processPayment(int orderId, Map<String, dynamic> paymentData)
```

---

## 🐛 Solución de Problemas

### Error: "No se puede conectar al servidor"
1. Verificar que el backend esté corriendo: `php artisan serve`
2. Revisar URL en `lib/constants.dart`
3. Para Android Emulator usar `http://10.0.2.2:8000`
4. Para dispositivo físico, usar IP local (ej: `192.168.1.100:8000`)

### Error: "Bad state: No element"
- Generalmente indica que no hay datos retornados por la API
- Verificar que los seeders del backend estén ejecutados
- Revisar logs del backend: `storage/logs/laravel.log`

### Pantalla en blanco o error de "Provider not found"
- Asegurarse de que todos los Providers estén inicializados en `main.dart`
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PosProvider()),
    ChangeNotifierProvider(create: (_) => CartModel()),
    ChangeNotifierProvider(create: (_) => PaymentModel()),
    // ... otros providers
  ],
  child: MyApp(),
)
```

### Errores de compilación
```bash
# Limpiar caché
flutter clean
flutter pub get

# Actualizar dependencias
flutter pub upgrade

# Analizar errores
flutter analyze
```

---

## 🧪 Testing

```bash
# Ejecutar todos los tests
flutter test

# Tests con coverage
flutter test --coverage

# Test de un archivo específico
flutter test test/widget_test.dart
```

---

## 📦 Build para Producción

### Android APK
```bash
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
# Salida en: build/web/
```

---

## 📝 Notas para Desarrollo

### TODOs Actuales (5 Feb 2026)
- ⏳ Reemplazar roles hardcodeados por valores reales de autenticación
- ⏳ Implementar flujo diferenciado según rol de usuario
- ⏳ Reemplazar IDs hardcodeados (userId: 1, cashRegisterId: 1)
- ⏳ Integrar restaurantId dinámico desde configuración

Ver `../kiosk-system/NEXT_STEPS.md` para tareas completas.

### Dependencias Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0           # Gestión de estado
  http: ^1.1.0               # Peticiones HTTP
  intl: ^0.18.0              # Formateo de fechas
  shared_preferences: ^2.0.0 # Persistencia local
```

---

## 🤝 Equipo de Desarrollo

Para dudas o cambios:
1. Revisar backend: `../kiosk-system/README.md`
2. Consultar tareas pendientes: `../kiosk-system/NEXT_STEPS.md`
3. Documentación API: `../kiosk-system/docs/`

---

## 📄 Licencia

Proyecto privado - THALO © 2026
