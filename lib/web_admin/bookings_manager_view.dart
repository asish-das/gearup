import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingsManagerView extends StatefulWidget {
  const BookingsManagerView({super.key});

  @override
  State<BookingsManagerView> createState() => _BookingsManagerViewState();
}

class _BookingsManagerViewState extends State<BookingsManagerView> {
  String _selectedTab = 'All Bookings';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = [
    'All Bookings',
    'Scheduled',
    'In Progress',
    'Completed',
    'Cancelled',
    'Refunded',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                  children: _tabs.map((tab) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: _buildTab(tab, _selectedTab == tab),
                    );
                  }).toList(),
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
                                        .orderBy('createdAt', descending: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        );
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return const Center(
                                          child: Text('No bookings found'),
                                        );
                                      }

                                      var docs = snapshot.data!.docs;

                                      // Client-side filtering
                                      var filteredDocs = docs.where((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        final status =
                                            (data['status'] ?? 'PENDING')
                                                .toString()
                                                .toUpperCase();
                                        final customer =
                                            (data['name'] ??
                                                    data['customerName'] ??
                                                    '')
                                                .toString()
                                                .toLowerCase();
                                        final center =
                                            (data['serviceCenterName'] ?? '')
                                                .toString()
                                                .toLowerCase();
                                        final bookingId = doc.id.toLowerCase();

                                        // Search filter
                                        bool matchesSearch =
                                            _searchQuery.isEmpty ||
                                            customer.contains(
                                              _searchQuery.toLowerCase(),
                                            ) ||
                                            center.contains(
                                              _searchQuery.toLowerCase(),
                                            ) ||
                                            bookingId.contains(
                                              _searchQuery.toLowerCase(),
                                            );

                                        if (!matchesSearch) return false;

                                        // Tab filter
                                        if (_selectedTab == 'All Bookings') {
                                          return true;
                                        }
                                        if (_selectedTab == 'Scheduled') {
                                          return status == 'PENDING' ||
                                              status == 'ACCEPTED';
                                        }
                                        if (_selectedTab == 'In Progress') {
                                          return status == 'IN SERVICE' ||
                                              status == 'STARTED' ||
                                              status == 'ON THE WAY';
                                        }
                                        if (_selectedTab == 'Completed') {
                                          return status == 'COMPLETED';
                                        }
                                        if (_selectedTab == 'Cancelled') {
                                          return status == 'CANCELLED' ||
                                              status == 'REJECTED';
                                        }
                                        if (_selectedTab == 'Refunded') {
                                          final pStatus =
                                              (data['paymentStatus'] ?? '')
                                                  .toString()
                                                  .toUpperCase();
                                          return status == 'REFUNDED' ||
                                              pStatus == 'REFUNDED';
                                        }

                                        return true;
                                      }).toList();

                                      if (filteredDocs.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No bookings match your filters',
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: filteredDocs.length,
                                        itemBuilder: (context, index) {
                                          final doc = filteredDocs[index];
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
                                              data['customerName'] ??
                                              'Unknown Customer';
                                          String center =
                                              data['serviceCenterName'] ??
                                              'Unknown Center';
                                          String type =
                                              data['service'] ??
                                              data['serviceName'] ??
                                              'General Service';
                                          String status =
                                              data['status'] ?? 'PENDING';

                                          String dateStr = 'Unknown Date';
                                          if (data['appointmentDate'] != null) {
                                            DateTime? dt;
                                            if (data['appointmentDate']
                                                is Timestamp) {
                                              dt =
                                                  (data['appointmentDate']
                                                          as Timestamp)
                                                      .toDate();
                                            } else {
                                              dt = DateTime.tryParse(
                                                data['appointmentDate']
                                                    .toString(),
                                              );
                                            }
                                            if (dt != null) {
                                              dateStr = DateFormat(
                                                'MMM dd, hh:mm a',
                                              ).format(dt);
                                            }
                                          }

                                          String pStatusStr =
                                              (data['paymentStatus'] ??
                                                      'PENDING')
                                                  .toString();
                                          String amountStr = '0.00';
                                          if (data['amount'] != null) {
                                            amountStr = data['amount']
                                                .toString();
                                          } else if (data['totalAmount'] !=
                                              null) {
                                            amountStr = data['totalAmount']
                                                .toString();
                                          }
                                          if (!amountStr.startsWith('\$')) {
                                            amountStr = '\$$amountStr';
                                          }

                                          Color statusColor = Colors.grey;
                                          if (status.toUpperCase() ==
                                              'PENDING') {
                                            statusColor = Colors.amber;
                                          } else if (status.toUpperCase() ==
                                              'ACCEPTED') {
                                            statusColor = Colors.blue;
                                          } else if (status.toUpperCase() ==
                                                  'IN SERVICE' ||
                                              status.toUpperCase() ==
                                                  'STARTED') {
                                            statusColor = Colors.orange;
                                          } else if (status.toUpperCase() ==
                                              'COMPLETED') {
                                            statusColor = Colors.green;
                                          } else if (status.toUpperCase() ==
                                                  'CANCELLED' ||
                                              status.toUpperCase() ==
                                                  'REJECTED') {
                                            statusColor = Colors.red;
                                          } else if (status.toUpperCase() ==
                                                  'REFUNDED' ||
                                              pStatusStr.toUpperCase() ==
                                                  'REFUNDED') {
                                            statusColor = Colors.deepPurple;
                                          }

                                          return _buildTableRow(
                                            '#$id',
                                            customer,
                                            center,
                                            type,
                                            status,
                                            dateStr,
                                            pStatusStr,
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
    return Row(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Expanded(
          child: Container(
            height: 48,
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
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
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
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              if (!isMobile) ...[
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
            ],
          ),
        ),
      ],
    );
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
          Expanded(flex: 2, child: Text('PAYMENT', style: _headerStyle())),
          Expanded(flex: 2, child: Text('AMOUNT', style: _headerStyle())),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
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
    Color statusColor,
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
                Expanded(
                  child: Text(
                    customer,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              center,
              overflow: TextOverflow.ellipsis,
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
              overflow: TextOverflow.ellipsis,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
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
                    color:
                        payment.toUpperCase() == 'PAID' ||
                            payment.toUpperCase() == 'COMPLETED'
                        ? Colors.green
                        : (payment.toUpperCase() == 'REFUNDED'
                              ? Colors.deepPurple
                              : Colors.grey),
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
