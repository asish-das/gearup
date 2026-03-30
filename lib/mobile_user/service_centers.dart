import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCentersScreen extends StatefulWidget {
  const ServiceCentersScreen({super.key});

  @override
  State<ServiceCentersScreen> createState() => _ServiceCentersScreenState();
}

class _ServiceCentersScreenState extends State<ServiceCentersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Nearest'; // Nearest, Rating, Popular, Open Now

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      // AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Service Centers',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search service centers...',
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
              children: [
                _buildFilterButton('Nearest', isSelected: _selectedFilter == 'Nearest'),
                const SizedBox(width: 12),
                _buildFilterButton('Rating', isSelected: _selectedFilter == 'Rating'),
                const SizedBox(width: 12),
                _buildFilterButton('Popular', isSelected: _selectedFilter == 'Popular'),
                const SizedBox(width: 12),
                _buildFilterButton('Open Now', isSelected: _selectedFilter == 'Open Now'),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'serviceCenter')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading centers',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                // Filtering in memory so we don't need composite indexes until ready
                // and to allow 'pending' or 'active' for easy testing.
                var centers = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status']?.toString().toLowerCase();
                  final name =
                      (data['businessName'] ?? data['name'] ?? '')
                          .toString()
                          .toLowerCase();

                  final matchesStatus =
                      status == 'approved' ||
                      status == 'active' ||
                      status == 'pending';
                  final matchesSearch =
                      name.contains(_searchQuery.toLowerCase());

                  return matchesStatus && matchesSearch;
                }).toList();

                // Sort logic
                if (_selectedFilter == 'Rating') {
                  centers.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aRating = (aData['rating'] as num?)?.toDouble() ?? 0.0;
                    final bRating = (bData['rating'] as num?)?.toDouble() ?? 0.0;
                    return bRating.compareTo(aRating);
                  });
                } else if (_selectedFilter == 'Popular') {
                  centers.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aCount = (aData['reviewsCount'] as num?)?.toInt() ?? 0;
                    final bCount = (bData['reviewsCount'] as num?)?.toInt() ?? 0;
                    return bCount.compareTo(aCount);
                  });
                }

                if (centers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No service centers found.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: centers.length,
                  itemBuilder: (context, index) {
                    final data = centers[index].data() as Map<String, dynamic>;
                    final docId = centers[index].id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCenterCard(
                        context: context,
                        uid: docId,
                        name:
                            data['businessName']?.toString().isNotEmpty == true
                            ? data['businessName']
                            : (data['name'] ?? 'Unknown Center'),
                        distance: data['address']?.toString().isNotEmpty == true
                            ? data['address']
                            : 'Location not specified',
                        description:
                            data['description']?.toString().isNotEmpty == true
                            ? data['description']
                            : 'Professional vehicle maintenance and repair services.',
                        rating: data['rating'] != null 
                            ? (data['rating'] as num).toDouble().toStringAsFixed(1)
                            : 'New',
                        imageUrl:
                            data['profileImageUrl']?.toString().isNotEmpty ==
                                true
                            ? data['profileImageUrl']
                            : 'https://images.unsplash.com/photo-1625047509168-a7026f36de04?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                        status:
                            (data['status']?.toString().toUpperCase() ??
                            'AVAILABLE'),
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
  }

  Widget _buildFilterButton(String label, {bool isSelected = false}) {
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              color: isSelected ? Colors.white : Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterCard({
    required BuildContext context,
    required String uid,
    required String name,
    required String distance,
    required String description,
    required String rating,
    required String imageUrl,
    String? status,
    Color statusColor = AppTheme.accent,
    String? customFooterStr,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/service_selection',
          arguments: {'serviceCenterId': uid, 'serviceCenterName': name},
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
            // Image
            Stack(
              children: [
                _buildDynamicImage(imageUrl),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              distance,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status != null)
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (customFooterStr != null)
                        Text(
                          customFooterStr,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        )
                      else
                        const SizedBox(), // Empty if null (can add avatar stack here if requested, but simplifying)

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/service_selection',
                            arguments: {
                              'serviceCenterId': uid,
                              'serviceCenterName': name,
                            },
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
                          'Book Now',
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

  Widget _buildDynamicImage(String source) {
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
}
