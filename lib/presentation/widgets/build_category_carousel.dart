import 'package:flutter/material.dart';
import 'package:restaurant_kiosco/service/api_service.dart';
import '../../models/category.dart';
 
const Color _mexicanPink = Color(0xFFE91E63);

class BuildCategoryCarousel extends StatefulWidget {
  final Future<bool> Function(int categoryId) onCategoryTap;

  const BuildCategoryCarousel({super.key, required this.onCategoryTap});

  @override
  State<BuildCategoryCarousel> createState() => _BuildCategoryCarouselState();
}

class _BuildCategoryCarouselState extends State<BuildCategoryCarousel> {
  bool _isLoading = true;
  String? _error;
  List<Category> _categories = [];
  int? _selectedCategoryId;

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
        _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
        _isLoading = false;
      });

      await _selectFirstValidCategory();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectFirstValidCategory() async {
    if (_categories.isEmpty) return;

    for (final category in List<Category>.from(_categories)) {
      final ok = await widget.onCategoryTap(category.id);
      if (!mounted) return;

      if (ok) {
        setState(() => _selectedCategoryId = category.id);
        return;
      }

      setState(() {
        _categories.removeWhere((c) => c.id == category.id);
      });
    }

    if (mounted && _categories.isEmpty) {
      setState(() => _selectedCategoryId = null);
    }
  }

  Future<void> _onCategoryPressed(int categoryId) async {
    final previous = _selectedCategoryId;
    setState(() => _selectedCategoryId = categoryId);

    final ok = await widget.onCategoryTap(categoryId);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _categories.removeWhere((c) => c.id == categoryId);
        _selectedCategoryId = previous;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          height: 60,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(
                        'Error: $_error',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : _categories.isEmpty
                      ? Center(
                          child: Text(
                            'No hay categorías',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category.id == _selectedCategoryId;

                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async => _onCategoryPressed(category.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.black87 : Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOut,
                                      width: isSelected ? 36 : 0,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _mexicanPink,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
