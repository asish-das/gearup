import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gearup/mobile_user/main_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/live_tracking_map.dart';

class ServiceTrackingScreen extends StatefulWidget {
  final bool isEmergency;
  final String? serviceName;
  final String? trackingId;

  const ServiceTrackingScreen({
    super.key,
    this.isEmergency = false,
    this.serviceName,
    this.trackingId,
  });

  @override
  State<ServiceTrackingScreen> createState() => _ServiceTrackingScreenState();
}

class _ServiceTrackingScreenState extends State<ServiceTrackingScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.isEmergency ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.backgroundDark,
          title: const Text(
            'Service Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Routine Service'),
              Tab(text: 'Emergency Request'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                );
              },
              tooltip: 'Back to Home',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Routine Service Tab
            _buildRoutineServiceTab(),
            // Emergency Request Tab
            _buildEmergencyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineServiceTab() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please log in to track services',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser!.uid)
          // We can't orderBy unless we have a composite index, so we sort in memory
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildNoActiveService();
        }

        // Sort by appointmentDate descending manually
        final sortedDocs = docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate =
                (aData['appointmentDate'] as Timestamp?)?.toDate() ??
                (aData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                (bData['appointmentDate'] as Timestamp?)?.toDate() ??
                (bData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

        // Try to find an active one, otherwise just show latest
        QueryDocumentSnapshot? activeDoc;
        try {
          activeDoc = sortedDocs.firstWhere((doc) {
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
          });
        } catch (e) {
          // If no active booking found, use the latest one
          activeDoc = sortedDocs.isNotEmpty ? sortedDocs.first : null;
        }

        if (activeDoc != null) {
          return _buildBookingProgress(activeDoc);
        } else {
          return _buildNoActiveService();
        }
      },
    );
  }

  Widget _buildNoActiveService() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) setState(() {});
      },
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height:
              MediaQuery.of(context).size.height -
              150, // Ensure enough height to scroll
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 80,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Recent Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have no active services currently being tracked.',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingProgress(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'PENDING';
    final vehicle = data['vehicle'] ?? 'Unknown Vehicle';
    final service = data['service'] ?? 'General Service';
    final deliveryOption = data['deliveryOption'] as String?;

    double progressVal = (data['progressVal'] ?? 0.0).toDouble();
    if (status == 'PENDING') {
      progressVal = -0.1;
    } else if (status == 'ACCEPTED') {
      progressVal = 0.0;
    } else if (status == 'DIAGNOSTICS') {
      progressVal = 0.25;
    } else if (status == 'IN_PROGRESS' || status == 'IN SERVICE') {
      progressVal = 0.5;
    } else if (status == 'TESTING') {
      progressVal = 0.75;
    } else if (status == 'COMPLETED') {
      progressVal = 1.0;
    }

    final isRejected = status == 'REJECTED';
    final isCompleted = status == 'COMPLETED';

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) setState(() {});
      },
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBr7wk28RrPX4KcQ5ArovZK7lQ45_yrnIN5OL8xKr_6NQPK-v6eHCtKJAUG5ClosQfMnm9iJNf_M5-sFuqSEwf2ACFnIcECeZXYHvwU6ggl9pyCgxV0y2LoEwiVNdd6DHTkpvUJJcHzsQ2pPBAuAGEudo3pyOfjPE-ESafoUwwfFteRunQ0OpFcKYeK9dG2FO-MhMiT7Soxl1HZeQz2rymbSKAnJlCn8eutNkTRCoegElLE4vn5d5GomiOMi-D5wb1N6ZN42t_TbWI',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isRejected
                                      ? Colors.red
                                      : isCompleted
                                      ? AppTheme.successGreen
                                      : AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status,
                                style: TextStyle(
                                  color: isRejected
                                      ? Colors.red
                                      : isCompleted
                                      ? AppTheme.successGreen
                                      : AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$vehicle - $service',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (data['serviceCenterId'] != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(data['serviceCenterId'].toString())
                                  .get(),
                              builder: (context, centerSnapshot) {
                                if (centerSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                
                                String centerName = 'GearUp Service Center';
                                String? centerPhone;

                                if (centerSnapshot.hasData && centerSnapshot.data!.exists) {
                                  final centerData = centerSnapshot.data!.data() as Map<String, dynamic>?;
                                  if (centerData != null) {
                                    centerName = centerData['name'] ?? centerData['fullName'] ?? 'GearUp Service Center';
                                    centerPhone = centerData['phoneNumber'] ?? centerData['phone'];
                                  }
                                }

                                return Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.storefront,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Service Center',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            centerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
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
                                        if (centerPhone != null &&
                                            centerPhone.isNotEmpty) {
                                          _makePhoneCall(centerPhone);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Contact info not available',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.call,
                                        size: 16,
                                      ),
                                      label: Text(
                                        centerPhone ?? 'Call',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          if (data['technicianName'] != null && data['technicianName'].toString().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Technician',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        data['technicianName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                    foregroundColor: AppTheme.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () {
                                    final techPhone = data['technicianPhone'];
                                    if (techPhone != null &&
                                        techPhone.toString().isNotEmpty) {
                                      _makePhoneCall(techPhone.toString());
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Contact info not available',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.call,
                                    size: 16,
                                  ),
                                  label: Text(
                                    (data['technicianPhone'] ?? 'Call').toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Live syncing...',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTimelineItem(
                    Icons.check_circle,
                    progressVal >= 0.0 ? AppTheme.successGreen : Colors.white38,
                    'Service Approved',
                    progressVal >= 0.0 ? 'Approved and booked' : 'Awaiting...',
                    isLineSolid: progressVal > 0.0,
                    lineColor: progressVal > 0.0
                        ? AppTheme.successGreen
                        : Colors.white38,
                    isActive: progressVal == 0.0,
                  ),
                  _buildTimelineItem(
                    Icons.settings_suggest,
                    progressVal >= 0.25
                        ? AppTheme.successGreen
                        : Colors.white38,
                    'Diagnostics & Checking',
                    progressVal >= 0.25 ? 'Completed' : 'Pending',
                    isLineSolid: progressVal > 0.25,
                    lineColor: progressVal > 0.25
                        ? AppTheme.successGreen
                        : Colors.white38,
                    isActive: progressVal == 0.25,
                  ),
                  _buildTimelineItem(
                    Icons.build,
                    progressVal >= 0.5 ? AppTheme.successGreen : Colors.white38,
                    'Servicing in Progress',
                    progressVal >= 0.5 ? 'Completed' : 'Pending',
                    isLineSolid: progressVal > 0.5,
                    lineColor: progressVal > 0.5
                        ? AppTheme.successGreen
                        : Colors.white38,
                    isActive: progressVal == 0.50,
                  ),
                  _buildTimelineItem(
                    Icons.done_all,
                    progressVal >= 0.75
                        ? AppTheme.successGreen
                        : Colors.white38,
                    'Final Testing',
                    progressVal >= 0.75 ? 'Completed' : 'Pending',
                    isLineSolid: progressVal > 0.75,
                    lineColor: progressVal > 0.75
                        ? AppTheme.successGreen
                        : Colors.white38,
                    isActive: progressVal == 0.75,
                  ),
                  _buildTimelineItem(
                    Icons.local_shipping,
                    isCompleted ? AppTheme.successGreen : Colors.white38,
                    'Ready to Delivery',
                    isCompleted ? 'Completed' : 'Pending',
                    isLineSolid: false,
                    isLast: true,
                    isActive: progressVal >= 1.0,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Updates',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Today, ${DateFormat('hh:mm a').format(DateTime.now())}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRejected
                          ? 'This service has been rejected by the service center.'
                          : isCompleted
                          ? 'Service successfully completed!'
                          : status == 'PENDING'
                          ? 'Your service is pending confirmation by the service center.'
                          : status == 'ACCEPTED'
                          ? 'Your service has been approved by the service center.'
                          : 'Service is currently progressing at ${(progressVal * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white54,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isCompleted && deliveryOption == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Service Complete! Choose receiving method:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(doc.id)
                                .update({'deliveryOption': 'pickup'}),
                            icon: const Icon(
                              Icons.storefront,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Self Pickup',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(doc.id)
                                .update({'deliveryOption': 'delivery'}),
                            icon: const Icon(
                              Icons.delivery_dining,
                              color: AppTheme.backgroundDark,
                            ),
                            label: const Text(
                              'Delivery',
                              style: TextStyle(color: AppTheme.backgroundDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else if (isCompleted && deliveryOption != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      deliveryOption == 'pickup'
                          ? Icons.storefront
                          : Icons.delivery_dining,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected: ${deliveryOption.toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MainNavigation(initialIndex: isCompleted ? 4 : 0),
                  ),
                  (route) => false,
                );
              },
              icon: Icon(isCompleted ? Icons.receipt_long : Icons.home),
              label: Text(
                isCompleted ? 'View Receipt in History' : 'Back to Home',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted
                    ? AppTheme.accent
                    : AppTheme.primary,
                foregroundColor: isCompleted
                    ? AppTheme.backgroundDark
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTab() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please log in to track emergencies',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergencies')
          .where('userId', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        // Filter for active ones (PENDING or DISPATCHED)
        final activeDocs = docs.where((doc) {
          final status =
              (doc.data() as Map<String, dynamic>)['status'] ?? 'PENDING';
          return status == 'PENDING' || status == 'DISPATCHED';
        }).toList();

        if (activeDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppTheme.successGreen.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Emergencies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Everything is looking good right now.',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final emergencyDoc = activeDocs.first;
        final data = emergencyDoc.data() as Map<String, dynamic>;
        return _buildActiveEmergency(data, emergencyDoc.id);
      },
    );
  }

  Widget _buildActiveEmergency(Map<String, dynamic> data, String id) {
    final status = data['status'] ?? 'PENDING';
    final service = data['serviceType'] ?? 'Emergency Assistance';
    final personnel = data['dispatchedPersonnel'] as Map<String, dynamic>?;
    final isDispatched = status == 'DISPATCHED';

    LatLng? userLocation;
    if (data['location'] != null && data['location'] is GeoPoint) {
      final geo = data['location'] as GeoPoint;
      userLocation = LatLng(geo.latitude, geo.longitude);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency,
                          color: Colors.redAccent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Request ID: $id',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (data['serviceCenterId'] != null) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(data['serviceCenterId'].toString())
                          .get(),
                      builder: (context, centerSnapshot) {
                        if (centerSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        String centerName = 'Service Center';
                        String? centerPhone;

                        if (centerSnapshot.hasData && centerSnapshot.data!.exists) {
                          final centerData = centerSnapshot.data!.data() as Map<String, dynamic>?;
                          if (centerData != null) {
                            centerName = centerData['name'] ?? centerData['fullName'] ?? 'Service Center';
                            centerPhone = centerData['phoneNumber'] ?? centerData['phone'];
                          }
                        }

                        return Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Assigned Center',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    centerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                if (centerPhone != null && centerPhone.isNotEmpty) {
                                  _makePhoneCall(centerPhone);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contact info not available'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.call, size: 16),
                              label: Text(
                                centerPhone ?? 'Call',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: data['serviceCenterId'] == null
                    ? LiveTrackingMap(
                        trackingId: id,
                        userLocation: userLocation,
                      )
                    : FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['serviceCenterId'].toString())
                            .get(),
                        builder: (context, centerSnapshot) {
                          LatLng? centerLocation;
                          if (centerSnapshot.hasData && centerSnapshot.data!.exists) {
                            final cData = centerSnapshot.data!.data() as Map<String, dynamic>?;
                            if (cData != null && cData['location'] is GeoPoint) {
                              final cGeo = cData['location'] as GeoPoint;
                              centerLocation = LatLng(cGeo.latitude, cGeo.longitude);
                            }
                          }
                          return LiveTrackingMap(
                            trackingId: id,
                            userLocation: userLocation,
                            serviceCenterLocation: centerLocation,
                          );
                        },
                      ),
              ),
            ),
          ),
          if (personnel != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personnel['name'] ?? 'Unknown Responder',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            personnel['vehicleNo'] ?? 'No vehicle details',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final contact = personnel['contact'];
                        if (contact != null && contact.toString().isNotEmpty) {
                          _makePhoneCall(contact.toString());
                        }
                      },
                      icon: const Icon(Icons.call, size: 16),
                      label: Text(
                        (personnel['contact'] ?? 'Call').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rescue Team Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildTimelineItem(
                  Icons.location_on,
                  Colors.green,
                  'Request Received',
                  'Waiting for dispatch',
                  isLineSolid: isDispatched,
                  lineColor: isDispatched ? Colors.green : Colors.white24,
                  isActive: status == 'PENDING',
                ),
                _buildTimelineItem(
                  Icons.directions_car,
                  isDispatched ? Colors.blue : Colors.white24,
                  'Team Dispatched',
                  isDispatched ? 'Rescue team is on the way' : 'Pending...',
                  isLineSolid: false,
                  lineColor: Colors.white24,
                  isActive: isDispatched,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle, {
    bool isLineSolid = false,
    Color? lineColor,
    bool isLast = false,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? iconColor.withValues(alpha: 0.2)
                    : isLineSolid
                    ? iconColor.withValues(alpha: 0.1)
                    : Colors.white10,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? iconColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? iconColor
                    : isLineSolid
                    ? iconColor
                    : Colors.white38,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isLineSolid ? (lineColor ?? iconColor) : Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isActive || isLineSolid
                      ? Colors.white
                      : Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isActive ? iconColor : Colors.white54,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
