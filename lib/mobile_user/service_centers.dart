import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ServiceCentersScreen extends StatelessWidget {
  const ServiceCentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      // AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundDark.withOpacity(
          0.8,
        ), // Instead of withOpacity(0.8), standard transparency handle
        title: const Text(
          'GearUp Service Centers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu, color: AppTheme.primary, size: 20),
          ),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterButton('Nearest', isSelected: true),
                const SizedBox(width: 12),
                _buildFilterButton('Rating'),
                const SizedBox(width: 12),
                _buildFilterButton('Open Now'),
                const SizedBox(width: 12),
                _buildFilterButton('Price'),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCenterCard(
                  name: 'Speedy Auto Care',
                  distance: '1.2 miles away • Downtown Hub',
                  description:
                      'Expert maintenance for all luxury and performance gear. State-of-the-art diagnostic tools.',
                  rating: '4.8',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAu4gZNyYevjnp06ETfWRrdIhl1oUtantlkielsVMaeqNlm0mxRL61heh7NUOkL4QS_tK9DNSRL_rXAmotcBKQNPbxZ56vzZjlIuLh4exqunRof52ZAtUMeY98rQPVignqnnOocCm5sZWwE_L3Ywpy_uX6EQhJITsPh3g4DgF6ukC7H8YAMCf6uSTmUAzAFUsWxl4rySu3iEH8ZAGKvpXgIbgostPy8xGeifStalIdkO_uEYyWnZRaVnwklh2BKhE2xsrNMHDnCrl4',
                  status: 'AVAILABLE',
                ),
                const SizedBox(height: 16),
                _buildCenterCard(
                  name: 'GearUp Elite Center',
                  distance: '2.5 miles away • West District',
                  description:
                      'Specializing in performance tuning and high-end diagnostics. Authorized GearUp Platinum Partner.',
                  rating: '4.9',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDAoimAE0GK98Y2wNkJBjpohX_uLJUd7_jhssoYSAS_qElG5y_EV5AznieWY8wU6lh9mOfbQ5qX6gj8znL-g1GkKtWoLJH3DDB3NbAWSR8ivvpxiA7XGPC8HMw7Km7UGSc2iP3yAH5aGfF0T0tIJJCri6Jn3ZcNsAAy6BgUUqGiWKtkNBXdGyWdBVN0ZVsPwK8XprlqonF2lLwuq32RUBgNGuTZPWhsSe-sX5khfX81Doh3yH4erUBRx022YY-AS3CvPdIdLPD5-S0',
                  status: 'TOP RATED',
                  statusColor: AppTheme.primary,
                ),
                const SizedBox(height: 16),
                _buildCenterCard(
                  name: 'Precision Motors',
                  distance: '3.8 miles away • East Industrial',
                  description:
                      'Quick service and express oil changes. No appointment needed for basic maintenance packages.',
                  rating: '4.7',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAHgvJ2ppTu2hYXeBmGA-7Zov3TMmFYm4kp0fMjZEyzERA9gPGyWZkVFeDzkrGlfwDKSD5GqP_zrq0wTtjTiqlL-1MWWVwiqb6a7Qvnx9WD9zNLEp6h5u2PhPtM5ZmI_gCFfRj6iWyxs3fSyrNcXyl09r37YcZa6kLnwENE63JSt7MUu-8XZC0EcFZ8MEoBvJQKvprRtHgvOxp5OALIbkrzNhyXyysf1Z5iLCsniztq24TeHD8uD5jlVhZ7lyGhBasFhZIMjv8-V6U',
                  customFooterStr: 'Open until 10:00 PM',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : const Color(0xFF261933),
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? null : Border.all(color: const Color(0xFF4d3267)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildCenterCard({
    required String name,
    required String distance,
    required String description,
    required String rating,
    required String imageUrl,
    String? status,
    Color statusColor = AppTheme.accent,
    String? customFooterStr,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF261933),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4d3267)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              Image(
                image: CachedNetworkImageProvider(imageUrl),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.backgroundDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
    );
  }
}
