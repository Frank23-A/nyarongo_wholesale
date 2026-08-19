import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';

class FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const FilterBar({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => onFilterSelected(filter),
            selectedColor: AppConstants.primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppConstants.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }
}
