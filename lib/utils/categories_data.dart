import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/models/product_model.dart';

const List<Map<String, dynamic>> categoriesData = [
  {
    'title': 'Groceries',
    'subtitle': 'Rice, flour, sugar and essentials',
    'icon': Icons.shopping_basket_rounded,
  },
  {
    'title': 'Beverages',
    'subtitle': 'Soft drinks, water and juices',
    'icon': Icons.local_drink_rounded,
  },
  {
    'title': 'Household',
    'subtitle': 'Cleaning and home supplies',
    'icon': Icons.cleaning_services_rounded,
  },
  {
    'title': 'Personal Care',
    'subtitle': 'Toiletries and daily care products',
    'icon': Icons.spa_rounded,
  },
];

const List<String> productFilters = [
  'All',
  'Available',
  'Wholesale Deals',
  'Fast Moving',
];

final List<ProductModel> demoProducts = [
  ProductModel(
    id: 'prod_1',
    name: 'Pishori Rice 25kg',
    category: 'Groceries',
    description: 'Premium long-grain rice ideal for restaurants and retailers.',
    price: 4200,
    wholesalePrice: 3900,
    minOrderQuantity: 2,
    unit: 'bag',
    imageUrl: '',
    isAvailable: true,
  ),
  ProductModel(
    id: 'prod_2',
    name: 'Maize Flour 2kg',
    category: 'Groceries',
    description: 'Well-milled flour packed for resale and family stock.',
    price: 185,
    wholesalePrice: 165,
    minOrderQuantity: 12,
    unit: 'pack',
    imageUrl: '',
    isAvailable: true,
  ),
  ProductModel(
    id: 'prod_3',
    name: 'Soda Crate 300ml',
    category: 'Beverages',
    description: 'Mixed flavors available for kiosks, events and shops.',
    price: 820,
    wholesalePrice: 760,
    minOrderQuantity: 3,
    unit: 'crate',
    imageUrl: '',
    isAvailable: true,
  ),
  ProductModel(
    id: 'prod_4',
    name: 'Mineral Water 1L',
    category: 'Beverages',
    description: 'Bulk bottled water for offices, events and retail shelves.',
    price: 95,
    wholesalePrice: 80,
    minOrderQuantity: 24,
    unit: 'bottle',
    imageUrl: '',
    isAvailable: true,
  ),
  ProductModel(
    id: 'prod_5',
    name: 'Multipurpose Detergent 5L',
    category: 'Household',
    description: 'Strong cleaning solution for homes, schools and businesses.',
    price: 780,
    wholesalePrice: 710,
    minOrderQuantity: 4,
    unit: 'container',
    imageUrl: '',
    isAvailable: true,
  ),
  ProductModel(
    id: 'prod_6',
    name: 'Bathing Soap Carton',
    category: 'Personal Care',
    description: 'Retail-ready soap bars packed in a wholesale carton.',
    price: 1650,
    wholesalePrice: 1500,
    minOrderQuantity: 1,
    unit: 'carton',
    imageUrl: '',
    isAvailable: false,
  ),
];
