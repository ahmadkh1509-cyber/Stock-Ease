import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constantscolors.dart';
import '../../models/product.dart';
import '../../services/product_provider.dart';
import '../../services/transaction_provider.dart';
import '../../widgets/text_field.dart';
import '../../widgets/primarybutton.dart';

class StockMovementScreen extends StatefulWidget {
  final bool isIn; // true = Stock In, false = Stock Out
  final String? initialProductId;

  const StockMovementScreen({
    super.key,
    required this.isIn,
    this.initialProductId,
  });

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  String? _selectedId;
  String? _productError;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialProductId;
    // Rebuild while typing so the Total updates live
    _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Product? _findSelected(ProductProvider provider) {
    return provider.products.where((p) => p.id == _selectedId).firstOrNull;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter the quantity';
    final number = int.tryParse(value.trim());
    if (number == null) return 'Enter a whole number';
    if (number <= 0) return 'Quantity must be greater than 0';

    if (!widget.isIn) {
      final product = _findSelected(context.read<ProductProvider>());
      if (product != null && number > product.quantity) {
        return 'Only ${product.quantity} in stock';
      }
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickProduct() async {
    FocusScope.of(context).unfocus();
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ProductPickerSheet(),
    );

    if (id != null) {
      setState(() {
        _selectedId = id;
        _productError = null;
      });
    }
  }

  Future<void> _submit() async {
    final product = _findSelected(context.read<ProductProvider>());
    if (product == null) {
      setState(() => _productError = 'Select a product first');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final quantity = int.parse(_quantityController.text.trim());
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.recordMovement(
      productId: product.id,
      quantity: quantity,
      isIn: widget.isIn,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isIn
                ? 'Added $quantity to ${product.name}'
                : 'Sold $quantity of ${product.name}',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(provider.errorMessage ?? 'Could not save');
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final isSaving = context.watch<TransactionProvider>().isSaving;

    final product = _findSelected(products);
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final unitPrice = product == null
        ? 0.0
        : (widget.isIn ? product.buyPrice : product.sellPrice);
    final total = unitPrice * quantity;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isIn ? 'Stock in' : 'Stock out')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isIn
                      ? 'Add new stock to a product at its buy price.'
                      : 'Record a sale at the sell price.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24),

                // ---------- Product picker ----------
                const Text(
                  'Product',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  child: InkWell(
                    onTap: _pickProduct,
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                        border: Border.all(
                          color: _productError != null
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: product == null
                                ? const Text(
                                    'Select a product',
                                    style: TextStyle(color: AppColors.textGrey),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${product.quantity} in stock',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_productError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      _productError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // ---------- Quantity ----------
                CustomTextField(
                  label: 'Quantity',
                  hint: '10',
                  icon: Icons.numbers_rounded,
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: _validateQuantity,
                ),
                const SizedBox(height: 20),

                // ---------- Live total ----------
                if (product != null && quantity > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isIn ? 'Total cost' : 'Total sale',
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                        Text(
                          'Rs ${NumberFormat('#,##0.##').format(total)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: widget.isIn ? 'Add stock' : 'Record sale',
                  isLoading: isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Bottom sheet with search ----------
class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet();

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ProductProvider>().filtered(query: _query);

    return Padding(
      // Keeps the sheet above the keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search by name or barcode',
                  prefixIcon: Icon(Icons.search_rounded, size: 22),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final p = items[index];
                        return ListTile(
                          title: Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          trailing: Text(
                            '${p.quantity} in stock',
                            style: TextStyle(
                              fontSize: 13,
                              color: p.isLowStock
                                  ? AppColors.error
                                  : AppColors.textGrey,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, p.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
