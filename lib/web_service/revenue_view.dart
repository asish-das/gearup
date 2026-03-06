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

  @override
  void initState() {
    super.initState();
    _initializePlaceholders();
    _fetchRevenueData();
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

  Future<void> _fetchRevenueData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // For chart: last 7 days including today
      List<double> dailyRev = List.filled(7, 0.0);
      List<String> labels = [];
      for (int i = 6; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        labels.add(DateFormat('E').format(d));
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceCenterId', isEqualTo: user.uid)
          .get();

      // Sort in-memory to avoid the need for a manually created composite index in Firebase Console
      final sortedDocs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aDate =
              (a.data()['appointmentDate'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          final bDate =
              (b.data()['appointmentDate'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          return bDate.compareTo(aDate); // Descending order (latest first)
        });

      double todayRev = 0;
      double weekRev = 0;
      double monthRev = 0;
      double totalRev = 0;
      int totalBookings = sortedDocs.length;
      Map<String, int> serviceCounts = {};
      List<Map<String, dynamic>> transactions = [];

      for (var doc in sortedDocs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final status = data['status'] ?? 'PENDING';
        final appointmentDate =
            (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final apptDay = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
        );
        final service = data['serviceName'] ?? data['service'] ?? 'Unknown';

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

        if (transactions.length < 10) {
          transactions.add({
            'id': doc.id.substring(0, 8).toUpperCase(),
            'date': DateFormat('MMM dd, yyyy').format(appointmentDate),
            'customer': data['customerName'] ?? data['name'] ?? 'Customer',
            'amount': '\$${amount.toStringAsFixed(2)}',
            'status': status,
            'color': _getStatusColor(status),
          });
        }
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
        _recentTransactions = transactions;
        _chartData = dailyRev;
        _chartLabels = labels;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching revenue: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  MaterialColor _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
      case 'CONFIRMED':
        return Colors.amber;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchRevenueData,
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF64748B),
                    size: 28,
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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
                        Expanded(
                          flex: 2,
                          child: Text('DATE', style: _headerStyle()),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('CUSTOMER', style: _headerStyle()),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('AMOUNT', style: _headerStyle()),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('STATUS', style: _headerStyle()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _recentTransactions.isEmpty
                        ? Center(
                            child: Text(
                              'No transactions found',
                              style: GoogleFonts.manrope(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _recentTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = _recentTransactions[index];
                              return _buildTxRow(
                                tx['id'],
                                tx['date'],
                                tx['customer'],
                                tx['amount'],
                                tx['status'],
                                tx['color'],
                              );
                            },
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

  Widget _buildTxRow(
    String id,
    String date,
    String customer,
    String amount,
    String status,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '#$id',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              customer,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.shade500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color.shade700,
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
    );
  }
}
