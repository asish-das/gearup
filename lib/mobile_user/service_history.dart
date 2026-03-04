import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: const Center(
          child: Text(
            'Please log in to view history.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.backgroundDark,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'Service History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Past Services'),
              Tab(text: 'Upcoming'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No services found.',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            final sortedDocs = docs.toList()
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aDate =
                    (aData['appointmentDate'] as Timestamp?)?.toDate() ??
                    (aData['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final bDate =
                    (bData['appointmentDate'] as Timestamp?)?.toDate() ??
                    (bData['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                return bDate.compareTo(aDate);
              });

            final pastDocs = sortedDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] as String?)?.toUpperCase() ?? '';
              return ['COMPLETED', 'REJECTED', 'CANCELLED'].contains(status);
            }).toList();

            final upcomingDocs = sortedDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] as String?)?.toUpperCase() ?? '';
              return [
                'PENDING',
                'ACCEPTED',
                'DIAGNOSTICS',
                'IN_PROGRESS',
                'IN SERVICE',
                'TESTING',
              ].contains(status);
            }).toList();

            return TabBarView(
              children: [
                _buildList(pastDocs, isPast: true),
                _buildList(upcomingDocs, isPast: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs, {required bool isPast}) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          isPast ? 'No past services found.' : 'No upcoming services found.',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;

        final title = data['service'] ?? 'General Service';
        final vehicle = data['vehicle'] ?? 'Unknown Vehicle';
        final status = data['status'] ?? 'UNKNOWN';
        final price = data['amount'] != null
            ? '\$${(data['amount'] as num).toStringAsFixed(2)}'
            : '\$0.00';
        final date =
            (data['appointmentDate'] as Timestamp?)?.toDate() ??
            (data['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now();
        final dateStr = DateFormat('MMM dd, yyyy').format(date);
        final location = data['serviceCenterName'] ?? 'GearUp Service Center';

        // Dynamic icon logic
        IconData icon = Icons.settings_suggest;
        if (title.toLowerCase().contains('oil')) {
          icon = Icons.oil_barrel;
        }
        if (title.toLowerCase().contains('brake') ||
            title.toLowerCase().contains('tire')) {
          icon = Icons.tire_repair;
        }

        return _buildServiceEntry(
          title: title,
          subtitle: vehicle,
          status: status,
          date: dateStr,
          location: location,
          price: price,
          icon: icon,
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBr7wk28RrPX4KcQ5ArovZK7lQ45_yrnIN5OL8xKr_6NQPK-v6eHCtKJAUG5ClosQfMnm9iJNf_M5-sFuqSEwf2ACFnIcECeZXYHvwU6ggl9pyCgxV0y2LoEwiVNdd6DHTkpvUJJcHzsQ2pPBAuAGEudo3pyOfjPE-ESafoUwwfFteRunQ0OpFcKYeK9dG2FO-MhMiT7Soxl1HZeQz2rymbSKAnJlCn8eutNkTRCoegElLE4vn5d5GomiOMi-D5wb1N6ZN42t_TbWI',
          isFirst: index == 0,
          isLast: index == docs.length - 1,
          data: data,
          isPast: isPast,
        );
      },
    );
  }

  Widget _buildServiceEntry({
    required String title,
    required String subtitle,
    required String status,
    required String date,
    required String location,
    required String price,
    required IconData icon,
    required String imageUrl,
    required bool isFirst,
    required bool isLast,
    required Map<String, dynamic> data,
    required bool isPast,
  }) {
    Color statusColor = AppTheme.accent;
    if (status.toUpperCase() == 'REJECTED' ||
        status.toUpperCase() == 'CANCELLED') {
      statusColor = Colors.red;
    }
    if (status.toUpperCase() == 'PENDING') {
      statusColor = Colors.orange;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: 0,
                    child: Container(width: 2, color: const Color(0xFF4d3267)),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.backgroundDark,
                      width: 4,
                    ),
                  ),
                  child: Icon(icon, color: AppTheme.accent, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date • $location',
                    style: const TextStyle(fontSize: 13, color: Colors.white54),
                  ),
                  const SizedBox(height: 12),

                  // Service Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF261933),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4d3267)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Image(
                          image: CachedNetworkImageProvider(imageUrl),
                          width: double.infinity,
                          height: 128,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPast ? 'Total Paid' : 'Amount',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (status.toUpperCase() == 'COMPLETED')
                                ElevatedButton.icon(
                                  onPressed: () => _viewReceipt(
                                    title,
                                    subtitle,
                                    location,
                                    price,
                                    date,
                                    data,
                                  ),
                                  icon: const Icon(
                                    Icons.receipt_long,
                                    color: AppTheme.accent,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'View Receipt',
                                    style: TextStyle(color: AppTheme.accent),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary
                                        .withValues(alpha: 0.2),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewReceipt(
    String title,
    String subtitle,
    String location,
    String price,
    String date,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Receipt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                _receiptRow('Service', title),
                _receiptRow('Vehicle', subtitle),
                _receiptRow('Center', location),
                _receiptRow('Date', date),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Paid',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
