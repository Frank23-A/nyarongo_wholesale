import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nyarongo_wholesale/models/product_model.dart';
import 'package:nyarongo_wholesale/services/firebase_service.dart';
import 'package:nyarongo_wholesale/utils/categories_data.dart';

class ProductService {
  const ProductService();

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      FirebaseService.firestore.collection('products');

  Stream<List<ProductModel>> watchProducts() {
    return _productsCollection
        .orderBy('name')
        .snapshots()
        .map(_productsFromSnapshot);
  }

  Stream<List<ProductModel>> watchProductsByCategory(String category) {
    return watchProducts().map(
      (products) => products
          .where((product) => product.category == category)
          .toList(growable: false),
    );
  }

  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _productsCollection.orderBy('name').get();
    final products = _productsFromSnapshot(snapshot);
    return products.isEmpty ? List<ProductModel>.from(demoProducts) : products;
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products
        .where((product) => product.category == category)
        .toList(growable: false);
  }

  Future<ProductModel> saveProduct({
    String? id,
    required String name,
    required String category,
    required String description,
    required double price,
    required double wholesalePrice,
    required int minOrderQuantity,
    required String unit,
    required bool isAvailable,
  }) async {
    final document =
        id == null ? _productsCollection.doc() : _productsCollection.doc(id);
    final product = ProductModel(
      id: document.id,
      name: name,
      category: category,
      description: description,
      price: price,
      wholesalePrice: wholesalePrice,
      minOrderQuantity: minOrderQuantity,
      unit: unit,
      imageUrl: '',
      isAvailable: isAvailable,
    );

    await document.set({
      ...product.toMap(),
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return product;
  }

  Future<void> toggleAvailability(ProductModel product) {
    return _productsCollection.doc(product.id).set({
      'isAvailable': !product.isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) {
    return _productsCollection.doc(productId).delete();
  }

  Future<void> seedDemoProductsIfEmpty() async {
    final snapshot = await _productsCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = FirebaseService.firestore.batch();
    for (final product in demoProducts) {
      batch.set(_productsCollection.doc(product.id), {
        ...product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  List<ProductModel> _productsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((document) => ProductModel.fromMap(document.data(), document.id))
        .toList(growable: false);
  }
}
