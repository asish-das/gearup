import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:gearup/services/cart_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isProcessing = false;

  final CartManager _cartManager = CartManager();

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all delivery details')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String userName = 'Mobile User';
      if (user != null) {
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          userName = user.displayName!;
        } else if (user.email != null && user.email!.isNotEmpty) {
          userName = user.email!;
        }
      }

      final deliveryFee = 150.0;
      final totalAmount = _cartManager.subtotal + deliveryFee;
      final firestore = FirebaseFirestore.instance;

      // Use a batch to ensure atomicity
      final batch = firestore.batch();

      // Create the order document
      final orderRef = firestore.collection('orders').doc();
      final orderData = {
        'userId': user?.uid ?? 'anonymous',
        'userName': userName,
        'items': _cartManager.items.map((item) => {
          'partId': item.part.id,
          'partName': item.part.name,
          'price': item.part.price,
          'quantity': item.quantity,
          'imageUrl': item.part.imageUrl,
          'serviceCenterId': item.part.serviceCenterId,
          'status': 'pending', // Added status per item
        }).toList(),
        'subtotal': _cartManager.subtotal,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'paymentMethod': _selectedPaymentMethod,
        'status': 'pending', // Overall order status
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(orderRef, orderData);

      // Create individual purchase records for admin and service centers
      for (var item in _cartManager.items) {
        final purchaseRef = firestore.collection('purchases').doc();
        batch.set(purchaseRef, {
          'orderId': orderRef.id,
          'userId': user?.uid ?? 'anonymous',
          'userName': userName,
          'partId': item.part.id,
          'partName': item.part.name,
          'imageUrl': item.part.imageUrl,
          'price': item.part.price,
          'quantity': item.quantity,
          'serviceCenterId': item.part.serviceCenterId,
          'address': _addressController.text,
          'phone': _phoneController.text,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Decrement stock for each item
        final partRef = firestore.collection('spareParts').doc(item.part.id);
        batch.update(partRef, {
          'stock': FieldValue.increment(-item.quantity),
        });
      }

      await batch.commit();

      _cartManager.clearCart();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed!',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your parts are on their way to you. You can track your order in the history section.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Delivery Address'),
            _buildTextField(
              controller: _addressController,
              hint: 'Enter your full delivery address',
              icon: Icons.location_on_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Contact Number'),
            _buildTextField(
              controller: _phoneController,
              hint: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Order Items'),
            _buildOrderItemsPreview(),
            const SizedBox(height: 32),
            _buildSectionTitle('Payment Method'),
            _buildPaymentOption('Cash on Delivery', Icons.payments_outlined),
            _buildPaymentOption('UPI / Online', Icons.account_balance_wallet_outlined, enabled: false),
            const SizedBox(height: 32),
            _buildOrderSummary(),
            const SizedBox(height: 40),
            _buildPlaceOrderButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _cartManager.items.length,
        separatorBuilder: (context, index) => const Divider(height: 24, color: Colors.white10),
        itemBuilder: (context, index) {
          final item = _cartManager.items[index];
          return Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _buildPartImage(item.part.imageUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.part.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.quantity} × ₹${item.part.price}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${(item.part.price * item.quantity).toStringAsFixed(0)}',
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, {bool enabled = true}) {
    final isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedPaymentMethod = title) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary.withValues(alpha: 0.1) 
              : AppTheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primary.withValues(alpha: 0.5) 
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : Colors.white54),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (!enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'COMING SOON',
                  style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            if (enabled)
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppTheme.primary : Colors.white24,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final deliveryFee = 150.0;
    final total = _cartManager.subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items Subtotal', style: TextStyle(color: Colors.white70)),
              Text(
                '₹${_cartManager.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Fee', style: TextStyle(color: Colors.white70)),
              Text(
                '₹${deliveryFee.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'PLACE ORDER NOW',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildPartImage(String source) {
    if (source.startsWith('data:image')) {
      try {
        final base64Str = source.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
        );
      } catch (e) {
        return const Center(child: Icon(Icons.image, color: Colors.white24));
      }
    }
    return CachedNetworkImage(
      imageUrl: source,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
      errorWidget: (context, url, error) => const Center(child: Icon(Icons.image, color: Colors.white24)),
    );
  }
}
