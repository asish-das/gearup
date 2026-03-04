import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BookingData {
  final String id;
  final String userId;
  final String name;
  String status;
  final String vehicle;
  final String service;
  final DateTime appointmentDate;
  final String contact;
  final double amount;
  double progressVal;

  BookingData({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    required this.vehicle,
    required this.service,
    required this.appointmentDate,
    required this.contact,
    required this.amount,
    this.progressVal = 0.0,
  });

  factory BookingData.fromMap(Map<String, dynamic> map, String docId) {
    return BookingData(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? map['customerName'] ?? 'Unknown',
      status: map['status'] ?? 'PENDING',
      vehicle: map['vehicle'] ?? 'Unknown Vehicle',
      service: map['service'] ?? 'General Service',
      appointmentDate: map['appointmentDate'] != null
          ? (map['appointmentDate'] as Timestamp).toDate()
          : DateTime.now(),
      contact: map['contact'] ?? 'Unknown Contact',
      amount: (map['amount'] ?? 0.0).toDouble(),
      progressVal: (map['progressVal'] ?? 0.0).toDouble(),
    );
  }
}

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  String _searchQuery = '';
  String _activeFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Rejected',
    'Accepted',
    'In Service',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _updateStatus(BookingData booking) async {
    String newStatus = booking.status;
    double newProgress = booking.progressVal;

    if (booking.status == 'PENDING') {
      newStatus = 'ACCEPTED';
    } else if (booking.status == 'ACCEPTED') {
      newStatus = 'IN SERVICE';
      newProgress = 0.1;
    } else if (booking.status == 'IN SERVICE') {
      newStatus = 'COMPLETED';
      newProgress = 1.0;
    } else if (booking.status == 'COMPLETED') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing receipt for ${booking.id}...'),
            backgroundColor: const Color(0xFF5D40D4),
          ),
        );
      }
      _printReceipt(booking);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'status': newStatus, 'progressVal': newProgress});

      if (newStatus == 'COMPLETED') {
        _printReceipt(booking);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(BookingData booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'status': 'REJECTED', 'progressVal': 0.0});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printReceipt(BookingData booking) async {
    String realCustomerName = booking.name;
    try {
      if (booking.userId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking.userId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          realCustomerName = data['name'] ?? data['fullName'] ?? booking.name;
        }
      }
    } catch (_) {}

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Service Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Booking ID: ${booking.id}'),
              pw.Text('Customer Name: $realCustomerName'),
              pw.Text('Contact: ${booking.contact}'),
              pw.SizedBox(height: 20),
              pw.Text('Vehicle: ${booking.vehicle}'),
              pw.Text('Service: ${booking.service}'),
              pw.Text(
                'Completed On: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Amount:',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '\$${booking.amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _showBookingDetails(BookingData booking) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(booking.userId)
              .get(),
          builder: (context, snapshot) {
            String realCustomerName = booking.name;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              realCustomerName =
                  data['name'] ?? data['fullName'] ?? booking.name;
            }

            return AlertDialog(
              title: Text(
                'Booking Details',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: $realCustomerName',
                    style: GoogleFonts.manrope(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact: ${booking.contact}',
                    style: GoogleFonts.manrope(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri(scheme: 'tel', path: booking.contact);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch dialer'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D40D4),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Vehicle: ${booking.vehicle}',
                    style: GoogleFonts.manrope(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service: ${booking.service}',
                    style: GoogleFonts.manrope(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appointment: ${DateFormat('MMM dd, yyyy - HH:mm').format(booking.appointmentDate)}',
                    style: GoogleFonts.manrope(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount: \$${booking.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNewBookingDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New booking creation dialog will be opened.'),
        backgroundColor: Color(0xFF5D40D4),
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
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<BookingData> bookings = [];
        if (snapshot.hasData) {
          bookings = snapshot.data!.docs.map((doc) {
            return BookingData.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        }

        final filteredBookings = bookings.where((booking) {
          final matchesFilter =
              _activeFilter == 'All' ||
              booking.status.toUpperCase() == _activeFilter.toUpperCase();
          final matchesSearch =
              booking.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              booking.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              booking.vehicle.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          return matchesFilter && matchesSearch;
        }).toList();

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(),
              const SizedBox(height: 32),
              _buildFiltersRow(),
              const SizedBox(height: 32),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 1;
                    if (constraints.maxWidth >= 1400) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth >= 900) {
                      crossAxisCount = 2;
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.6,
                      ),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        return _buildDynamicBookingCard(
                          filteredBookings[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
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
              _buildHeaderActions(),
            ],
          );
        }
        return Row(
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
            _buildHeaderActions(),
          ],
        );
      },
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
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
        InkWell(
          onTap: _showNewBookingDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF5D40D4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'New Booking',
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
      ],
    );
  }

  Widget _buildFiltersRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmall = constraints.maxWidth < 900;
        return isSmall
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBox(),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildFilterChip(f, _activeFilter == f),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 1, child: _buildSearchBox()),
                  const SizedBox(width: 24),
                  Row(
                    children: _filters
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildFilterChip(f, _activeFilter == f),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildSearchBox() {
    return Container(
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by customer, vehicle or service ID...',
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
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5D40D4) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBookingCard(BookingData booking) {
    Color statusColor;
    String actionLabel;
    Color actionColor;
    bool outlinesButton;
    bool isHighlighted = false;
    String bottomLeftLabel = 'Appointment';
    String bottomLeftValue = DateFormat(
      'MMM dd, hh:mm a',
    ).format(booking.appointmentDate);
    String bottomRightLabel = 'Contact';
    String bottomRightValue = booking.contact;
    Color bottomRightColor = const Color(0xFF0F172A);

    switch (booking.status) {
      case 'PENDING':
        statusColor = Colors.orange;
        actionLabel = 'Accept Booking';
        actionColor = const Color(0xFF5D40D4);
        outlinesButton = false;
        break;
      case 'ACCEPTED':
        statusColor = Colors.blue;
        actionLabel = 'Start Service';
        actionColor = const Color(0xFF0F172A);
        outlinesButton = false;
        bottomRightLabel = 'Status';
        bottomRightValue = 'Scheduled';
        bottomRightColor = Colors.blue;
        break;
      case 'IN SERVICE':
        statusColor = const Color(0xFF5D40D4);
        actionLabel = 'Mark Completed';
        actionColor = const Color(0xFF10B981); // Green
        outlinesButton = false;
        isHighlighted = true;
        bottomLeftLabel = '';
        bottomLeftValue = '';
        bottomRightLabel = '';
        bottomRightValue = '';
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        actionLabel = 'Rejected';
        actionColor = Colors.red;
        outlinesButton = true;
        bottomLeftLabel = 'Rejected';
        bottomLeftValue = DateFormat(
          'MMM dd, hh:mm a',
        ).format(booking.appointmentDate);
        bottomRightLabel = '';
        bottomRightValue = '';
        bottomRightColor = Colors.red;
        break;
      case 'COMPLETED':
      default:
        statusColor = Colors.green;
        actionLabel = 'View Receipt';
        actionColor = const Color(0xFF64748B);
        outlinesButton = true;
        bottomLeftLabel = 'Completed At';
        bottomLeftValue = DateFormat(
          'Today, hh:mm a',
        ).format(booking.appointmentDate);
        bottomRightLabel = 'Bill Amount';
        bottomRightValue = '\$${booking.amount.toStringAsFixed(2)}';
        bottomRightColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF5D40D4)
              : const Color(0xFFE2E8F0),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          if (isHighlighted)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D40D4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person, color: statusColor),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(booking.userId)
                                .get(),
                            builder: (context, snapshot) {
                              String realName = booking.name;
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                realName =
                                    data['name'] ??
                                    data['fullName'] ??
                                    booking.name;
                              }
                              return Text(
                                realName,
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: ${booking.id}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFF3E8FF)
                          : statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      booking.status,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted
                            ? const Color(0xFF5D40D4)
                            : statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFE2E8F0)),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          booking.vehicle,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Type',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          booking.service,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isHighlighted) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bottomLeftLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bottomLeftValue,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bottomRightLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bottomRightValue,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: bottomRightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (isHighlighted) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESS',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      '${(booking.progressVal * 100).toInt()}%',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D40D4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: booking.progressVal,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF5D40D4),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  if (booking.status == 'PENDING') ...[
                    Expanded(
                      child: InkWell(
                        onTap: () => _rejectBooking(booking),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Reject',
                              style: GoogleFonts.manrope(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: InkWell(
                      onTap: booking.status == 'REJECTED'
                          ? null
                          : () => _updateStatus(booking),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: outlinesButton ? Colors.white : actionColor,
                          border: outlinesButton
                              ? Border.all(color: const Color(0xFFE2E8F0))
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            actionLabel,
                            style: GoogleFonts.manrope(
                              color: outlinesButton
                                  ? actionColor
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      _showBookingDetails(booking);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.info_outline,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
