import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  void _showNotifications(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 450,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: uid)
                      .orderBy('timestamp', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: GoogleFonts.manrope(color: Colors.white38),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final data =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        final type = data['type'] ?? 'info';
                        IconData iconData = Icons.info_outline;
                        Color iconColor = Colors.blue;

                        if (type == 'refund') {
                          iconData = Icons.refresh_rounded;
                          iconColor = Colors.red;
                        } else if (type == 'booking') {
                          iconData = Icons.calendar_today_rounded;
                          iconColor = Colors.green;
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: iconColor, size: 20),
                          ),
                          title: Text(
                            data['title'] ?? 'Notification',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                data['body'] ?? '',
                                style: GoogleFonts.manrope(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['timestamp'] != null
                                    ? DateFormat('MMM dd, hh:mm a').format(
                                        (data['timestamp'] as Timestamp)
                                            .toDate(),
                                      )
                                    : '',
                                style: GoogleFonts.manrope(
                                  color: Colors.white24,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: uid != null
          ? FirebaseFirestore.instance
                .collection('bookings')
                .where('serviceCenterId', isEqualTo: uid)
                .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        int todayBookings = 0;
        int pendingBookings = 0;
        int completedServices = 0;
        double totalRevenue = 0;
        List<Map<String, dynamic>> recentBookings = [];

        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final docs = snapshot.data!.docs;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'PENDING')
                .toString()
                .toUpperCase();
            final appointmentDate =
                (data['appointmentDate'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final apptDay = DateTime(
              appointmentDate.year,
              appointmentDate.month,
              appointmentDate.day,
            );
            final amount = (data['amount'] ?? 0.0).toDouble();

            if (apptDay == today) todayBookings++;
            if (status == 'PENDING') pendingBookings++;
            if (status == 'COMPLETED') completedServices++;
            if (status == 'COMPLETED') totalRevenue += amount;
          }

          // Sort and take latest 5 for the table
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              final aDate =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bDate =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              return (bDate ?? Timestamp.now()).compareTo(
                aDate ?? Timestamp.now(),
              );
            });

          recentBookings = sortedDocs.take(5).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['customerName'] ?? data['name'] ?? 'Unknown';
            return {
              'initials': name.isNotEmpty ? name[0].toUpperCase() : '?',
              'name': name,
              'email': data['contact'] ?? 'No contact',
              'vehicle': data['vehicle'] ?? 'Unknown Vehicle',
              'service': data['service'] ?? 'General Service',
              'status': data['status'] ?? 'Pending',
              'statusColor': _getStatusColor(data['status'] ?? 'Pending'),
            };
          }).toList();
        }

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(uid),
                const SizedBox(height: 32),
                _buildStatsGrid(
                  todayBookings,
                  pendingBookings,
                  completedServices,
                  totalRevenue,
                ),
                const SizedBox(height: 32),
                _buildRecentBookings(recentBookings),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String? uid) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmall = constraints.maxWidth < 900;
        return isSmall
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(uid),
                  const SizedBox(height: 16),
                  _buildSearchAndProfile(uid),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTitle(uid),
                  SizedBox(width: 450, child: _buildSearchAndProfile(uid)),
                ],
              );
      },
    );
  }

  Widget _buildTitle(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: uid != null
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        String name = "Garage";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['businessName'] ?? data['name'] ?? "Garage";
        }
        return Text(
          "Welcome back, $name",
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndProfile(String? uid) {
    return Row(
      children: [
        Expanded(child: _buildSearchBox()),
        const SizedBox(width: 24),
        StreamBuilder<QuerySnapshot>(
          stream: uid != null
              ? FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: uid)
                    .where('isRead', isEqualTo: false)
                    .snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
            return InkWell(
              onTap: () => _showNotifications(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF64748B),
                      size: 28,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE2E8F0),
          child: Icon(Icons.person, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          hintText: 'Search customer, vehicle or invoice...',
          hintStyle: GoogleFonts.manrope(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    int today,
    int pending,
    int completed,
    double revenue,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildStatCard(
            'Today\'s Bookings',
            today.toString(),
            'Live',
            Icons.calendar_today_rounded,
            Colors.purple,
          ),
          _buildStatCard(
            'Pending Bookings',
            pending.toString(),
            'Action Required',
            Icons.pending_actions_rounded,
            Colors.orange,
          ),
          _buildStatCard(
            'Completed Services',
            completed.toString(),
            'Success',
            Icons.check_circle_outline_rounded,
            Colors.teal,
          ),
          _buildStatCard(
            'Total Revenue',
            '₹${revenue.toStringAsFixed(0)}',
            'Growth',
            Icons.account_balance_wallet_rounded,
            Colors.green,
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: constraints.maxWidth < 600
              ? 1
              : (constraints.maxWidth < 1200 ? 2 : 4),
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 2.2,
          children: cards,
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String trend,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trend,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
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

  Widget _buildRecentBookings(List<Map<String, dynamic>> bookings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Bookings',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D40D4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (bookings.isEmpty)
            _buildEmptyBookings()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return _buildTableRow(
                  b['initials'],
                  b['name'],
                  b['email'],
                  b['vehicle'],
                  b['service'],
                  b['status'],
                  b['statusColor'],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBookings() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Text(
              'No recent bookings found',
              style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(
    String initials,
    String name,
    String email,
    String vehicle,
    String service,
    String status,
    MaterialColor statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.manrope(
                        color: statusColor.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              vehicle,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              service,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MaterialColor _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'IN SERVICE':
      case 'DIAGNOSTICS':
      case 'TESTING':
        return Colors.blue;
      case 'REJECTED':
      case 'CANCELLED':
      case 'REFUNDED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
