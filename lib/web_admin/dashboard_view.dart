import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class DashboardView extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardView({super.key, this.onNavigate});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeCenters = 0;
  int _totalBookings = 0;
  double _monthlyRevenue = 0;

  // Chart data
  List<double> _revenueData = List.filled(7, 0.0);
  List<double> _bookingData = List.filled(7, 0.0);
  List<String> _chartLabels = List.filled(7, '');

  final TextEditingController _searchController = TextEditingController();
  String _dashboardSearchQuery = '';

  StreamSubscription? _usersSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _recentBookingsSub;
  List<Map<String, dynamic>> _recentBookings = [];

  @override
  void initState() {
    super.initState();
    _startListeners();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _bookingsSub?.cancel();
    _recentBookingsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startListeners() {
    // Listen to users for counts
    _usersSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          int users = 0;
          int centers = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final role = data['role'];
            final status = data['status'];

            if (role == 'vehicleOwner') {
              users++;
            } else if (role == 'serviceCenter' && status == 'active') {
              centers++;
            }
          }

          setState(() {
            _totalUsers = users;
            _activeCenters = centers;
          });
        });

    // Listen to bookings for total, revenue and chart data
    _bookingsSub = FirebaseFirestore.instance
        .collection('bookings')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final today = DateTime(now.year, now.month, now.day);

          double mRevenue = 0;
          List<double> rData = List.filled(7, 0.0);
          List<double> bData = List.filled(7, 0.0);
          List<String> labels = [];

          for (int i = 6; i >= 0; i--) {
            final d = today.subtract(Duration(days: i));
            labels.add(DateFormat('E').format(d));
          }

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = data['status'] ?? 'PENDING';
            final timestamp = data['appointmentDate'] as Timestamp?;
            final amount = (data['amount'] ?? 0.0).toDouble();
            if (timestamp != null) {
              final date = timestamp.toDate();
              final apptDay = DateTime(date.year, date.month, date.day);

              // Only count COMPLETED bookings for revenue
              if (status == 'COMPLETED' &&
                  date.isAfter(
                    startOfMonth.subtract(const Duration(seconds: 1)),
                  )) {
                mRevenue += amount;
              }

              final diffDays = today.difference(apptDay).inDays;
              if (diffDays >= 0 && diffDays < 7) {
                if (status == 'COMPLETED') {
                  rData[6 - diffDays] += amount;
                }
                bData[6 - diffDays] += 1;
              }
            }
          }

          setState(() {
            _totalBookings = snapshot.docs.length;
            _monthlyRevenue = mRevenue;
            _revenueData = rData;
            _bookingData = bData;
            _chartLabels = labels;
          });
        });

    // Listen to recent bookings
    _recentBookingsSub = FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(20) // Get more to allow client-side search filtering
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            _recentBookings = snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();
            _isLoading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Area
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 600;
                return isSmall
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 16),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildActionIcons(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTitle(),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: _buildSearchBar(),
                            ),
                          ),
                          _buildActionIcons(),
                        ],
                      );
              },
            ),
            const SizedBox(height: 32),

            // Stats Row / Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                int crossAxisCount = 4;
                if (width < 600) {
                  crossAxisCount = 1;
                } else if (width < 900) {
                  crossAxisCount = 2;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: width < 600 ? 2.5 : 1.5,
                  children: [
                    _buildStatCard(
                      'Total Users',
                      NumberFormat.compact().format(_totalUsers),
                      Icons.people_alt_rounded,
                      const Color(0xFF4F46E5),
                      const Color(0xFF818CF8),
                      'Total',
                    ),
                    _buildStatCard(
                      'Active Centers',
                      _activeCenters.toString(),
                      Icons.handyman_rounded,
                      const Color(0xFF0ea5e9),
                      const Color(0xFF38bdf8),
                      'Live',
                    ),
                    _buildStatCard(
                      'Bookings',
                      NumberFormat.compact().format(_totalBookings),
                      Icons.calendar_month_rounded,
                      const Color(0xFFF59E0B),
                      const Color(0xFFFCD34D),
                      'All Time',
                    ),
                    _buildStatCard(
                      'Monthly Revenue',
                      NumberFormat.simpleCurrency(
                        decimalDigits: 0,
                      ).format(_monthlyRevenue),
                      Icons.attach_money_rounded,
                      const Color(0xFF10B981),
                      const Color(0xFF34D399),
                      'This Month',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Charts Area
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 1000;
                final revenueChart = _buildRevenueChart();
                final bookingChart = _buildBookingChart();

                return isSmall
                    ? Column(
                        children: [
                          SizedBox(height: 400, child: revenueChart),
                          const SizedBox(height: 24),
                          SizedBox(height: 400, child: bookingChart),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: SizedBox(height: 420, child: revenueChart),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: SizedBox(height: 420, child: bookingChart),
                          ),
                        ],
                      );
              },
            ),

            const SizedBox(height: 32),

            // Recent Bookings Table
            _buildRecentBookings(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Here\'s what\'s happening today.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _dashboardSearchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search bookings by customer or center...',
                hintStyle: GoogleFonts.manrope(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_dashboardSearchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _dashboardSearchQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      children: [
        _buildIconButton(Icons.notifications_none_rounded),
        const SizedBox(width: 16),
        _buildIconButton(Icons.chat_bubble_outline_rounded),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF64748B), size: 22),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Analysis',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Cumulative earnings across all regions',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'Last 7 Days',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF334155),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _RevenueChartPainter(_revenueData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Trend',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(child: _buildBarChart()),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgGradientStart,
    Color bgGradientEnd,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bgGradientStart, bgGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: bgGradientStart.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF059669),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    double maxVal = _bookingData.fold(0.0, (m, e) => e > m ? e : m);
    if (maxVal == 0) maxVal = 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final double value = _bookingData[index];
        final String label = _chartLabels.length > index
            ? _chartLabels[index]
            : '';
        final bool isToday = index == 6;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 16,
              height: (value / maxVal) * 150, // Proportional height
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF5D40D4)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                color: isToday
                    ? const Color(0xFF5D40D4)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRecentBookings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Bookings',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onNavigate?.call(3); // Navigate to Bookings
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D40D4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_recentBookings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'No recent bookings found.',
                  style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
                ),
              ),
            )
          else
            _buildBookingsTable(),
        ],
      ),
    );
  }

  Widget _buildBookingsTable() {
    final filtered = _recentBookings
        .where((b) {
          if (_dashboardSearchQuery.isEmpty) return true;
          final customer = (b['customerName'] ?? b['userName'] ?? '')
              .toLowerCase();
          final center = (b['serviceCenterName'] ?? b['centerName'] ?? '')
              .toLowerCase();
          final id = (b['id'] ?? '').toLowerCase();
          return customer.contains(_dashboardSearchQuery) ||
              center.contains(_dashboardSearchQuery) ||
              id.contains(_dashboardSearchQuery);
        })
        .take(10)
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'No matches found for "$_dashboardSearchQuery"',
            style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dataRowMinHeight: 64,
        dataRowMaxHeight: 72,
        columns: [
          DataColumn(
            label: Text(
              'Customer',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Service Type',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Center',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Date',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Amount',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: filtered.map((booking) {
          final status = booking['status'] ?? 'PENDING';
          Color statusColor;
          switch (status) {
            case 'COMPLETED':
              statusColor = const Color(0xFF10B981);
              break;
            case 'IN SERVICE':
              statusColor = const Color(0xFF3B82F6);
              break;
            case 'REFUNDED':
              statusColor = const Color(0xFFF43F5E);
              break;
            default:
              statusColor = const Color(0xFFF59E0B);
          }

          final dateStr =
              (booking['appointmentDate'] as Timestamp?)?.toDate() ??
              DateTime.now();

          return DataRow(
            cells: [
              DataCell(
                Text(
                  booking['customerName'] ?? booking['userName'] ?? 'Unknown',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  booking['serviceName'] ??
                      booking['serviceType'] ??
                      'General Service',
                ),
              ),
              DataCell(
                Text(
                  booking['serviceCenterName'] ??
                      booking['centerName'] ??
                      'N/A',
                ),
              ),
              DataCell(Text(DateFormat('MMM dd, yyyy').format(dateStr))),
              DataCell(Text('\$${booking['amount'] ?? 0}')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  final List<double> data;
  _RevenueChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF5D40D4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF5D40D4).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    double maxVal = data.fold(0.0, (m, e) => e > m ? e : m);
    if (maxVal == 0) maxVal = 1;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y =
          size.height -
          (data[i] / maxVal) *
              size.height *
              0.8; // Use 80% height to avoid edge
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Curve the line slightly if possible, but keeping it simple for now
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = const Color(0xFF5D40D4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y = size.height - (data[i] / maxVal) * size.height * 0.8;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.data != data;
}
