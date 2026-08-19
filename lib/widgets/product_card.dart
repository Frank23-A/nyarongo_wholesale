import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/models/product_model.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFDFF7F0), Color(0xFFFDF2D3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  product.name.substring(0, 1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'KSh ${product.wholesalePrice.toStringAsFixed(0)} / ${product.unit}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              product.isAvailable ? 'In stock' : 'Out of stock',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: product.isAvailable
                        ? Colors.green.shade700
                        : Colors.red.shade400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
