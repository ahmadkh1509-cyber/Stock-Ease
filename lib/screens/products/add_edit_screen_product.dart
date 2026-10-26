import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constantscolors.dart';
import '../../models/product.dart';
import '../../services/product_provider.dart';
import '../../widgets/text_field.dart';
import '../../widgets/primarybutton.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product; // null = add mode, not null = edit mode

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _limitController;

  bool get _isEditing => widget.product != null;

  // 50.0 -> "50", 50.5 -> "50.5"
  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _buyPriceController = TextEditingController(
      text: p == null ? '' : _fmt(p.buyPrice),
    );
    _sellPriceController = TextEditingController(
      text: p == null ? '' : _fmt(p.sellPrice),
    );
    _quantityController = TextEditingController(
      text: p == null ? '' : '${p.quantity}',
    );
    _limitController = TextEditingController(
      text: p == null ? '5' : '${p.lowStockLimit}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  // ---------- Validators ----------
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter the product name';
    return null;
  }

  String? _validateBarcode(String? value) {
    final exists = context.read<ProductProvider>().barcodeExists(
      value ?? '',
      excludeId: widget.product?.id,
    );
    if (exists) return 'This barcode is already used by another product';
    return null; // barcode is optional
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a price';
    final number = double.tryParse(value.trim());
    if (number == null) return 'Enter a valid number';
    if (number < 0) return 'Price cannot be negative';
    return null;
  }

  String? _validateWholeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = int.tryParse(value.trim());
    if (number == null) return 'Enter a whole number';
    if (number < 0) return 'Cannot be negative';
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

  // ---------- Actions ----------
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      buyPrice: double.parse(_buyPriceController.text.trim()),
      sellPrice: double.parse(_sellPriceController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      lowStockLimit: int.parse(_limitController.text.trim()),
    );

    final provider = context.read<ProductProvider>();
    final success = _isEditing
        ? await provider.updateProduct(product)
        : await provider.addProduct(product);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      _showError(provider.errorMessage ?? 'Could not save the product');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete product?'),
        content: Text('"${widget.product!.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final success = await provider.deleteProduct(widget.product!.id);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      _showError(provider.errorMessage ?? 'Could not delete the product');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<ProductProvider>().isSaving;
    const decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'Add product'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              onPressed: isSaving ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  label: 'Product name',
                  hint: 'Sugar 1kg',
                  icon: Icons.inventory_2_outlined,
                  controller: _nameController,
                  validator: _validateName,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Barcode (optional)',
                  hint: '8964000123456',
                  icon: Icons.qr_code_2_rounded,
                  controller: _barcodeController,
                  keyboardType: TextInputType.number,
                  validator: _validateBarcode,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Buy price',
                        hint: '120',
                        icon: Icons.south_west_rounded,
                        controller: _buyPriceController,
                        keyboardType: decimalKeyboard,
                        validator: _validatePrice,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Sell price',
                        hint: '150',
                        icon: Icons.north_east_rounded,
                        controller: _sellPriceController,
                        keyboardType: decimalKeyboard,
                        validator: _validatePrice,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Quantity',
                        hint: '50',
                        icon: Icons.numbers_rounded,
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        validator: _validateWholeNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Low stock limit',
                        hint: '5',
                        icon: Icons.warning_amber_rounded,
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: _validateWholeNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: _isEditing ? 'Save changes' : 'Add product',
                  isLoading: isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
