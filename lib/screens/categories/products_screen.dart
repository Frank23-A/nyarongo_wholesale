import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/models/product_model.dart';
import 'package:nyarongo_wholesale/screens/categories/product_details_screen.dart';
import 'package:nyarongo_wholesale/services/product_service.dart';
import 'package:nyarongo_wholesale/utils/categories_data.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/widgets/filter_bar.dart';
import 'package:nyarongo_wholesale/widgets/product_card.dart';
import 'package:nyarongo_wholesale/widgets/search_bar.dart';

class ProductsScreen extends StatefulWidget {
  final String category;

  const ProductsScreen({
    super.key,
    required this.category,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = const ProductService();
  String selectedFilter = productFilters.first;
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: StreamBuilder<List<ProductModel>>(
          stream: _productService.watchProductsByCategory(widget.category),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ProductLoadError(message: snapshot.error.toString());
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredProducts = _applyFilters(snapshot.data!);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSearchBar(
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 14),
                FilterBar(
                  filters: productFilters,
                  selectedFilter: selectedFilter,
                  onFilterSelected: (value) {
                    setState(() => selectedFilter = value);
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  '${filteredProducts.length} products available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text('No products found.'))
                      : GridView.builder(
                          itemCount: filteredProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];

                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    return products.where((product) {
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase());

      final matchesFilter = switch (selectedFilter) {
        'Available' => product.isAvailable,
        'Wholesale Deals' => product.wholesalePrice < product.price,
        'Fast Moving' => product.minOrderQuantity <= 12,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList(growable: false);
  }
}

class _ProductLoadError extends StatelessWidget {
  final String message;

  const _ProductLoadError({required this.message});

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
