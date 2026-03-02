import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/live_tracking_map.dart';

class ServiceTrackingScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: isEmergency ? 1 : 0,
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
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
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
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'IN PROGRESS',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'GearUp Professional Tuning',
                          style: TextStyle(
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
                                    'Alex Rivera',
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
                        'Refreshed 2m ago',
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
                  AppTheme.successGreen,
                  'Arrived at Workshop',
                  'Completed at 10:30 AM',
                  isLineSolid: true,
                  lineColor: AppTheme.successGreen,
                ),
                _buildTimelineItem(
                  Icons.check_circle,
                  AppTheme.successGreen,
                  'Inspecting Components',
                  'Completed at 11:15 AM',
                  isLineSolid: true,
                  lineColor: AppTheme.successGreen,
                ),
                _buildTimelineItem(
                  Icons.settings_suggest,
                  AppTheme.primary,
                  'Servicing Gear System',
                  'Active — Estimated 45 mins left',
                  isLineSolid: true,
                  lineColor: AppTheme.primary.withValues(alpha: 0.2),
                  isActive: true,
                ),
                _buildTimelineItem(
                  Icons.schedule,
                  Colors.white38,
                  'Final Testing & Safety Check',
                  'Scheduled for later',
                  isLineSolid: false,
                  isLast: true,
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
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Estimated Completion',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Today, 2:30 PM',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'ve identified a minor alignment issue in the derailleur which is being corrected now. No extra parts needed.',
                    style: TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    if (!isEmergency && serviceName == null) {
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
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'EMERGENCY DISPATCH',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    serviceName ?? 'Emergency Service Request',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A specialized unit has been dispatched to your location.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Driver / Technician',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Michael B.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FloatingActionButton.small(
                        backgroundColor: Colors.redAccent,
                        onPressed: () {},
                        child: const Icon(Icons.call, color: Colors.white),
                      ),
                    ],
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
                  'Live Unit Tracking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LiveTrackingMap(
                    trackingId:
                        trackingId ??
                        'emergency_${serviceName?.replaceAll(" ", "_") ?? "generic"}',
                    isDriver: false,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Live Progression',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildTimelineItem(
                  Icons.check_circle,
                  AppTheme.successGreen,
                  'Request Received',
                  'Processed instantly',
                  isLineSolid: true,
                  lineColor: AppTheme.successGreen,
                ),
                _buildTimelineItem(
                  Icons.map,
                  Colors.redAccent,
                  'Unit Dispatched to Location',
                  'Active — Driver is en route (5 mins away)',
                  isLineSolid: true,
                  lineColor: Colors.redAccent.withValues(alpha: 0.3),
                  isActive: true,
                  activeColor: Colors.redAccent,
                ),
                _buildTimelineItem(
                  Icons.home_repair_service,
                  Colors.white38,
                  'On-Site Assistance',
                  'Waiting for arrival',
                  isLineSolid: false,
                  lineColor: Colors.white24,
                ),
                _buildTimelineItem(
                  Icons.flag,
                  Colors.white38,
                  'Service Completed',
                  'Pending',
                  isLineSolid: false,
                  isLast: true,
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
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Estimated Arrival time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'In 5 Minutes',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stay near your vehicle and keep your hazard lights on if safe to do so.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle, {
    bool isLineSolid = true,
    Color? lineColor,
    bool isLast = false,
    bool isActive = false,
    Color? activeColor,
  }) {
    Color progressColor = activeColor ?? AppTheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor == Colors.white38
                    ? Colors.transparent
                    : iconColor,
                shape: BoxShape.circle,
                border: iconColor == Colors.white38
                    ? Border.all(color: Colors.white38, width: 2)
                    : null,
              ),
              child: Icon(
                icon,
                color: iconColor == Colors.white38
                    ? Colors.white38
                    : Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: lineColor ?? Colors.white24,
                margin: const EdgeInsets.symmetric(vertical: 4),
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
                  color: isActive ? progressColor : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              if (isActive) ...[
                const SizedBox(height: 12),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.66,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
