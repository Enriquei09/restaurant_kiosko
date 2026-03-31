import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:restaurant_kiosco/presentation/screens/menu/menu_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kitchen/kitchen_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/cashier/cashier_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/splash_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/restaurant_selection_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/terminal_selection_screen.dart';
import 'package:restaurant_kiosco/providers/cart_model.dart';
import 'package:restaurant_kiosco/providers/payment_model.dart';
import 'package:restaurant_kiosco/providers/tip_model.dart';
import 'package:restaurant_kiosco/providers/restaurant_provider.dart';
import 'package:restaurant_kiosco/providers/table_provider.dart';
import 'package:restaurant_kiosco/providers/cash_register_provider.dart';
import 'package:restaurant_kiosco/providers/pos_provider.dart';
import 'package:restaurant_kiosco/providers/auth_provider.dart';
import 'package:restaurant_kiosco/presentation/screens/waiter/waiter_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/order_type_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/table_input_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/kiosk_table_selection_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/kiosk/kiosk_screen_wrapper.dart';
import 'package:restaurant_kiosco/presentation/screens/checkout/checkout_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/runner/runner_screen.dart';
import 'package:restaurant_kiosco/presentation/screens/auth/login_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Helper classes para verificación de roles
// ══════════════════════════════════════════════════════════════════════════════

/// Define una ruta protegida con roles permitidos
class _RoleRoute {
  final List<String> allowedRoles;
  final WidgetBuilder builder;

  const _RoleRoute({
    required this.allowedRoles,
    required this.builder,
  });
}

/// Guard que verifica autenticación y rol antes de mostrar la pantalla
class _RoleGuard extends StatelessWidget {
  final String routeName;
  final _RoleRoute roleRoute;

