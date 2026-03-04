import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gearup/mobile_user/main_navigation.dart';
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
                DateTime.now();
            final bDate =
                (bData['appointmentDate'] as Timestamp?)?.toDate() ??
                DateTime.now();
            return bDate.compareTo(aDate);
          });

        // Try to find an active one, otherwise just show latest
        QueryDocumentSnapshot? activeDoc;
        try {
          activeDoc = sortedDocs.firstWhere((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            return status == 'PENDING' || status == 'IN_PROGRESS';
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
    return Center(
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
    );
  }

  Widget _buildBookingProgress(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'PENDING';
    final vehicle = data['vehicle'] ?? 'Unknown Vehicle';
    final service = data['service'] ?? 'General Service';
    final progressVal = (data['progressVal'] ?? 0.0).toDouble();

    final isRejected = status == 'REJECTED';
    final isCompleted = status == 'COMPLETED';

    return SingleChildScrollView(
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
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.2),
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
                                children: const [
                                  Text(
                                    'Technician',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'GearUp Staff',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FloatingActionButton.small(
                              backgroundColor: AppTheme.primary,
                              onPressed: () {},
                              child: const Icon(
                                Icons.call,
                                color: Colors.white,
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
                  progressVal >= 0.25 ? AppTheme.successGreen : Colors.white38,
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
                  progressVal >= 0.75 ? AppTheme.successGreen : Colors.white38,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    if (!widget.isEmergency && widget.serviceName == null) {
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

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
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
                              widget.serviceName ?? 'Emergency Assistance',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Request ID: ${widget.trackingId ?? 'Unknown'}',
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
                ],
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LiveTrackingMap(
                  trackingId: widget.trackingId ?? 'emergency_tracking',
                ),
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
                  Colors.redAccent,
                  'Team Dispatched',
                  'Started 10 mins ago',
                  isLineSolid: true,
                  lineColor: Colors.redAccent,
                ),
                _buildTimelineItem(
                  Icons.directions_car,
                  Colors.redAccent,
                  'On The Way',
                  'Active — ETA: 15 mins',
                  isLineSolid: true,
                  lineColor: Colors.redAccent.withValues(alpha: 0.2),
                  isActive: true,
                ),
                _buildTimelineItem(
                  Icons.handshake,
                  Colors.white38,
                  'Arrived at Location',
                  'Pending',
                  isLineSolid: false,
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
