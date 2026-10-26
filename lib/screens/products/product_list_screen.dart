import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constantscolors.dart';
import '../../services/product_provider.dart';
import '../../widgets/product_tile.dart';
import 'add_edit_screen_product.dart';

class ProductListScreen extends StatefulWidget {
  final bool initialLowStockOnly;

  const ProductListScreen({super.key, this.initialLowStockOnly = false});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _query = '';
  late bool _lowStockOnly;

  @override
  void initState() {
    super.initState();
    _lowStockOnly = widget.initialLowStockOnly;
  }

  void _openForm({product}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
      side: BorderSide.none,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: selected ? Colors.white : AppColors.primary,
      ),
    );
  }

  Widget _buildMessage(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryDisabled),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProductProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.errorMessage != null && provider.products.isEmpty) {
      return _buildMessage(
        Icons.error_outline_rounded,
        'Something went wrong',
        provider.errorMessage!,
      );
    }

    if (provider.products.isEmpty) {
      return _buildMessage(
        Icons.inventory_2_outlined,
        'No products yet',
        'Tap the + button to add your first product.',
      );
    }

    final items = provider.filtered(query: _query, lowStockOnly: _lowStockOnly);

    if (items.isEmpty) {
      return _buildMessage(
        Icons.search_off_rounded,
        'No matching products',
        'Try a different name or clear the filter.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.padding,
        8,
        AppSizes.padding,
        96,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return ProductTile(
          product: product,
          onTap: () => _openForm(product: product),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.padding,
              8,
              AppSizes.padding,
              12,
            ),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name or barcode',
                prefixIcon: Icon(Icons.search_rounded, size: 22),
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
            child: Row(
              children: [
                _buildFilterChip(
                  'All',
                  !_lowStockOnly,
                  () => setState(() => _lowStockOnly = false),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Low stock (${provider.lowStock.length})',
                  _lowStockOnly,
                  () => setState(() => _lowStockOnly = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }
}
