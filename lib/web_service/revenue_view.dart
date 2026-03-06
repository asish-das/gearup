import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RevenueView extends StatefulWidget {
  const RevenueView({super.key});

  @override
  State<RevenueView> createState() => _RevenueViewState();
}

class _RevenueViewState extends State<RevenueView> {
  bool _isLoading = true;
  double _todayRevenue = 0;
  double _weeklyRevenue = 0;
  double _monthlyRevenue = 0;
  double _totalRevenue = 0;
  double _avgOrderValue = 0;
  String _topService = 'None';
  int _topServiceCount = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<double> _chartData = List.filled(7, 0.0);
  List<String> _chartLabels = List.filled(7, '');
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _revenueSubscription;
  bool _isShowingHistory = false;
  String _txSearchQuery = '';
  String _selectedTxFilter = 'All';
  List<Map<String, dynamic>> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _initializePlaceholders();
    _startRevenueListener();
  }

  void _showNotifications() {
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
                    'Recent Activity',
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
                              'No recent notifications',
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
  void dispose() {
    _revenueSubscription?.cancel();
    super.dispose();
  }

  void _initializePlaceholders() {
    final today = DateTime.now();
    List<String> labels = [];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      labels.add(DateFormat('E').format(d));
    }
    setState(() {
      _chartLabels = labels;
    });
  }

  void _startRevenueListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    _revenueSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceCenterId', isEqualTo: user.uid)
        .snapshots()
        .listen((querySnapshot) {
          if (!mounted) return;

          try {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final startOfWeek = today.subtract(
              Duration(days: today.weekday - 1),
            );
            final startOfMonth = DateTime(now.year, now.month, 1);

            // For chart labels (stays same unless date changes, but good to refresh)
            List<String> labels = [];
            for (int i = 6; i >= 0; i--) {
              final d = today.subtract(Duration(days: i));
              labels.add(DateFormat('E').format(d));
            }

            // Sort in-memory to avoid mandatory index requirement
            final sortedDocs = querySnapshot.docs.toList()
              ..sort((a, b) {
                final aDate =
                    (a.data()['appointmentDate'] as Timestamp?)?.toDate() ??
                    DateTime(2000);
                final bDate =
                    (b.data()['appointmentDate'] as Timestamp?)?.toDate() ??
                    DateTime(2000);
                return bDate.compareTo(aDate);
              });

            double todayRev = 0;
            double weekRev = 0;
            double monthRev = 0;
            double totalRev = 0;
            List<double> dailyRev = List.filled(7, 0.0);
            int totalBookings = sortedDocs.length;
            Map<String, int> serviceCounts = {};
            List<Map<String, dynamic>> transactions = [];

            for (var doc in sortedDocs) {
              final data = doc.data();
              final amount = (data['amount'] ?? 0.0).toDouble();
              final status = data['status'] ?? 'PENDING';
              final appointmentDate =
                  (data['appointmentDate'] as Timestamp?)?.toDate() ??
                  DateTime(2000);
              final apptDay = DateTime(
                appointmentDate.year,
                appointmentDate.month,
                appointmentDate.day,
              );
              final service =
                  data['serviceName'] ?? data['service'] ?? 'Unknown';

              totalRev += amount;

              if (apptDay == today) {
                todayRev += amount;
              }
              if (appointmentDate.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              )) {
                weekRev += amount;
              }
              if (appointmentDate.isAfter(
                startOfMonth.subtract(const Duration(seconds: 1)),
              )) {
                monthRev += amount;
              }

              // Chart data (last 7 days)
              final diffDays = today.difference(apptDay).inDays;
              if (diffDays >= 0 && diffDays < 7) {
                dailyRev[6 - diffDays] += amount;
              }

              serviceCounts[service] = (serviceCounts[service] ?? 0) + 1;

              final tx = {
                'docId': doc.id,
                'id': doc.id.substring(0, 8).toUpperCase(),
                'date': DateFormat(
                  'MMM dd, yyyy HH:mm',
                ).format(appointmentDate),
                'rawDate': appointmentDate,
                'customer': data['customerName'] ?? data['name'] ?? 'Customer',
                'userId': data['userId'], // Added userId for notifications
                'amount': amount,
                'displayAmount': '\$${amount.toStringAsFixed(2)}',
                'status': status,
                'paymentStatus': data['paymentStatus'] ?? 'PENDING',
                'paymentMethod': data['paymentMethod'] ?? 'N/A',
                'service': service,
                'contact': data['contact'] ?? 'No contact',
                'color': _getStatusColor(status),
                'paymentColor': _getPaymentStatusColor(
                  data['paymentStatus'] ?? 'PENDING',
                ),
              };
              transactions.add(tx);
            }

            String topSrv = 'None';
            int topSrvCnt = 0;
            serviceCounts.forEach((srv, srvCount) {
              if (srvCount > topSrvCnt) {
                topSrvCnt = srvCount;
                topSrv = srv;
              }
            });

            setState(() {
              _todayRevenue = todayRev;
              _weeklyRevenue = weekRev;
              _monthlyRevenue = monthRev;
              _totalRevenue = totalRev;
              _avgOrderValue = totalBookings > 0 ? totalRev / totalBookings : 0;
              _topService = topSrv;
              _topServiceCount = topSrvCnt;
              _allTransactions = transactions;
              _recentTransactions = transactions.take(10).toList();
              _chartData = dailyRev;
              _chartLabels = labels;
              _errorMessage = null;
              _isLoading = false;
            });
          } catch (e) {
            debugPrint('Error processing revenue stream: $e');
            setState(() {
              _errorMessage = e.toString();
              _isLoading = false;
            });
          }
        });
  }

  MaterialColor _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
      case 'CONFIRMED':
        return Colors.amber;
      case 'REFUNDED':
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  MaterialColor _getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'REFUNDED':
        return Colors.red;
      case 'PENDING':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refundTransaction(Map<String, dynamic> tx) async {
    final docId = tx['docId'];
    final userId = tx['userId'];
    final serviceName = tx['service'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Refund',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to refund this transaction for ${tx['customer']}? This action will mark the payment as REFUNDED and notify the user.',
          style: GoogleFonts.manrope(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm Refund',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Update booking status
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .update({'paymentStatus': 'REFUNDED'});

        // 2. Create notification for the user
        if (userId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': userId,
            'title': 'Transaction Refunded',
            'body':
                'Your payment of ${tx['displayAmount']} for $serviceName has been refunded.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'refund',
            'relatedDocId': docId,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction Refunded and User Notified.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refund failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 24,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Details',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: #${tx['id'] ?? 'N/A'}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: const Color(0xFF818CF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // New Organized Info Section
              _buildDetailRow(
                Icons.person_outline_rounded,
                'Customer',
                tx['customer'] ?? 'Unknown',
                const Color(0xFF38BDF8),
              ),
              _buildDetailRow(
                Icons.handyman_outlined,
                'Service Rendering',
                tx['service'] ?? 'General Service',
                const Color(0xFFFB7185),
              ),
              _buildDetailRow(
                Icons.calendar_today_rounded,
                'Date & Time',
                tx['date'] ?? '--',
                const Color(0xFF34D399),
              ),
              _buildDetailRow(
                Icons.payments_outlined,
                'Amount Paid',
                tx['displayAmount'] ?? '₹0.00',
                const Color(0xFFFBBF24),
              ),
              _buildDetailRow(
                Icons.account_balance_wallet_outlined,
                'Payment Method',
                tx['paymentMethod'] ?? 'N/A',
                const Color(0xFFA78BFA),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Status Badges
              Row(
                children: [
                  Expanded(
                    child: _buildStatusBadge(
                      'Booking Status',
                      tx['status'] ?? 'PENDING',
                      tx['color'] ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusBadge(
                      'Payment Status',
                      tx['paymentStatus'] ?? 'PENDING',
                      tx['paymentColor'] ?? Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              if (tx['paymentStatus'] != 'REFUNDED' &&
                  tx['paymentStatus'] == 'PAID')
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _refundTransaction(tx);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        'Process Refund',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),

              if (tx['paymentStatus'] == 'REFUNDED')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Transaction Refunded',
                        style: GoogleFonts.manrope(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String title, String status, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Center(
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFF6F6F8),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error: $_errorMessage\n(Tip: Check if Firestore composite indices are created in Firebase Console)',
                      style: GoogleFonts.manrope(
                        color: Colors.red.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Analytics',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  _buildTabButton('Overview', !_isShowingHistory, () {
                    setState(() => _isShowingHistory = false);
                  }),
                  const SizedBox(width: 8),
                  _buildTabButton('Transaction History', _isShowingHistory, () {
                    setState(() => _isShowingHistory = true);
                  }),
                  const SizedBox(width: 24),
                  const VerticalDivider(width: 1, indent: 10, endIndent: 10),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _revenueSubscription?.cancel();
                      _startRevenueListener();
                    },
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseAuth.instance.currentUser?.uid != null
                        ? FirebaseFirestore.instance
                              .collection('notifications')
                              .where(
                                'userId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              )
                              .where('isRead', isEqualTo: false)
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      bool hasUnread =
                          snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                      return Stack(
                        children: [
                          IconButton(
                            onPressed: () => _showNotifications(),
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF64748B),
                              size: 26,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (hasUnread)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.person, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          if (!_isShowingHistory) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "TODAY'S REVENUE",
                    value: '\$${_todayRevenue.toStringAsFixed(2)}',
                    subtitle: 'Confirmed earnings today',
                    badgeText: 'Live',
                    isPositive: true,
                    icon: Icons.today,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildMetricCard(
                    title: 'THIS WEEK',
                    value: '\$${_weeklyRevenue.toStringAsFixed(2)}',
                    subtitle: 'Total revenue this week',
                    badgeText:
                        '+${(_weeklyRevenue / (_totalRevenue > 0 ? _totalRevenue : 1) * 100).toStringAsFixed(1)}%',
                    isPositive: true,
                    icon: Icons.calendar_view_week,
                    iconColor: const Color(0xFF5D40D4),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildMetricCard(
                    title: 'THIS MONTH',
                    value: '\$${_monthlyRevenue.toStringAsFixed(2)}',
                    subtitle: 'Monthly accumulated',
                    badgeText: '~',
                    isPositive: true,
                    icon: Icons.calendar_month,
                    iconColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Chart Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 7 Days Revenue',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (index) {
                        final value = _chartData[index];
                        final maxValue = _chartData.reduce(
                          (a, b) => a > b ? a : b,
                        );
                        final heightFactor = maxValue > 0
                            ? value / maxValue
                            : 0.0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 30,
                              height: (120 * heightFactor).clamp(4, 120),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D40D4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _chartLabels[index],
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'LIFETIME REVENUE',
                    value: '\$${_totalRevenue.toStringAsFixed(2)}',
                    subtitle: 'Total historical earnings',
                    badgeText: 'All Time',
                    isPositive: true,
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildMetricCard(
                    title: 'AVG. ORDER VALUE',
                    value: '\$${_avgOrderValue.toStringAsFixed(2)}',
                    subtitle: 'Per booking average',
                    badgeText: '~',
                    isPositive: true,
                    icon: Icons.analytics,
                    iconColor: Colors.teal,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOP SERVICE',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const Icon(Icons.star, color: Color(0xFF5D40D4)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _topService,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_topServiceCount bookings',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Transaction Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _isShowingHistory = true),
                            child: Text(
                              'View All',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF5D40D4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTransactionsHeader(),
                    Expanded(
                      child: _recentTransactions.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: _recentTransactions.length,
                              itemBuilder: (context, index) =>
                                  _buildTxRow(_recentTransactions[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: TextField(
                                onChanged: (val) =>
                                    setState(() => _txSearchQuery = val),
                                decoration: InputDecoration(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF64748B),
                                  ),
                                  hintText:
                                      'Search transactions by ID, customer or service...',
                                  hintStyle: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildFilterBadge(
                            'All',
                            _selectedTxFilter == 'All',
                            () {
                              setState(() => _selectedTxFilter = 'All');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterBadge(
                            'Paid',
                            _selectedTxFilter == 'Paid',
                            () {
                              setState(() => _selectedTxFilter = 'Paid');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterBadge(
                            'Pending',
                            _selectedTxFilter == 'Pending',
                            () {
                              setState(() => _selectedTxFilter = 'Pending');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterBadge(
                            'Refunded',
                            _selectedTxFilter == 'Refunded',
                            () {
                              setState(() => _selectedTxFilter = 'Refunded');
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildTransactionsHeader(),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filtered = _allTransactions.where((tx) {
                            final matchSearch =
                                tx['id'].toLowerCase().contains(
                                  _txSearchQuery.toLowerCase(),
                                ) ||
                                tx['customer'].toLowerCase().contains(
                                  _txSearchQuery.toLowerCase(),
                                ) ||
                                tx['service'].toLowerCase().contains(
                                  _txSearchQuery.toLowerCase(),
                                );

                            bool matchFilter = true;
                            if (_selectedTxFilter == 'Paid') {
                              matchFilter = tx['paymentStatus'] == 'PAID';
                            } else if (_selectedTxFilter == 'Pending') {
                              matchFilter = tx['paymentStatus'] == 'PENDING';
                            } else if (_selectedTxFilter == 'Refunded') {
                              matchFilter = tx['paymentStatus'] == 'REFUNDED';
                            }

                            return matchSearch && matchFilter;
                          }).toList();

                          if (filtered.isEmpty) return _buildEmptyState();

                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildTxRow(filtered[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String badgeText,
    required String subtitle,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
              Icon(icon, color: iconColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? const Color(0xFF10B981) : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF94A3B8),
      letterSpacing: 1.1,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No transactions found',
        style: GoogleFonts.manrope(color: Colors.grey),
      ),
    );
  }

  Widget _buildTransactionsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('TRANSACTION ID', style: _headerStyle()),
          ),
          Expanded(flex: 2, child: Text('DATE', style: _headerStyle())),
          Expanded(flex: 3, child: Text('CUSTOMER', style: _headerStyle())),
          Expanded(flex: 2, child: Text('AMOUNT', style: _headerStyle())),
          Expanded(flex: 2, child: Text('STATUS', style: _headerStyle())),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF5D40D4).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF5D40D4) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBadge(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5D40D4) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF5D40D4) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTxRow(Map<String, dynamic> tx) {
    final statusColor = tx['color'] as MaterialColor;
    final paymentColor = tx['paymentColor'] as MaterialColor;
    final bool isRefunded = tx['paymentStatus'] == 'REFUNDED';

    return InkWell(
      onTap: () => _showTransactionDetails(tx),
      hoverColor: const Color(0xFFF8FAFC),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (tx['customer'] as String?)?.isNotEmpty == true
                            ? tx['customer'][0]
                            : '?',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${tx['id'] ?? 'N/A'}',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tx['service'] ?? 'General Service',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                tx['date'] ?? '--',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['customer'] ?? 'Unknown Customer',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    tx['contact'] ?? 'No contact info',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                tx['displayAmount'] ?? '\$0.00',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isRefunded ? Colors.red : const Color(0xFF0F172A),
                  decoration: isRefunded ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildMiniBadge(tx['status'] ?? 'PENDING', statusColor),
                  _buildMiniBadge(
                    tx['paymentStatus'] ?? 'PENDING',
                    paymentColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.shade700,
        ),
      ),
    );
  }
}
