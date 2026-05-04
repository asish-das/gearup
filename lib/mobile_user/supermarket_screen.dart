import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:gearup/models/spare_part.dart';
import 'package:gearup/services/cart_manager.dart';
import 'package:gearup/mobile_user/cart_screen.dart';
import 'package:gearup/mobile_user/product_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SupermarketScreen extends StatefulWidget {
  const SupermarketScreen({super.key});

  @override
  State<SupermarketScreen> createState() => _SupermarketScreenState();
}

class _SupermarketScreenState extends State<SupermarketScreen> {
  String _selectedCategory = 'All';
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Engine', 'icon': Icons.engineering_rounded},
    {'name': 'Brakes', 'icon': Icons.album_outlined},
    {'name': 'Oil & Fluids', 'icon': Icons.water_drop_rounded},
    {'name': 'Filters', 'icon': Icons.filter_alt_rounded},
    {'name': 'Wheels', 'icon': Icons.adjust_rounded},
    {'name': 'Exterior', 'icon': Icons.car_repair_rounded},
  ];
  String _searchQuery = '';
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_rebuild);
  }

  @override
  void dispose() {
    _cartManager.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Spare Parts',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                ),
              ),
              if (_cartManager.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_cartManager.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _showOrderHistory(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search spare parts...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _categories.map((cat) {
                final category = cat['name'] as String;
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildFilterButton(category, isSelected: isSelected),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: _cartManager.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              ),
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.backgroundDark,
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'VIEW CART (${_cartManager.itemCount})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterButton(String label, {bool isSelected = false}) {
    return InkWell(
      onTap: () => setState(() => _selectedCategory = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    Query query = FirebaseFirestore.instance.collection('spareParts');
    
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }

        var docs = snapshot.data?.docs ?? [];
        
        // In-memory filtering for stock, category (if not handled by Firestore), and search query
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // 1. Stock filter (must be greater than 0)
          final stock = (data['stock'] is int) ? data['stock'] as int : int.tryParse(data['stock']?.toString() ?? '0') ?? 0;
          if (stock <= 0) return false;

          // 2. Search query filter
          if (_searchQuery.isNotEmpty) {
            final name = (data['name'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            if (!name.contains(q) && !category.contains(q)) return false;
          }

          return true;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_2_outlined, 
                  size: 64, 
                  color: Colors.white70
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty 
                      ? 'No results for "$_searchQuery"' 
                      : 'No parts found in this category', 
                  style: const TextStyle(color: Colors.white70)
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) setState(() {});
          },
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final part = SparePart.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildProductCard(part),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(SparePart part) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(part: part),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildPartImage(part.imageUrl),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text('4.8', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              part.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              part.category.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${part.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(),
                      ElevatedButton(
                        onPressed: () {
                          _cartManager.addToCart(part);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${part.name} added to cart'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.backgroundDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }
    return CachedNetworkImage(
      imageUrl: source,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[900],
      child: const Icon(Icons.image, color: Colors.white24, size: 48),
    );
  }

  void _showOrderHistory() {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Order History',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: user?.uid ?? 'anonymous')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'Query Error',
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'The order history requires a database index. If you are the developer, please check the Firebase console. Otherwise, try again later.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                  child: const Text('RETRY'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                      }

                      final docs = snapshot.data!.docs;
                      
                      // Sort locally to avoid needing a composite index
                      final sortedDocs = docs.toList()..sort((a, b) {
                        final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        if (aTime == null) return -1;
                        if (bTime == null) return 1;
                        return bTime.compareTo(aTime);
                      });

                      if (sortedDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history, size: 64, color: Colors.white54),
                              const SizedBox(height: 16),
                              const Text('No orders yet', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: sortedDocs.length,
                        itemBuilder: (context, index) {
                          final data = sortedDocs[index].data() as Map<String, dynamic>;
                          final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
                          final status = data['status'] ?? 'pending';
                          final items = data['items'] as List? ?? [];
                          final address = data['address'] ?? 'No address';
                          final phone = data['phone'] ?? 'No phone';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.surface.withValues(alpha: 0.8),
                                          AppTheme.surface,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              timestamp != null 
                                                ? '${timestamp.day} ${_getMonth(timestamp.month)} ${timestamp.year}' 
                                                : 'Recent Order',
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'ORDER ID: #${sortedDocs[index].id.substring(0, 8).toUpperCase()}',
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white70,
                                                fontSize: 10,
                                                letterSpacing: 1,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _buildStatusChip(status),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${items.length} Item${items.length > 1 ? 's' : ''}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Delivery Info Section
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 20),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.phone_outlined, color: Colors.white54, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          phone,
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                                    child: Column(
                                      children: [
                                        ...items.map((item) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(14),
                                                  color: AppTheme.backgroundDark,
                                                  border: Border.all(color: AppTheme.surface.withValues(alpha: 0.5)),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(14),
                                                  child: item['imageUrl'] != null 
                                                    ? _buildPartImage(item['imageUrl'])
                                                    : const Icon(Icons.settings_outlined, color: AppTheme.primary, size: 24),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['partName'] ?? 'Unknown Part',
                                                      style: GoogleFonts.spaceGrotesk(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${item['quantity']} Unit${item['quantity'] > 1 ? 's' : ''} × ₹${item['price']}',
                                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Divider(height: 1, color: Colors.white12),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Paid',
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '₹${data['totalAmount']}',
                                              style: GoogleFonts.spaceGrotesk(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (data['trackingId'] != null && data['trackingId'].toString().isNotEmpty) ...[
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Divider(height: 1, color: Colors.white12),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.local_shipping_outlined, color: AppTheme.primary, size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Tracking ID:',
                                                style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 12),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                data['trackingId'],
                                                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          _buildTrackingStepper(status),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showTrackingModal(data, sortedDocs[index].id),
                                              icon: const Icon(Icons.track_changes_rounded, size: 18),
                                              label: Text(
                                                'TRACK ORDER',
                                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 1),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                                foregroundColor: AppTheme.primary,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
        );
      },
    );
  }

  void _showTrackingModal(Map<String, dynamic> initialData, String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.hasData ? (snapshot.data!.data() as Map<String, dynamic>?) ?? initialData : initialData;
              final status = data['status'] ?? 'pending';
              final items = data['items'] as List? ?? [];
              
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Live Tracking',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildDetailedTrackingStepper(status),
                        const SizedBox(height: 32),
                        Text(
                          'ITEM INFORMATION',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: item['imageUrl'] != null 
                                    ? _buildPartImage(item['imageUrl'])
                                    : const Icon(Icons.settings, color: AppTheme.primary, size: 20),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['partName'] ?? 'Unknown Part',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Qty: ${item['quantity']} • ₹${item['price']}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 32),
                        _trackingDetailRow('Order Status', status.toString().toUpperCase(), isPrimary: true),
                        _trackingDetailRow('Tracking ID', '#${orderId.substring(0, 10).toUpperCase()}'),
                        _trackingDetailRow('Delivery Address', data['address'] ?? 'N/A'),
                        _trackingDetailRow('Contact Phone', data['phone'] ?? 'N/A'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(color: Colors.white10),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount', style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 16)),
                            Text(
                              '₹${data['totalAmount']}',
                              style: GoogleFonts.spaceGrotesk(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTrackingStepper(String status) {
    final steps = ['pending', 'shipped', 'out for delivery', 'delivered'];
    final currentIndex = steps.indexOf(status.toLowerCase());
    
    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == steps.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.primary : Colors.white10,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ] : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.circle,
                      size: 16,
                      color: isCompleted ? Colors.white : Colors.white24,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted ? AppTheme.primary : Colors.white10,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index].toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.white : Colors.white24,
                      ),
                    ),
                    Text(
                      _getTrackingStepDesc(steps[index]),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.white54 : Colors.white10,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getTrackingStepDesc(String step) {
    switch (step.toLowerCase()) {
      case 'pending': return 'Your order is being processed by the center';
      case 'shipped': return 'Your package has been dispatched from the warehouse';
      case 'out for delivery': return 'Our delivery executive is on the way to you';
      case 'delivered': return 'Package delivered successfully to your address';
      default: return 'Status update in progress';
    }
  }

  Widget _trackingDetailRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isPrimary ? AppTheme.primary : Colors.white,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    IconData icon;
    switch (status.toLowerCase()) {
      case 'pending': icon = Icons.access_time_rounded; break;
      case 'confirmed': icon = Icons.check_circle_outline_rounded; break;
      case 'shipped': icon = Icons.local_shipping_outlined; break;
      case 'delivered': icon = Icons.verified_outlined; break;
      case 'cancelled': icon = Icons.cancel_outlined; break;
      default: icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(String status) {
    final steps = ['pending', 'shipped', 'out for delivery', 'delivered'];
    final currentIndex = steps.indexOf(status.toLowerCase());
    
    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;
        
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.primary : AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? AppTheme.primary : Colors.white24,
                      ),
                    ),
                    child: isCompleted 
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index].toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isCompleted ? AppTheme.primary : Colors.white12,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
