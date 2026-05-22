import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_kiosco/models/table_model.dart';
import 'package:restaurant_kiosco/providers/auth_provider.dart';
import 'package:restaurant_kiosco/providers/table_provider.dart';
import 'package:restaurant_kiosco/service/configuration_service.dart';
import '../table_detail_screen.dart';

// ── Colores de marca ─────────────────────────────────────────────────────────
const Color _kPink    = Color(0xFFE91E63); // Rosa Mexicano
const Color _kThalo   = Color(0xFF0056D2); // Azul Thalo (cuenta pedida)
const Color _kOrange  = Color(0xFFFF9800); // Naranja (bloqueada por otro)
const Color _kDark    = Color(0xFF0D0D0D);
const Color _kSub     = Color(0xFF757575);

/// Enum local de estado de mesa (refleja los estados del API)
enum TableStatus { available, occupied, billPrinted, lockedByOther, other }

extension _StatusExt on RestaurantTable {
  TableStatus get uiStatus {
    if (isLockedByOther) return TableStatus.lockedByOther;
    switch (status.toLowerCase()) {
      case 'available':    return TableStatus.available;
      case 'occupied':     return TableStatus.occupied;
      case 'bill_printed': return TableStatus.billPrinted;
      default:             return TableStatus.other;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class TableMapScreen extends StatefulWidget {
  const TableMapScreen({super.key});

  @override
  State<TableMapScreen> createState() => _TableMapScreenState();
}

class _TableMapScreenState extends State<TableMapScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final restaurantId = await ConfigurationService.getRestaurantId();
    if (mounted) {
      Provider.of<TableProvider>(context, listen: false)
          .fetchTables(restaurantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final waiter = auth.userName.isNotEmpty ? auth.userName : 'Mesero';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Consumer<TableProvider>(
          builder: (context, tp, _) {
            return RefreshIndicator(
              color: _kPink,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── Header ────────────────────────────────────────────────
                  SliverToBoxAdapter(child: _Header(waiterName: waiter)),

                  // ── Barra de estados ──────────────────────────────────────
                  if (!tp.isLoading && tp.error == null && tp.tables.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _StatusBar(tables: tp.tables),
                    ),

                  // ── Contenido principal ───────────────────────────────────
                  if (tp.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: _kPink),
                      ),
                    )
                  else if (tp.error != null)
                    SliverFillRemaining(child: _ErrorView(message: tp.error!, onRetry: _load))
                  else if (tp.tables.isEmpty)
                    const SliverFillRemaining(child: _EmptyView())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _TableCard(
                            table: tp.tables[i],
                            onTap: () => _onTableTap(tp.tables[i]),
                          ),
                          childCount: tp.tables.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _onTableTap(RestaurantTable table) {
    switch (table.uiStatus) {
      // ── 1. Bloqueada por otro mesero ──────────────────────────────────────
      case TableStatus.lockedByOther:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Esta mesa está siendo editada por otro compañero',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: _kOrange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;

      // ── 2. Mesa libre: llamar /open y luego navegar al menú ───────────────
      case TableStatus.available:
        _openTableDialog(table);
        break;

      // ── 3. Mesa ocupada y libre de lock: abrir detalle + auto-lock ────────
      case TableStatus.occupied:
        _navigateToDetail(table);
        break;

      // ── 4. Cuenta impresa: solo ver resumen, sin agregar productos ────────
      case TableStatus.billPrinted:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TableDetailScreen(
              tableId: table.id,
              tableName: table.name,
              isBillPrinted: true,
            ),
          ),
        ).then((_) => _load());
        break;

      case TableStatus.other:
        break;
    }
  }

  /// Navega al detalle de la mesa, dispara /lock al entrar y /release-lock al salir.
  Future<void> _navigateToDetail(RestaurantTable table) async {
    final tp = Provider.of<TableProvider>(context, listen: false);

    // Intentar adquirir el lock antes de navegar
    try {
      await tp.lockTable(table.id);
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      
      // Si el error es por bloqueo concurrente, mostrar diálogo modal
      if (msg.toLowerCase().contains('otro mesero') || msg.toLowerCase().contains('locked')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.lock_rounded, color: _kOrange, size: 28),
            title: const Text('Mesa Ocupada'),
            content: const Text('Mesa ocupada por otro mesero en este momento'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        // Otros errores: mostrar SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TableDetailScreen(
          tableId: table.id,
          tableName: table.name,
          isBillPrinted: false,
        ),
      ),
    );

    // Al regresar al mapa, liberar el lock
    if (mounted) {
      await tp.releaseLock(table.id);
      _load();
    }
  }

  // ── Mesa Libre: preguntar comensales y abrir menú ─────────────────────────
  Future<void> _openTableDialog(RestaurantTable table) async {
    int guests = 1;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¿Cuántos comensales?',
                    style: TextStyle(fontSize: 14, color: _kSub, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: guests > 1
                        ? () => setLocal(() => guests--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: _kPink,
                    iconSize: 32,
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      '$guests',
                      key: ValueKey(guests),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: _kDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: guests < (table.capacity > 0 ? table.capacity : 20)
                        ? () => setLocal(() => guests++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: _kPink,
                    iconSize: 32,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(ctx2, true),
                    child: Text(
                      'Iniciar pedido ($guests pax)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Llamar /open: crea la orden y pinta la mesa de rosa al instante
    final tp = Provider.of<TableProvider>(context, listen: false);
    try {
      await tp.openTable(table.id);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Navegar al detalle (con lock automático) en lugar del menú
    await _navigateToDetail(table.copyWith(status: 'occupied'));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.waiterName});
  final String waiterName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          // Logo / branding
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _kPink,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sabores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kDark,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Mapa de mesas',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          // Chip del mesero
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _kPink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded, color: _kPink, size: 16),
                const SizedBox(width: 5),
                Text(
                  waiterName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de resumen de estados
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.tables});
  final List<RestaurantTable> tables;

  @override
  Widget build(BuildContext context) {
    final free  = tables.where((t) => t.uiStatus == TableStatus.available).length;
    final occ   = tables.where((t) => t.uiStatus == TableStatus.occupied).length;
    final bill  = tables.where((t) => t.uiStatus == TableStatus.billPrinted).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _StatusPill(count: free,  label: 'Libres',  color: Colors.green.shade600),
          const SizedBox(width: 8),
          _StatusPill(count: occ,   label: 'Ocupadas', color: _kPink),
          const SizedBox(width: 8),
          _StatusPill(count: bill,  label: 'Cuenta',  color: _kThalo),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TableCard
// ─────────────────────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  const _TableCard({required this.table, required this.onTap});
  final RestaurantTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uiStatus = table.uiStatus;

    // ── Paleta según estado ──────────────────────────────────
    final Color bgColor;
    final Color textColor;
    final Color subColor;
    final Color iconColor;
    final IconData icon;
    final String statusLabel;
    final bool isDisabled; // bloqueada por otro mesero

    switch (uiStatus) {
      case TableStatus.available:
        bgColor     = Colors.grey[100]!;
        textColor   = _kDark;
        subColor    = Colors.grey[500]!;
        iconColor   = Colors.grey[400]!;
        icon        = Icons.table_restaurant_outlined;
        statusLabel = 'Libre';
        isDisabled  = false;
      case TableStatus.occupied:
        bgColor     = _kPink;
        textColor   = Colors.white;
        subColor    = Colors.white.withValues(alpha: 0.75);
        iconColor   = Colors.white.withValues(alpha: 0.6);
        icon        = Icons.people_rounded;
        statusLabel = 'Ocupada';
        isDisabled  = false;
      case TableStatus.billPrinted:
        bgColor     = _kThalo;
        textColor   = Colors.white;
        subColor    = Colors.white.withValues(alpha: 0.75);
        iconColor   = Colors.white.withValues(alpha: 0.6);
        icon        = Icons.receipt_rounded;
        statusLabel = 'En Cuenta';
        isDisabled  = false;
      // ── Bloqueada por otro mesero ──────────────────────────
      case TableStatus.lockedByOther:
        bgColor     = _kOrange;
        textColor   = Colors.white;
        subColor    = Colors.white.withValues(alpha: 0.75);
        iconColor   = Colors.white.withValues(alpha: 0.6);
        icon        = Icons.lock_rounded;
        statusLabel = 'En uso';
        isDisabled  = true; // tap deshabilitado visualmente
      case TableStatus.other:
        bgColor     = Colors.grey[200]!;
        textColor   = _kSub;
        subColor    = _kSub;
        iconColor   = _kSub;
        icon        = Icons.help_outline_rounded;
        statusLabel = table.status;
        isDisabled  = false;
    }

    // Las mesas bloqueadas por otro se muestran opacas al 60 %
    return Opacity(
      opacity: isDisabled ? 0.60 : 1.0,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          // onTap null deshabilita el toque nativo, pero igual llamamos
          // al callback para mostrar el SnackBar (ver _onTableTap)
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: isDisabled
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.15),
          highlightColor: isDisabled
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono
                Icon(icon, size: 26, color: iconColor),
                const SizedBox(height: 8),

                // Número / nombre de mesa
                Text(
                  table.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),

                // Etiqueta de estado
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vistas auxiliares
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay mesas configuradas',
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Configura las mesas desde el panel de administración',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: _kPink),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar las mesas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kDark),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
