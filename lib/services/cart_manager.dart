import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gearup/models/spare_part.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final SparePart part;
  int quantity;

  CartItem({required this.part, this.quantity = 1});

  Map<String, dynamic> toMap() {
    return {
      'part': part.toMap(),
      'partId': part.id,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      part: SparePart.fromMap(map['part'], map['partId']),
      quantity: map['quantity'],
    );
  }
}

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  
  CartManager._internal() {
    _loadCart();
  }

  final List<CartItem> _items = [];
  static const String _storageKey = 'gearup_cart';

  List<CartItem> get items => List.unmodifiable(_items);

  double get subtotal => _items.fold(0, (sum, item) => sum + (item.part.price * item.quantity));
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_storageKey);
      if (cartJson != null) {
        final List<dynamic> decoded = json.decode(cartJson);
        _items.clear();
        _items.addAll(decoded.map((item) => CartItem.fromMap(item)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_items.map((item) => item.toMap()).toList());
      await prefs.setString(_storageKey, cartJson);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  void addToCart(SparePart part) {
    final index = _items.indexWhere((item) => item.part.id == part.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(part: part));
    }
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String partId) {
    _items.removeWhere((item) => item.part.id == partId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String partId, int delta) {
    final index = _items.indexWhere((item) => item.part.id == partId);
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
}
