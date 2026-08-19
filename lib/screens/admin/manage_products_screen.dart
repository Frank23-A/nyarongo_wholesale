import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/models/product_model.dart';
import 'package:nyarongo_wholesale/services/product_service.dart';
import 'package:nyarongo_wholesale/utils/categories_data.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/widgets/search_bar.dart';

class ManageProductsScreen extends StatefulWidget {
  final bool embedded;

  const ManageProductsScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final ProductService _productService = const ProductService();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: StreamBuilder<List<ProductModel>>(
        stream: _productService.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _DatabaseErrorState(message: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;
          final filteredProducts = _filterProducts(products);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Manage Products',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openEditor(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Products',
                      value: '${products.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Available',
                      value:
                          '${products.where((product) => product.isAvailable).length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppSearchBar(
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: filteredProducts.isEmpty
                    ? _EmptyProductsState(hasQuery: _query.isNotEmpty)
                    : ListView.separated(
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _AdminProductCard(
                            product: product,
                            onToggleAvailability: () async {
                              await _productService
                                  .toggleAvailability(product);
                            },
                            onDelete: () => _deleteProduct(product),
                            onEdit: () => _openEditor(product: product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      body: content,
    );
  }

  Future<void> _openEditor({ProductModel? product}) async {
    final saved = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductEditorSheet(product: product),
    );

    if (saved == null) {
      return;
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from the catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await _productService.deleteProduct(product.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} deleted')),
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    return products.where((product) {
      if (_query.isEmpty) {
        return true;
      }

      final normalizedQuery = _query.toLowerCase();
      return product.name.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery) ||
          product.description.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }
}

class _AdminProductCard extends StatelessWidget {
  final ProductModel product;
  final Future<void> Function() onToggleAvailability;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AdminProductCard({
    required this.product,
    required this.onToggleAvailability,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD97B14).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Switch(
                value: product.isAvailable,
                onChanged: (_) => onToggleAvailability(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.category,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 10),
          Text(product.description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProductMeta(
                label: 'Retail',
                value: 'KSh ${product.price.toStringAsFixed(0)}',
              ),
              _ProductMeta(
                label: 'Wholesale',
                value: 'KSh ${product.wholesalePrice.toStringAsFixed(0)}',
              ),
              _ProductMeta(
                label: 'MOQ',
                value: '${product.minOrderQuantity} ${product.unit}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ProductMeta extends StatelessWidget {
  final String label;
  final String value;

  const _ProductMeta({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  final bool hasQuery;

  const _EmptyProductsState({
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 48,
              color: AppConstants.textSecondaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery ? 'No products match your search.' : 'No products yet.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try a different name, category, or description keyword.'
                  : 'Add your first product to start building the catalog.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DatabaseErrorState extends StatelessWidget {
  final String message;

  const _DatabaseErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44),
            const SizedBox(height: 12),
            Text(
              'Could not load products from the database.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductEditorSheet extends StatefulWidget {
  final ProductModel? product;

  const _ProductEditorSheet({
    this.product,
  });

  @override
  State<_ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<_ProductEditorSheet> {
  final ProductService _productService = const ProductService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _wholesalePriceController;
  late final TextEditingController _moqController;
  late final TextEditingController _unitController;
  late String _category;
  bool _isAvailable = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController =
        TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );
    _wholesalePriceController = TextEditingController(
      text: product == null ? '' : product.wholesalePrice.toStringAsFixed(0),
    );
    _moqController = TextEditingController(
      text: product == null ? '1' : product.minOrderQuantity.toString(),
    );
    _unitController = TextEditingController(text: product?.unit ?? 'pcs');
    _category = product?.category ?? categoriesData.first['title'] as String;
    _isAvailable = product?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _wholesalePriceController.dispose();
    _moqController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.product == null ? 'Add Product' : 'Edit Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categoriesData
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category['title'] as String,
                          child: Text(category['title'] as String),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a short description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Retail price'),
                        validator: _validatePrice,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _wholesalePriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Wholesale price'),
                        validator: _validatePrice,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _moqController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Min order quantity'),
                        validator: _validateMinOrderQuantity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a unit';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() => _isAvailable = value);
                  },
                  title: const Text('Available for ordering'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final product = await _productService.saveProduct(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        category: _category,
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        wholesalePrice:
            double.tryParse(_wholesalePriceController.text.trim()) ?? 0,
        minOrderQuantity: int.tryParse(_moqController.text.trim()) ?? 1,
        unit: _unitController.text.trim().isEmpty
            ? 'pcs'
            : _unitController.text.trim(),
        isAvailable: _isAvailable,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(product);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save product: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validatePrice(String? value) {
    final parsedValue = double.tryParse(value?.trim() ?? '');
    if (parsedValue == null || parsedValue <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  String? _validateMinOrderQuantity(String? value) {
    final parsedValue = int.tryParse(value?.trim() ?? '');
    if (parsedValue == null || parsedValue <= 0) {
      return 'Enter a valid quantity';
    }
    return null;
  }
}
