import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingsManagerView extends StatelessWidget {
  const BookingsManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Actions
              if (isMobile || isTablet)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopActions(isMobile: isMobile),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bookings',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    _buildTopActions(isMobile: false),
                  ],
                ),

              const SizedBox(height: 32),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab('All Bookings', true),
                    const SizedBox(width: 32),
                    _buildTab('Scheduled', false),
                    const SizedBox(width: 32),
                    _buildTab('In Progress', false),
                    const SizedBox(width: 32),
                    _buildTab('Completed', false),
                    const SizedBox(width: 32),
                    _buildTab('Cancelled', false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Table List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, tableConstraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1200),
                          child: SizedBox(
                            width: tableConstraints.maxWidth > 1200
                                ? tableConstraints.maxWidth
                                : 1200,
                            child: Column(
                              children: [
                                _buildTableHeader(),
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('bookings')
                                        .orderBy(
                                          'appointmentDate',
                                          descending: true,
                                        )
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return const Center(
                                          child: Text('Error loading bookings'),
                                        );
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return const Center(
                                          child: Text('No bookings found'),
                                        );
                                      }

                                      final bookings = snapshot.data!.docs;

                                      return ListView.builder(
                                        itemCount: bookings.length,
                                        itemBuilder: (context, index) {
                                          final doc = bookings[index];
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;

                                          String id = doc.id.length > 6
                                              ? doc.id
                                                    .substring(0, 6)
                                                    .toUpperCase()
                                              : doc.id.toUpperCase();
                                          String customer =
                                              data['name'] ??
                                              'Unknown Customer';
                                          String center =
                                              data['serviceCenterName'] ??
                                              'Unknown Center';
                                          String type =
                                              data['service'] ??
                                              'General Service';
                                          String status =
                                              data['status'] ?? 'PENDING';

                                          String dateStr = 'Unknown Date';
                                          if (data['appointmentDate'] != null) {
                                            DateTime dt =
                                                (data['appointmentDate']
                                                        as Timestamp)
                                                    .toDate();
                                            dateStr = DateFormat(
                                              'MMM dd, hh:mm a',
                                            ).format(dt);
                                          }

                                          String payment =
                                              status.toUpperCase() ==
                                                  'COMPLETED'
                                              ? 'Paid'
                                              : 'Pending';
                                          String amountStr =
                                              data['amount'] != null
                                              ? data['amount'].toString()
                                              : '0.00';
                                          if (!amountStr.startsWith('\$')) {
                                            amountStr = '\$$amountStr';
                                          }

                                          MaterialColor statusColor =
                                              Colors.grey;
                                          if (status.toUpperCase() ==
                                              'PENDING') {
                                            statusColor = Colors.amber;
                                          } else if (status.toUpperCase() ==
                                              'ACCEPTED') {
                                            statusColor = Colors.blue;
                                          } else if (status.toUpperCase() ==
                                              'IN SERVICE') {
                                            statusColor = Colors.orange;
                                          } else if (status.toUpperCase() ==
                                              'COMPLETED') {
                                            statusColor = Colors.green;
                                          } else if (status.toUpperCase() ==
                                              'CANCELLED') {
                                            statusColor = Colors.red;
                                          }

                                          return _buildTableRow(
                                            '#$id',
                                            customer,
                                            center,
                                            type,
                                            status,
                                            dateStr,
                                            payment,
                                            amountStr,
                                            statusColor,
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
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopActions({required bool isMobile}) {
    final actions = [
      Container(
        height: 48,
        width: isMobile ? double.infinity : 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search bookings...',
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
      ),
      if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF0F172A),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd').format(DateTime(DateTime.now().year, DateTime.now().month, 1))} - ${DateFormat('MMM dd').format(DateTime(DateTime.now().year, DateTime.now().month + 1, 0))}',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more, color: Color(0xFF64748B), size: 18),
          ],
        ),
      ),
      if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        width: isMobile ? double.infinity : null,
        decoration: BoxDecoration(
          color: const Color(0xFF5D40D4),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D40D4).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_download, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Export',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions,
      );
    } else {
      return Row(children: actions);
    }
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('BOOKING ID', style: _headerStyle())),
          Expanded(flex: 3, child: Text('CUSTOMER', style: _headerStyle())),
          Expanded(
            flex: 3,
            child: Text('SERVICE CENTER', style: _headerStyle()),
          ),
          Expanded(flex: 3, child: Text('SERVICE TYPE', style: _headerStyle())),
          Expanded(flex: 2, child: Text('STATUS', style: _headerStyle())),
          Expanded(flex: 2, child: Text('DATE/TIME', style: _headerStyle())),
          Expanded(
            flex: 2,
            child: Text('PAYMENT STATUS', style: _headerStyle()),
          ),
          Expanded(flex: 2, child: Text('AMOUNT', style: _headerStyle())),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? const Color(0xFF5D40D4) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          color: isActive ? const Color(0xFF5D40D4) : const Color(0xFF64748B),
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
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
    String id,
    String customer,
    String center,
    String type,
    String status,
    String date,
    String payment,
    String amount,
    MaterialColor statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              id,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D40D4),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF1F5F9),
                  radius: 16,
                  child: Icon(Icons.person, color: Color(0xFF94A3B8), size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  customer,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              type,
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
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.shade100,
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
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: payment == 'Paid'
                        ? Colors.green
                        : (payment == 'Refunded' ? Colors.red : Colors.grey),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  payment,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
