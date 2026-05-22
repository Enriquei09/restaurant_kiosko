import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/models/product.dart';
import 'package:restaurant_kiosco/presentation/widgets/larger_button.dart';
import 'package:restaurant_kiosco/presentation/widgets/selerctor_items.dart';

const Color _mexicanPink = Color(0xFFE91E63);

class ProductDescription extends StatefulWidget {
  const ProductDescription({super.key, required this.product});
  final Product product;

  @override
  State<ProductDescription> createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  int _currentStep = 0;
  int _totalSteps = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 760,
          height: 720,
          color: Colors.white,
          child: Column(
            children: [
              _HeaderImage(
                product: widget.product,
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                onBack: () => setState(() => _currentStep--),
              ),
              Expanded(
                child: InfoProductContainer(
                  product: widget.product,
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onCurrentStepChanged: (s) => setState(() => _currentStep = s),
                  onGroupsLoaded: (count) {
                    if (count != _totalSteps) {
                      setState(() {
                        _totalSteps = count;
                        _currentStep = 0;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  final Product product;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _HeaderImage({
    required this.product,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = product.imagePath.startsWith('http');
    final bool canGoBack = currentStep > 0;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del producto
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: isNetwork
                      ? Image.network(
                          product.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : Image.asset(
                          product.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                ),
                // Botón retroceso (solo visible en paso > 0)
                if (canGoBack)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFFE91E63),
                          size: 20,
                        ),
                        onPressed: onBack,
                        tooltip: 'Paso anterior',
                      ),
                    ),
                  ),
                // Botón cerrar (siempre visible)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nombre y descripción sobre fondo blanco
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if (product.description.isNotEmpty) ...
                  [
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.restaurant_menu, size: 64, color: Color(0xFFCCCCCC)),
        ),
      );
}

class InfoProductContainer extends StatefulWidget {
  const InfoProductContainer({
    super.key,
    required this.product,
    required this.currentStep,
    required this.totalSteps,
    required this.onCurrentStepChanged,
    required this.onGroupsLoaded,
  });

  final Product product;
  final int currentStep;
  final int totalSteps;
  final ValueChanged<int> onCurrentStepChanged;
  final ValueChanged<int> onGroupsLoaded;

  @override
  State<InfoProductContainer> createState() => _InfoProductContainerState();
}

class _InfoProductContainerState extends State<InfoProductContainer> {
  List<int> selectedModifiers = [];
  List<String> _modsLabels = [];
  int qty = 1;
  String? note;
  double _extraTotal = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final total = (p.price + _extraTotal) * qty;

    // Usa los valores de paso que vienen del padre
    final int currentStep = widget.currentStep;
    final int totalSteps = widget.totalSteps;
    final bool hasSteps = totalSteps > 1;
    final bool isLastStep = currentStep >= totalSteps - 1;

    return Column(
      children: [
        // ── Indicador de pasos (solo visible si hay > 1 grupo) ──────────────
        if (hasSteps)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: _StepIndicator(
              totalSteps: totalSteps,
              currentStep: currentStep,
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base: \$${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A6D),
                  ),
                ),
                const SizedBox(height: 12),
                ExtraSelector(
                  key: ValueKey('${p.id}_$currentStep'),
                  productId: p.id,
                  onChanged: (mods) => setState(() => selectedModifiers = mods),
                  onLabelsChanged: (labels) =>
                      setState(() => _modsLabels = labels),
                  onQtyChanged: (q) => setState(() => qty = q),
                  onNoteChanged: (n) => setState(() => note = n),
                  onExtraTotalChanged: (value) =>
                      setState(() => _extraTotal = value),
                  onGroupsLoaded: widget.onGroupsLoaded,
                  // En modo paginado: paso actual y mostrar qty/nota solo al final
                  currentStep: hasSteps ? currentStep : null,
                  showQtyNote: !hasSteps || isLastStep,
                ),
              ],
            ),
          ),
        ),

        // ── Barra inferior ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // ── Botón ATRÁS (visible solo si hay pasos y no es el primero) ──
                  if (hasSteps && currentStep > 0) ...[
                    SizedBox(
                      height: 64,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _mexicanPink,
                          side: const BorderSide(color: _mexicanPink, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        label: const Text(
                          'Atrás',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () =>
                            widget.onCurrentStepChanged(currentStep - 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // ── Botón SIGUIENTE o AGREGAR AL CARRITO ────────────────
                  if (hasSteps && !isLastStep)
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mexicanPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                          label: const Text(
                            'Siguiente',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () =>
                              widget.onCurrentStepChanged(currentStep + 1),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: LargeButton(
                        productId: p.id,
                        name: p.name,
                        price: p.price,
                        imagePath: p.imagePath,
                        modifierIds: selectedModifiers,
                        modifierLabels: _modsLabels,
                        qty: qty,
                        note: note,
                        openCartAfterAdd: true,
                        closeCurrentDialog: true,
                        buttonText:
                            'Agregar al carrito • \$${total.toStringAsFixed(2)}',
                        backgroundColor: _mexicanPink,
                        minHeight: 64,
                        fontSize: 20,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Indicador de pasos horizontal con puntos y etiqueta "Paso X de N"
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Etiqueta textual
        Text(
          'Paso ${currentStep + 1} de $totalSteps',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        // Barra de puntos / segmentos
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (i) {
            final bool isActive = i == currentStep;
            final bool isDone = i < currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive
                    ? _mexicanPink
                    : isDone
                        ? _mexicanPink.withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class ImageContainer extends StatelessWidget {
  const ImageContainer({super.key, required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Colors.white),
      alignment: Alignment.topCenter,
      child: isNetwork
          ? Image.network(imagePath, width: 280, fit: BoxFit.cover)
          : Image.asset(imagePath, width: 280, fit: BoxFit.cover),
    );
  }
}

// Mantener clase para compatibilidad en imports antiguos
class IconsViewCard extends StatelessWidget {
  const IconsViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
