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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(serviceCenterName),
      ),
      body: serviceCenterId == null
          ? const Center(
              child: Text(
                'Invalid Service Center',
                style: TextStyle(color: Colors.red),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(serviceCenterId)
                  .collection('services')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading services',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final services = snapshot.data?.docs ?? [];

                if (services.isEmpty) {
                  return const Center(
                    child: Text(
                      'No services available at this center.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final data = services[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildServiceTile(
                        context,
                        data['title'] ?? 'Unknown Service',
                        data['description'] ?? 'No description available',
                        '\$${data['price'] ?? 0}',
                        Icons
                            .build, // Default icon, you can make this dynamic if stored
                        serviceCenterId,
                        serviceCenterName,
                      ),
                    );
                  },
                );
              },
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
