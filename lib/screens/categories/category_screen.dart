import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/screens/categories/products_screen.dart';
import 'package:nyarongo_wholesale/utils/categories_data.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/widgets/category_card.dart';
import 'package:nyarongo_wholesale/widgets/search_bar.dart';

class CategoryScreen extends StatefulWidget {
  final bool embedded;

  const CategoryScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filteredCategories = categoriesData.where((category) {
      final title = (category['title'] as String).toLowerCase();
      final subtitle = (category['subtitle'] as String).toLowerCase();
      final normalizedQuery = query.toLowerCase();

      return title.contains(normalizedQuery) || subtitle.contains(normalizedQuery);
    }).toList(growable: false);

    final content = Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.embedded) ...[
                  Text(
                    'Shop Categories',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  'Wholesale made simple',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse stock by category, compare wholesale pricing and move faster.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSearchBar(
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 20),
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: filteredCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = filteredCategories[index];

                return CategoryCard(
                  title: category['title'] as String,
                  subtitle: category['subtitle'] as String,
                  icon: category['icon'] as IconData,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductsScreen(
                          category: category['title'] as String,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Categories'),
      ),
      body: content,
    );
  }
}
