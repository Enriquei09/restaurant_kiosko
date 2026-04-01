import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../models/cart_item.dart';
import '../../../providers/cart_model.dart';
import '../../../providers/restaurant_provider.dart';
import '../../../service/api_service.dart';

class DirectSalesScreen extends StatefulWidget {
  const DirectSalesScreen({super.key});

  @override
  State<DirectSalesScreen> createState() => _DirectSalesScreenState();
}

class _DirectSalesScreenState extends State<DirectSalesScreen> {
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
      if (categories.isNotEmpty) {
        _selectCategory(categories.first.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar categorías: $e')),
      );
    }
  }

  Future<void> _selectCategory(int categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoadingProducts = true;
    });
    try {
      final category = await ApiService.fetchCategoryWithProducts(categoryId);
      if (!mounted) return;
      final allProducts = <Product>[];
      for (final group in category.productGroups) {
        allProducts.addAll(group.products.where((p) => p.active && !p.outOfStock));
      }
      setState(() {
        _products = allProducts;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  void _addToCart(Product product) {
    final cart = context.read<CartModel>();
    cart.add(CartItem(
      productId: product.id,
      name: product.name,
      unitPrice: product.price,
      qty: 1,
      imagePath: product.imagePath,
    ));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 300, right: 300),
      ),
    );
  }

  // ─── Iconos por nombre de categoría ───────────────────────
  IconData _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('popular') || lower.contains('destacado')) return Icons.local_fire_department;
    if (lower.contains('taco')) return Icons.lunch_dining;
    if (lower.contains('burrito') || lower.contains('wrap')) return Icons.fastfood;
    if (lower.contains('bebida') || lower.contains('drink')) return Icons.local_bar;
    if (lower.contains('postre') || lower.contains('dessert')) return Icons.cake;
    if (lower.contains('ensalada') || lower.contains('salad')) return Icons.eco;
    if (lower.contains('entra') || lower.contains('side') || lower.contains('acomp')) return Icons.tapas;
    if (lower.contains('sopa') || lower.contains('soup')) return Icons.soup_kitchen;
    if (lower.contains('barbacoa') || lower.contains('parrilla') || lower.contains('grill')) return Icons.outdoor_grill;
    if (lower.contains('plat') || lower.contains('tipico')) return Icons.restaurant;
    if (lower.contains('desayuno') || lower.contains('breakfast')) return Icons.free_breakfast;
    if (lower.contains('pizza')) return Icons.local_pizza;
    return Icons.restaurant_menu;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final restaurantProvider = context.watch<RestaurantProvider>();
    // Sincronizar tax rate
    cart.setTaxRate(restaurantProvider.config.taxRate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nueva Venta',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                cart.clear();
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              label: const Text('Limpiar', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ═══════════════════════════════════════════════════
          // COLUMNA 1 — CATEGORÍAS (100px)
          // ═══════════════════════════════════════════════════
          _buildCategoriesColumn(),

          // ═══════════════════════════════════════════════════
          // COLUMNA 2 — GRID DE PRODUCTOS (Expanded)
          // ═══════════════════════════════════════════════════
          Expanded(child: _buildProductsGrid()),

          // ═══════════════════════════════════════════════════
          // COLUMNA 3 — TICKET DE VENTA (350px)
          // ═══════════════════════════════════════════════════
          _buildTicketColumn(cart),
        ],
      ),
    );
  }

  // ─── COLUMNA 1: Categorías ────────────────────────────────
  Widget _buildCategoriesColumn() {
    return Container(
      width: 100,
      color: const Color(0xFFF0F0F0),
      child: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'CATEGORIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat.id == _selectedCategoryId;
                      return _buildCategoryTile(cat, isSelected);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryTile(Category category, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectCategory(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE91E63) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForCategory(category.name),
              size: 24,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── COLUMNA 2: Grid de productos ────────────────────────
  Widget _buildProductsGrid() {
    if (_isLoadingProducts) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE91E63),
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sin productos en esta categoría',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Barra de búsqueda ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
              ),
            ),
            onChanged: (query) {
              // Filtrar productos localmente
              if (query.isEmpty && _selectedCategoryId != null) {
                _selectCategory(_selectedCategoryId!);
                return;
              }
              setState(() {
                _products = _products
                    .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              });
            },
          ),
        ),
        // ── Grid ─────────────────────────────────────────────
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final isNetwork = product.imagePath.startsWith('http');

    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: isNetwork
                    ? Image.network(
                        product.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : Image.asset(
                        product.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.fastfood_rounded, size: 40, color: Colors.grey.shade300),
      ),
    );
  }

  // ─── COLUMNA 3: Ticket de venta ──────────────────────────
  Widget _buildTicketColumn(CartModel cart) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header del ticket ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFFE91E63),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ticket de Venta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${cart.totalItems} items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista de productos ───────────────────────────
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Cart is empty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca un producto para agregarlo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItemTile(cart, item, index);
                    },
                  ),
          ),

          // ── Totales ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                _buildTotalRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _buildTotalRow(
                  'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)',
                  '\$${cart.tax.toStringAsFixed(2)}',
                ),
                if (cart.promotionDiscount > 0) ...[
                  const SizedBox(height: 6),
                  _buildTotalRow(
                    'Descuento',
                    '-\$${cart.promotionDiscount.toStringAsFixed(2)}',
                    valueColor: Colors.green,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '\$${cart.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Botón Confirmar y Pagar ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/checkout');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Confirmar y Pagar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartModel cart, CartItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mini imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: item.imagePath != null && item.imagePath!.startsWith('http')
                  ? Image.network(item.imagePath!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _miniPlaceholder())
                  : item.imagePath != null
                      ? Image.asset(item.imagePath!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _miniPlaceholder())
                      : _miniPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre y precio unitario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Controles + / -
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _qtyButton(
                  icon: Icons.remove,
                  onTap: () => cart.decrease(index),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.qty}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                _qtyButton(
                  icon: Icons.add,
                  onTap: () => cart.setQty(index, item.qty + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Total de línea
          SizedBox(
            width: 60,
            child: Text(
              '\$${item.line.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.fastfood, size: 20, color: Colors.grey.shade400),
    );
  }

  Widget _buildTotalRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
