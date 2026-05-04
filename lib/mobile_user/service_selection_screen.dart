import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  bool _isInitialized = false;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

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
                             if (centerData['phoneNumber'] != null || centerData['phone'] != null) ...[
                               Row(
                                 children: [
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         const Text(
                                           'Contact',
                                           style: TextStyle(
                                             color: Colors.white,
                                             fontSize: 18,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                         const SizedBox(height: 8),
                                         Text(
                                           (centerData['phoneNumber'] ?? centerData['phone']).toString(),
                                           style: const TextStyle(
                                             color: Colors.white70,
                                             fontSize: 14,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                   ElevatedButton.icon(
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: AppTheme.primary,
                                       foregroundColor: Colors.white,
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                       shape: RoundedRectangleBorder(
                                         borderRadius: BorderRadius.circular(20),
                                       ),
                                     ),
                                     onPressed: () {
                                       final phone = (centerData['phoneNumber'] ?? centerData['phone']).toString();
                                       if (phone.isNotEmpty) {
                                         _makePhoneCall(phone);
                                       }
                                     },
                                     icon: const Icon(Icons.call, size: 16),
                                     label: const Text(
                                       'Call',
                                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                     ),
                                   ),
                                 ],
                               ),
                               const SizedBox(height: 24),
                             ],
                             const SizedBox(height: 16),
                             _buildOperatingHours(hours),
                             const SizedBox(height: 16),
                           ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Services',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Curated for your vehicle',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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

                        var services = servicesSnapshot.data?.docs ?? [];
                        
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

                        return SliverMainAxisGroup(
                          slivers: [
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final data =
                                    services[index].data() as Map<String, dynamic>;
                                String priceStr = data['price']?.toString() ?? '0';
                                if (!priceStr.startsWith('₹') && !priceStr.startsWith('\$')) {
                                  priceStr = '₹$priceStr';
                                }

                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 400 + (index * 50)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOutQuint,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
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
                                      _getCategoryIcon(data['category']),
                                      data['category'] ?? 'General',
                                      serviceCenterId,
                                      serviceCenterName,
                                    ),
                                  ),
                                );
                              }, childCount: services.length),
                            ),
                          ],
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



  Color _getCategoryColor(String? category) {
    if (category == null) return AppTheme.primary;
    switch (category.toLowerCase()) {
      case 'wash': return Colors.blueAccent;
      case 'repair': return Colors.orangeAccent;
      case 'body': return Colors.purpleAccent;
      case 'tires': return Colors.redAccent;
      case 'battery': return Colors.yellowAccent;
      case 'ac': return Colors.cyanAccent;
      case 'engine': return Colors.tealAccent;
      default: return AppTheme.primary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.grid_view_rounded;
    switch (category.toLowerCase()) {
      case 'wash': return Icons.local_car_wash_rounded;
      case 'repair': return Icons.build_rounded;
      case 'body': return Icons.brush_rounded;
      case 'tires': return Icons.tire_repair_rounded;
      case 'battery': return Icons.battery_charging_full_rounded;
      case 'ac': return Icons.ac_unit_rounded;
      case 'engine': return Icons.engineering_rounded;
      default: return Icons.build_rounded;
    }
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
    String category,
    String? serviceCenterId,
    String? serviceCenterName,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: AppTheme.surface.withValues(alpha: 0.6),
          child: InkWell(
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
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Icon(icon, color: AppTheme.accent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getCategoryColor(category).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  color: _getCategoryColor(category),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

class FadeInTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeInTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

