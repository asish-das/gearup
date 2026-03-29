import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final serviceCenterId = args?['serviceCenterId'] as String?;
    final serviceCenterName =
        args?['serviceCenterName'] as String? ?? 'Select Service';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: serviceCenterId == null
          ? const Center(
              child: Text(
                'Invalid Service Center',
                style: TextStyle(color: Colors.red),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(serviceCenterId)
                  .snapshots(),
              builder: (context, centerSnapshot) {
                if (centerSnapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading center info',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (centerSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final centerData =
                    centerSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final description =
                    centerData['description'] ??
                    'Professional vehicle maintenance and repair services.';
                final hours =
                    centerData['operatingHours'] as Map<String, dynamic>? ?? {};

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: AppTheme.backgroundDark,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          serviceCenterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildHeaderImage(centerData['profileImageUrl']),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.backgroundDark.withValues(alpha: 0.8),
                                    AppTheme.backgroundDark,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildOperatingHours(hours),
                            const SizedBox(height: 32),
                            const Text(
                              'Available Services',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(serviceCenterId)
                          .collection('services')
                          .where('isActive', isEqualTo: true)
                          .snapshots(),
                      builder: (context, servicesSnapshot) {
                        if (servicesSnapshot.hasError) {
                          return const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'Error loading services',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }

                        if (servicesSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          );
                        }

                        final services = servicesSnapshot.data?.docs ?? [];

                        if (services.isEmpty) {
                          return const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No services available at this center.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final data =
                                services[index].data() as Map<String, dynamic>;
                            String priceStr = data['price'] ?? '0';
                            if (!priceStr.startsWith('\$')) {
                              priceStr = '\$$priceStr';
                            }

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _buildServiceTile(
                                context,
                                data['title'] ??
                                    data['name'] ??
                                    'Unknown Service',
                                data['desc'] ??
                                    data['description'] ??
                                    'No description available',
                                priceStr,
                                Icons.build,
                                serviceCenterId,
                                serviceCenterName,
                              ),
                            );
                          }, childCount: services.length),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildOperatingHours(Map<String, dynamic> hours) {
    if (hours.isEmpty) return const SizedBox();

    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Operating Hours',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...days.map((day) {
            final dayData = hours[day] as Map<String, dynamic>?;
            if (dayData == null) return const SizedBox();

            final isOpen = dayData['isOpen'] ?? false;
            final openTime = dayData['open'] ?? '--';
            final closeTime = dayData['close'] ?? '--';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: isOpen ? Colors.white : Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    isOpen ? '$openTime - $closeTime' : 'Closed',
                    style: TextStyle(
                      color: isOpen ? AppTheme.primary : Colors.white24,
                      fontSize: 13,
                      fontWeight: isOpen ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    String name,
    String desc,
    String price,
    IconData icon,
    String? serviceCenterId,
    String? serviceCenterName,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/booking',
          arguments: {
            'name': name,
            'desc': desc,
            'price': price,
            'serviceCenterId': serviceCenterId,
            'serviceCenterName': serviceCenterName,
          },
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String? source) {
    if (source == null || source.isEmpty) {
      return Container(
        color: AppTheme.primary.withValues(alpha: 0.1),
      );
    }

    if (source.startsWith('data:image')) {
      try {
        final base64Str = source.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        );
      } catch (e) {
        return Container(
          color: AppTheme.primary.withValues(alpha: 0.1),
        );
      }
    }

    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppTheme.primary.withValues(alpha: 0.1),
      ),
    );
  }
}
