import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

class BookingsManagerView extends StatefulWidget {
  const BookingsManagerView({super.key});

  @override
  State<BookingsManagerView> createState() => _BookingsManagerViewState();
}

class _BookingsManagerViewState extends State<BookingsManagerView> {
  String _selectedTab = 'All';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize to current month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
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
                      'Bookings Management',
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
                      'Bookings Management',
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
                    _buildTab('All', _selectedTab == 'All'),
                    const SizedBox(width: 12),
                    _buildTab('Pending', _selectedTab == 'Pending'),
                    const SizedBox(width: 12),
                    _buildTab('Rejected', _selectedTab == 'Rejected'),
                    const SizedBox(width: 12),
                    _buildTab('Accepted', _selectedTab == 'Accepted'),
                    const SizedBox(width: 12),
                    _buildTab('Diagnostics', _selectedTab == 'Diagnostics'),
                    const SizedBox(width: 12),
                    _buildTab('In Service', _selectedTab == 'In Service'),
                    const SizedBox(width: 12),
                    _buildTab('Testing', _selectedTab == 'Testing'),
                    const SizedBox(width: 12),
                    _buildTab('Completed', _selectedTab == 'Completed'),
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
                                        return Center(
                                          child: Column(
                                            children: [
                                              const Text('No bookings found'),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Debug: ${snapshot.hasError ? "Error: ${snapshot.error}" : "Connected but no data"}',
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final docs = snapshot.data!.docs.toList();
                                      final bookings = _filterBookings(docs);

                                      if (bookings.isEmpty) {
                                        return const Center(
                                          child: Text('No bookings found with current filters'),
                                        );
                                      }

                                      // Sort by date descending
                                      bookings.sort((a, b) {
                                        final da = a.data() as Map<String, dynamic>;
                                        final db = b.data() as Map<String, dynamic>;

                                        DateTime? dateA;
                                        if (da['appointmentDate'] != null) {
                                          if (da['appointmentDate'] is Timestamp) {
                                            dateA = (da['appointmentDate'] as Timestamp).toDate();
                                          } else {
                                            dateA = DateTime.tryParse(da['appointmentDate'].toString());
                                          }
                                        } else if (da['createdAt'] != null && da['createdAt'] is Timestamp) {
                                          dateA = (da['createdAt'] as Timestamp).toDate();
                                        }

                                        DateTime? dateB;
                                        if (db['appointmentDate'] != null) {
                                          if (db['appointmentDate'] is Timestamp) {
                                            dateB = (db['appointmentDate'] as Timestamp).toDate();
                                          } else {
                                            dateB = DateTime.tryParse(db['appointmentDate'].toString());
                                          }
                                        } else if (db['createdAt'] != null && db['createdAt'] is Timestamp) {
                                          dateB = (db['createdAt'] as Timestamp).toDate();
                                        }

                                        return (dateB ?? DateTime.now()).compareTo(dateA ?? DateTime.now());
                                      });

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
                                          } else if (data['date'] != null) {
                                            DateTime? dt = DateTime.tryParse(
                                              data['date'],
                                            );
                                            if (dt != null) {
                                              dateStr = DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(dt);
                                              if (data['time'] != null) {
                                                dateStr += ', ${data['time']}';
                                              }
                                            }
                                          }

                                          String payment =
                                              status.toUpperCase() ==
                                                  'COMPLETED'
                                              ? 'Paid'
                                              : 'Pending';
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

                                          MaterialColor statusColor = Colors.grey;
                                          if (status == 'PENDING') {
                                            statusColor = Colors.amber;
                                          } else if (status == 'ACCEPTED') {
                                            statusColor = Colors.blue;
                                          } else if (status == 'IN SERVICE') {
                                            statusColor = Colors.orange;
                                          } else if (status == 'COMPLETED') {
                                            statusColor = Colors.green;
                                          } else if (status == 'CANCELLED' || status == 'REJECTED') {
                                            statusColor = Colors.red;
                                          } else if (status == 'DIAGNOSTICS') {
                                            statusColor = Colors.purple;
                                          } else if (status == 'TESTING') {
                                            statusColor = Colors.teal;
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
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
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
      if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
      InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                    _selectedDateRange == null
                        ? 'Select Dates'
                        : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
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
      ),
      if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
      InkWell(
        onTap: _exportBookingsToCSV,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D40D4),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _exportBookingsToCSV() async {
    // We'll use the current stream data if possible, but let's fetch once for the export
    try {
      final snapshot = await FirebaseFirestore.instance.collection('bookings').get();
      final docs = _filterBookings(snapshot.docs);

      if (docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No bookings to export for the selected filters.')),
          );
        }
        return;
      }

      String csvData = 'Booking ID,Customer,Service Center,Service Type,Status,Date,Payment,Amount\n';
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        String id = doc.id.toUpperCase();
        String customer = (data['name'] ?? data['customerName'] ?? 'N/A').toString().replaceAll(',', '');
        String center = (data['serviceCenterName'] ?? 'N/A').toString().replaceAll(',', '');
        String type = (data['service'] ?? 'N/A').toString().replaceAll(',', '');
        String status = (data['status'] ?? 'PENDING').toString();
        
        DateTime? dt;
        if (data['appointmentDate'] is Timestamp) {
          dt = (data['appointmentDate'] as Timestamp).toDate();
        } else if (data['date'] != null) {
          dt = DateTime.tryParse(data['date'].toString());
        }
        String dateStr = dt != null ? DateFormat('yyyy-MM-dd').format(dt) : 'N/A';
        
        String payment = (status.toUpperCase() == 'COMPLETED' ? 'Paid' : 'Pending');
        String amount = data['amount']?.toString() ?? data['totalAmount']?.toString() ?? '0.00';

        csvData += '$id,$customer,$center,$type,$status,$dateStr,$payment,$amount\n';
      }

      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'bookings_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookings exported successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  List<QueryDocumentSnapshot> _filterBookings(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      // 1. Tab Filter
      if (_selectedTab != 'All') {
        final status = (data['status'] ?? 'PENDING').toString().toUpperCase();
        if (_selectedTab == 'Pending' && status != 'PENDING') return false;
        if (_selectedTab == 'Rejected' && status != 'REJECTED') return false;
        if (_selectedTab == 'Accepted' && status != 'ACCEPTED') return false;
        if (_selectedTab == 'Diagnostics' && status != 'DIAGNOSTICS') return false;
        if (_selectedTab == 'In Service' && status != 'IN SERVICE') return false;
        if (_selectedTab == 'Testing' && status != 'TESTING') return false;
        if (_selectedTab == 'Completed' && status != 'COMPLETED') return false;
      }

      // 2. Date Range Filter
      if (_selectedDateRange != null) {
        DateTime? dt;
        if (data['appointmentDate'] is Timestamp) {
          dt = (data['appointmentDate'] as Timestamp).toDate();
        } else if (data['date'] != null) {
          dt = DateTime.tryParse(data['date'].toString());
        }
        
        if (dt == null) return false;
        
        // Normalize dates to compare without time
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
        final current = DateTime(dt.year, dt.month, dt.day);
        
        if (current.isBefore(start) || current.isAfter(end)) return false;
      }

      // 3. Search Filter
      if (_searchQuery.isNotEmpty) {
        final customer = (data['name'] ?? data['customerName'] ?? '').toString().toLowerCase();
        final vehicle = (data['vehicle'] ?? '').toString().toLowerCase();
        final id = doc.id.toLowerCase();
        if (!customer.contains(_searchQuery) && !vehicle.contains(_searchQuery) && !id.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5D40D4) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF5D40D4) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.manrope(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
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