  const _RoleGuard({
    required this.routeName,
    required this.roleRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // No autenticado → redirigir a login
        if (!auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => route.settings.name == '/home',
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = auth.roleName.toLowerCase();

        // Verificar si tiene permiso para esta ruta
        final hasAccess = roleRoute.allowedRoles
            .any((role) => role.toLowerCase() == userRole);

        if (!hasAccess) {
          // Redirigir a su pantalla correcta según su rol
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _redirectToCorrectScreen(context, userRole);
          });
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Acceso denegado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu rol ($userRole) no tiene acceso a esta pantalla',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // Tiene acceso → limpiar historial y mostrar pantalla
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              routeName,
              (route) => false, // Limpiar todo el historial
            );
          }
        });

        return roleRoute.builder(context);
      },
    );
  }

  /// Redirige al usuario a su pantalla correcta según su rol
  void _redirectToCorrectScreen(BuildContext context, String role) {
    final route = switch (role) {
      'cashier' || 'cajero'       => '/cashier',
      'cook' || 'cocinero'        => '/kitchen',
      'bartender'                 => '/kitchen',
      'waiter' || 'mesero'        => '/waiter',
      'runner'                    => '/runner',
      _                           => '/home', // admin, manager, supervisor
    };

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (r) => false, // Limpiar historial
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartModel()..restore()),
        ChangeNotifierProvider(create: (_) => PaymentModel()),
        ChangeNotifierProvider(create: (_) => TipModel()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => CashRegisterProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Genera rutas con verificación de rol y limpieza de historial
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Rutas protegidas por rol con limpieza de historial
    final protectedRoutes = <String, _RoleRoute>{
      '/kitchen': _RoleRoute(
        allowedRoles: ['cook', 'bartender', 'admin', 'owner', 'manager', 'supervisor'],
        builder: (_) => const KitchenScreen(),
      ),
      '/cashier': _RoleRoute(
        allowedRoles: ['cashier', 'admin', 'owner', 'manager', 'supervisor'],
        builder: (_) => const CashierScreen(),
      ),
      '/terminal-selection': _RoleRoute(
        allowedRoles: ['cashier', 'admin', 'owner', 'manager', 'supervisor'],
        builder: (_) => const TerminalSelectionScreen(),
      ),
      '/waiter': _RoleRoute(
        allowedRoles: ['waiter', 'admin', 'owner', 'manager', 'supervisor'],
        builder: (_) => const WaiterScreen(),
      ),
      '/runner': _RoleRoute(
        allowedRoles: ['runner', 'admin', 'owner', 'manager', 'supervisor'],
        builder: (_) => const RunnerScreen(),
      ),
    };

    final routeName = settings.name;
    if (routeName == null || !protectedRoutes.containsKey(routeName)) {
      return null; // Dejar que MaterialApp maneje las rutas normales
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return _RoleGuard(
          routeName: routeName,
          roleRoute: protectedRoutes[routeName]!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: restaurantProvider.config.displayName.isNotEmpty
              ? restaurantProvider.config.displayName
              : 'THALO Kiosk',
          theme: restaurantProvider.themeData,
          home: const _AppGate(),
          onGenerateRoute: (settings) => _generateRoute(settings),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/restaurant-selection': (context) => const RestaurantSelectionScreen(),
            // Rutas públicas (kiosko cliente)
            '/menu': (context) => const KioskScreenWrapper(child: MenuScreen()),
            '/kiosk/order-type': (context) => const KioskScreenWrapper(child: OrderTypeScreen()),
            '/kiosk/table-input': (context) => const KioskScreenWrapper(child: TableInputScreen()),
            '/kiosk/table-selection': (context) => const KioskScreenWrapper(child: KioskTableSelectionScreen()),
            '/checkout': (context) => const CheckoutScreen(),
          },
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final brandColor = restaurantProvider.primaryColor;
    final restaurantName = restaurantProvider.config.displayName.isNotEmpty
        ? restaurantProvider.config.displayName
        : 'Sistema POS - Restaurante';

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        actions: [
          if (auth.isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${auth.userName} (${auth.roleName})',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Selecciona tu Rol',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                  // KIOSKO — siempre visible (acceso público para clientes)
                  _buildOptionCard(
                    context,
                    title: 'KIOSKO',
                    subtitle: 'Cliente',
                    icon: Icons.touch_app,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/kiosk/order-type'),
                  ),

                  // MESERO — requiere login + can_take_orders
                  _buildOptionCard(
                    context,
                    title: 'MESERO',
                    subtitle: 'Mesas',
                    icon: Icons.table_restaurant,
                    color: Colors.orange.shade800,
                    onTap: () => _navigateWithAuth(
                      context,
                      route: '/waiter',
                      requiredPermission: 'can_take_orders',
                      roleName: 'Mesero',
                    ),
                  ),

                  // COCINA — requiere login con rol cook/bar/admin
                  _buildOptionCard(
                    context,
                    title: 'COCINA',
                    subtitle: 'Pedidos',
                    icon: Icons.kitchen,
                    color: Colors.orange,
                    onTap: () => _navigateWithAuth(
                      context,
                      route: '/kitchen',
                      requiredRoles: ['admin', 'supervisor', 'cook', 'bar'],
                      roleName: 'Cocina',
                    ),
                  ),

                  // CAJA — requiere login + can_open_cash_register
                  _buildOptionCard(
                    context,
                    title: 'CAJA',
                    subtitle: 'Cobro',
                    icon: Icons.point_of_sale,
                    color: Colors.green,
                    onTap: () => _navigateWithAuth(
                      context,
                      route: '/terminal-selection',
                      requiredPermission: 'can_open_cash_register',
                      roleName: 'Cajero',
                    ),
                  ),

                  // ENTREGAR — requiere login
                  _buildOptionCard(
                    context,
                    title: 'ENTREGAR',
                    subtitle: 'Runner',
                    icon: Icons.delivery_dining,
                    color: Colors.teal,
                    onTap: () => _navigateWithAuth(
                      context,
                      route: '/runner',
                      roleName: 'Runner',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180, // Slightly smaller to fit 4
        height: 220,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navegar a una pantalla protegida.
  /// Si no está autenticado, redirige a login.
  /// Si está autenticado pero no tiene permiso, muestra error.
  void _navigateWithAuth(
    BuildContext context, {
    required String route,
    String? requiredPermission,
    List<String>? requiredRoles,
    required String roleName,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!auth.isAuthenticated) {
      // Ir a login y luego redirigir a la ruta solicitada
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            redirectRoute: route,
            requiredPermission: requiredPermission,
            requiredRoles: requiredRoles,
            roleName: roleName,
          ),
        ),
      );
      return;
    }

    // Ya autenticado — verificar permisos
    if (requiredPermission != null && !auth.hasPermission(requiredPermission)) {
      _showPermissionError(context, roleName);
      return;
    }

    if (requiredRoles != null && !auth.hasRole(requiredRoles)) {
      _showPermissionError(context, roleName);
      return;
    }

    // Actualizar userId, restaurantId y tenantId en PosProvider
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    posProvider.setUserId(auth.user!.id);
    
    // Sincronizar restaurantId del RestaurantProvider al PosProvider
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (restaurantProvider.currentRestaurantId != null) {
      posProvider.setRestaurantId(restaurantProvider.currentRestaurantId!);
    }
    if (restaurantProvider.currentTenantId != null) {
      posProvider.setTenantId(restaurantProvider.currentTenantId!);
    }

    Navigator.pushNamed(context, route);
  }

  void _showPermissionError(BuildContext context, String roleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tu rol no tiene acceso a $roleName'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppGate — enrutador reactivo principal
//
// 1. Inicializa el restaurante y restaura la sesión de auth en paralelo.
// 2. Muestra SplashScreen mientras carga.
// 3. Escucha AuthProvider y, si el usuario está autenticado,
//    redirige automáticamente según el rol con un switch.
// ─────────────────────────────────────────────────────────────────────────────
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartModel    = Provider.of<CartModel>(context, listen: false);
    final posProvider  = Provider.of<PosProvider>(context, listen: false);

    // Inicializar restaurante y sesion de auth en paralelo
    await Future.wait([
      restaurantProvider.initialize(),
      authProvider.restoreSession(),
    ]);

    // Breve pausa para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Configurar cart y POS si hay restaurante seleccionado
    if (restaurantProvider.hasSelection) {
      cartModel.setRestaurantId(restaurantProvider.currentRestaurantId!);
      cartModel.setTaxRate(restaurantProvider.config.taxRate);

      posProvider.setRestaurantId(restaurantProvider.currentRestaurantId!);
      if (restaurantProvider.currentTenantId != null) {
        posProvider.setTenantId(restaurantProvider.currentTenantId!);
      }
      if (authProvider.isAuthenticated && authProvider.user != null) {
        posProvider.setUserId(authProvider.user!.id);
      }
    }

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    // Mientras inicializa, mostrar splash
    if (!_ready) return const SplashScreen();

    final restaurantProvider = context.watch<RestaurantProvider>();

    // Sin restaurante configurado → pantalla de seleccion
    if (!restaurantProvider.hasSelection) {
      return const RestaurantSelectionScreen();
    }

    // Con restaurante → escuchar AuthProvider y redirigir por rol
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // No autenticado → pantalla de selección de modulo
        if (!auth.isAuthenticated) return const HomeScreen();

        // Autenticado → switch por rol
        return switch (auth.roleName.toLowerCase()) {
          'cashier'                    => const CashierScreen(),
          'cook' || 'bartender'        => const KitchenScreen(),
          'waiter'                     => const WaiterScreen(),
          'runner'                     => const RunnerScreen(),
          'kiosk'                      => const KioskScreenWrapper(
                                           child: MenuScreen()),
          _                            => const HomeScreen(),
          // admin, owner, manager, supervisor → pantalla de seleccion
        };
      },
    );
  }
}
