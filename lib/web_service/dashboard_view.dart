import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  final List<Map<String, dynamic>> _recentBookings = const [
    {
      'initials': 'AW',
      'name': 'Alex Walker',
      'email': 'alex.w@example.com',
      'vehicle': '2021 Toyota Corolla',
      'service': 'Full Maintenance',
      'status': 'Pending',
      'statusColor': Colors.amber,
    },
    {
      'initials': 'SJ',
      'name': 'Sarah Johnson',
      'email': 'sarah.j@example.com',
      'vehicle': '2019 Honda CR-V',
      'service': 'Brake Replacement',
      'status': 'In Progress',
      'statusColor': Colors.blue,
    },
    {
      'initials': 'MR',
      'name': 'Michael Ross',
      'email': 'm.ross@example.com',
      'vehicle': '2022 Ford F-150',
      'service': 'Oil Change',
      'status': 'Pending',
      'statusColor': Colors.amber,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      color: const Color(0xFFF6F6F8),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              bool isSmall = constraints.maxWidth < 900;

              Widget searchBar = Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search customer, vehicle or invoice...',
                          hintStyle: GoogleFonts.manrope(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              Widget searchAndProfile = Row(
                children: [
                  Expanded(child: searchBar),
                  const SizedBox(width: 24),
                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        color: Color(0xFF64748B),
                        size: 28,
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.person, color: Color(0xFF64748B)),
                  ),
                ],
              );

              Widget titleText = StreamBuilder<DocumentSnapshot>(
                stream: uid != null
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .snapshots()
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

              return isSmall
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleText,
                        const SizedBox(height: 16),
                        searchAndProfile,
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        titleText,
                        SizedBox(width: 450, child: searchAndProfile),
                      ],
                    );
            },
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _buildStatCard(
                  'Today\'s Bookings',
                  '8',
                  '+5%',
                  Icons.calendar_today,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Pending Bookings',
                  '3',
                  '-2%',
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed Services',
                  '12',
                  '+10%',
                  Icons.check_circle_outline,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Total Revenue',
                  '\$1,240',
                  '+15%',
                  Icons.attach_money,
                  Colors.green,
                ),
              ];

              if (constraints.maxWidth < 600) {
                return Column(
                  children: cards
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: c,
                        ),
                      )
                      .toList(),
                );
              } else if (constraints.maxWidth < 1100) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[1]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: cards[2]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[3]),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 24),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 24),
                  Expanded(child: cards[2]),
                  const SizedBox(width: 24),
                  Expanded(child: cards[3]),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                Container(
                  width: double.infinity,
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
                            'Booking Calendar',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                DateFormat('MMMM yyyy').format(DateTime.now()),
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF0F172A),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDayCol(
                              '${DateFormat('EE').format(DateTime.now().subtract(const Duration(days: 2)).toLocal()).toUpperCase()} ${DateFormat('dd').format(DateTime.now().subtract(const Duration(days: 2)).toLocal())}',
                              [
                                _buildCalEvent(
                                  '09:00 AM',
                                  'Oil Change',
                                  Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildDayCol(
                              '${DateFormat('EE').format(DateTime.now().subtract(const Duration(days: 1)).toLocal()).toUpperCase()} ${DateFormat('dd').format(DateTime.now().subtract(const Duration(days: 1)).toLocal())}',
                              [
                                _buildCalEvent(
                                  '10:30 AM',
                                  'Brake\nInspection',
                                  Colors.purple,
                                  sub: 'BMW X5',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildDayCol(
                              '${DateFormat('EE').format(DateTime.now()).toUpperCase()} ${DateFormat('dd').format(DateTime.now())}',
                              [
                                _buildCalEvent(
                                  '08:00 AM',
                                  'Tire\nRotation',
                                  Colors.teal,
                                  sub: 'Tesla Model 3',
                                ),
                                _buildCalEvent(
                                  '02:00 PM',
                                  'Engine\nTuning',
                                  Colors.orange,
                                  sub: 'Ford Raptor',
                                ),
                              ],
                              isActive: true,
                            ),
                          ),
                          Expanded(
                            child: _buildDayCol(
                              '${DateFormat('EE').format(DateTime.now().add(const Duration(days: 1)).toLocal()).toUpperCase()} ${DateFormat('dd').format(DateTime.now().add(const Duration(days: 1)).toLocal())}',
                              [],
                            ),
                          ),
                          Expanded(
                            child: _buildDayCol(
                              '${DateFormat('EE').format(DateTime.now().add(const Duration(days: 2)).toLocal()).toUpperCase()} ${DateFormat('dd').format(DateTime.now().add(const Duration(days: 2)).toLocal())}',
                              [
                                _buildCalEvent(
                                  '11:00 AM',
                                  'Diagnostics',
                                  Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildDayCol(
                              '${DateFormat('EE').format(DateTime.now().add(const Duration(days: 3)).toLocal()).toUpperCase()} ${DateFormat('dd').format(DateTime.now().add(const Duration(days: 3)).toLocal())}',
                              [],
                            ),
                          ),
                          Expanded(
                            child: _buildDayCol(
                              '${DateFormat('EE').format(DateTime.now().add(const Duration(days: 4)).toLocal()).toUpperCase()} ${DateFormat('dd').format(DateTime.now().add(const Duration(days: 4)).toLocal())}',
                              [],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
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
                              'Recent Bookings',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'View All',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5D40D4),
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
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          color: Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('CUSTOMER', style: _headerStyle()),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('VEHICLE', style: _headerStyle()),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'SERVICE TYPE',
                                style: _headerStyle(),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('STATUS', style: _headerStyle()),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('ACTIONS', style: _headerStyle()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentBookings.length,
                        itemBuilder: (context, index) {
                          final booking = _recentBookings[index];
                          return _buildTableRow(
                            booking['initials'] as String,
                            booking['name'] as String,
                            booking['email'] as String,
                            booking['vehicle'] as String,
                            booking['service'] as String,
                            booking['status'] as String,
                            booking['statusColor'] as MaterialColor,
                          );
                        },
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

  Widget _buildStatCard(
    String title,
    String value,
    String percent,
    IconData icon,
    MaterialColor color,
  ) {
    bool isPositive = percent.startsWith('+');
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color.shade500, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  percent,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCol(
    String title,
    List<Widget> events, {
    bool isActive = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF5D40D4) : const Color(0xFF94A3B8),
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 2,
            color: const Color(0xFF5D40D4),
          )
        else
          const SizedBox(height: 10),
        const SizedBox(height: 16),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF8FAFC) : Colors.transparent,
            border: Border(left: BorderSide(color: const Color(0xFFF1F5F9))),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: events,
          ),
        ),
      ],
    );
  }

  Widget _buildCalEvent(
    String time,
    String title,
    MaterialColor color, {
    String sub = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color.shade500, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
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
          const Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
