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
  final String vehicleId;
  final String vehicle;
  final String service;
  final DateTime appointmentDate;
  final String contact;
  final double amount;
  double progressVal;
  final String paymentStatus;
  final String paymentMethod;
  final String? deliveryOption;
  final DateTime createdAt;
  final double? rating;
  final String? reviewText;

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
    this.paymentStatus = 'PENDING',
    this.paymentMethod = 'N/A',
    this.deliveryOption,
    this.vehicleId = '',
    required this.createdAt,
    this.rating,
    this.reviewText,
  });

  factory BookingData.fromMap(Map<String, dynamic> map, String docId) {
    return BookingData(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? map['customerName'] ?? 'Unknown',
      status: map['status'] ?? 'PENDING',
      vehicleId: map['vehicleId'] ?? '',
      vehicle: map['vehicle'] ?? 'Unknown Vehicle',
      service: map['service'] ?? 'General Service',
      appointmentDate: map['appointmentDate'] != null
          ? (map['appointmentDate'] as Timestamp).toDate()
          : DateTime.now(),
      contact: map['contact'] ?? 'Unknown Contact',
      amount: (map['amount'] ?? 0.0).toDouble(),
      progressVal: (map['progressVal'] ?? 0.0).toDouble(),
      paymentStatus: map['paymentStatus'] ?? 'PENDING',
      paymentMethod: map['paymentMethod'] ?? 'N/A',
      deliveryOption: map['deliveryOption'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['appointmentDate'] != null
                ? (map['appointmentDate'] as Timestamp).toDate()
                : DateTime.now()),
      rating: (map['rating'] as num?)?.toDouble(),
      reviewText: map['reviewText'] as String?,
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
    'Diagnostics',
    'In Service',
    'Testing',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
  }

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
                              color: iconColor.withValues(alpha: 0.1),
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

  Future<void> _updateStatus(BookingData booking) async {
    String newStatus = booking.status;
    double newProgress = booking.progressVal;

    if (booking.status == 'PENDING') {
      newStatus = 'ACCEPTED';
      newProgress = 0.0;
    } else if (booking.status == 'ACCEPTED') {
      newStatus = 'DIAGNOSTICS';
      newProgress = 0.25;
    } else if (booking.status == 'DIAGNOSTICS') {
      newStatus = 'IN SERVICE';
      newProgress = 0.50;
    } else if (booking.status == 'IN SERVICE') {
      newStatus = 'TESTING';
      newProgress = 0.75;
    } else if (booking.status == 'TESTING') {
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
      if (newStatus == 'COMPLETED') {
        _showMileageUpdateDialog(booking);
      } else {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .update({'status': newStatus, 'progressVal': newProgress});
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

  void _showMileageUpdateDialog(BookingData booking) {
    final mileageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Complete Service',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter the current mileage (KM) for ${booking.vehicle} to complete the service.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: mileageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mileage (KM)',
                      labelStyle: const TextStyle(color: Color(0xFF5D40D4)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.speed, color: Color(0xFF5D40D4)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.manrope(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final mileage = int.tryParse(mileageController.text);
                            if (mileage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid mileage'),
                                ),
                              );
                              return;
                            }

                            try {
                              // 1. Update booking
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(booking.id)
                                  .update({'status': 'COMPLETED', 'progressVal': 1.0});

                              // 2. Update vehicle kilometers if vehicleId exists
                              if (booking.vehicleId.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('vehicles')
                                    .doc(booking.vehicleId)
                                    .update({'kilometers': mileage});
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _printReceipt(booking);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Service completed and mileage updated!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D40D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Complete',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _markAsPaid(BookingData booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'paymentStatus': 'PAID'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as PAID!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payment: $e'),
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
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GEARUP',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'SERVICE & DETAILING CENTER',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text(
                        '#${booking.id.toUpperCase().substring(0, 8)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 20),

              // Status Badge
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: booking.paymentStatus == 'PAID' 
                    ? PdfColors.green100 
                    : PdfColors.orange100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  booking.paymentStatus,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: booking.paymentStatus == 'PAID' 
                      ? PdfColors.green800 
                      : PdfColors.orange800,
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              // Customer & Vehicle Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          realCustomerName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          booking.contact,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VEHICLE DETAILS:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          booking.vehicle,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Appointment: ${DateFormat('MMM dd, yyyy').format(booking.appointmentDate)}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Items Table Header
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SERVICE DESCRIPTION',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Table Item
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          booking.service,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Professional ${booking.service} with detailed inspection',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      '\$${booking.amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Summary
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Grand Total: ',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Text(
                            '\$${booking.amount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Paid via ${booking.paymentMethod}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 50),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for choosing GearUp!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'For any queries, please contact our support at support@gearup.com',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey500,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Generated on: ${DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ],
                ),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'BookingDetails',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, _) {
        return Center(
          child: FutureBuilder<DocumentSnapshot>(
            future: booking.userId.isNotEmpty
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(booking.userId)
                      .get()
                : null,
            builder: (context, snapshot) {
              String realCustomerName = booking.name;
              String customerEmail = 'N/A';
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                realCustomerName =
                    data['name'] ?? data['fullName'] ?? booking.name;
                customerEmail = data['email'] ?? 'N/A';
              }

              return Material(
                color: Colors.transparent,
                child: Container(
                  width: 550,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Premium Dark Navy
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Details',
                                style: GoogleFonts.manrope(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: #${booking.id.substring(0, 8).toUpperCase()}',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Main Content Area
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildModernDetailItem(
                              Icons.person_outline,
                              'Customer',
                              realCustomerName,
                              subtitle: customerEmail,
                            ),
                            _buildModernDetailItem(
                              Icons.directions_car_filled_outlined,
                              'Vehicle',
                              booking.vehicle,
                            ),
                            _buildModernDetailItem(
                              Icons.build_circle_outlined,
                              'Service Type',
                              booking.service,
                            ),
                            _buildModernDetailItem(
                              Icons.calendar_today_outlined,
                              'Appointment',
                              DateFormat(
                                'EEEE, MMM dd, yyyy - HH:mm',
                              ).format(booking.appointmentDate),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: Colors.white10),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBadgeDetail(
                                    'Status',
                                    booking.status,
                                    _getStatusColor(booking.status),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildBadgeDetail(
                                    'Payment',
                                    booking.paymentStatus,
                                    _getPaymentStatusColor(
                                      booking.paymentStatus,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer / Actions
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: Colors.white54,
                                  ),
                                ),
                                Text(
                                  '\$${booking.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(
                                      0xFF818CF8,
                                    ), // Indigo highlight
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final Uri url = Uri(
                                  scheme: 'tel',
                                  path: booking.contact,
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.call, size: 20),
                              label: Text(
                                'Call Customer',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D40D4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModernDetailItem(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
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
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.white24,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeDetail(String label, String value, MaterialColor color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              value.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  MaterialColor _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'DIAGNOSTICS':
        return Colors.teal;
      case 'IN SERVICE':
        return Colors.indigo;
      case 'TESTING':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'REFUNDED':
      case 'REJECTED':
      case 'CANCELLED':
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
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showQuickBookingForm() {
    final nameController = TextEditingController();
    final vehicleController = TextEditingController();
    final serviceController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Manual Booking',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quickly register a walk-in customer',
                  style: GoogleFonts.manrope(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  'Customer Name',
                  nameController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Vehicle Name / Number',
                  vehicleController,
                  Icons.directions_car_outlined,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Service Required',
                  serviceController,
                  Icons.settings_outlined,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        'Date',
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        Icons.calendar_today_outlined,
                        () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimePicker(
                        'Time',
                        selectedTime.format(context),
                        Icons.access_time_outlined,
                        () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            final now = DateTime.now();
                            final isToday =
                                selectedDate.year == now.year &&
                                selectedDate.month == now.month &&
                                selectedDate.day == now.day;

                            if (isToday) {
                              if (time.hour < now.hour ||
                                  (time.hour == now.hour &&
                                      time.minute < now.minute)) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cannot select a past time for today',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) return;
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;

                        final bookingDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .add({
                              'name': nameController.text,
                              'customerName': nameController.text,
                              'vehicle': vehicleController.text,
                              'service': serviceController.text,
                              'serviceCenterId': uid,
                              'appointmentDate': Timestamp.fromDate(
                                bookingDate,
                              ),
                              'dateString': DateFormat('yyyy-MM-dd').format(selectedDate),
                              'time': selectedTime.format(context),
                              'createdAt': FieldValue.serverTimestamp(),
                              'status': 'PENDING',
                              'amount': 0.0,
                              'paymentMethod': 'Cash',
                              'deliveryOption': 'Quick Booking',
                              'progress': 0.0,
                            });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quick booking added successfully!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D40D4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Confirm Booking',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF5D40D4), size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF5D40D4), size: 18),
                const SizedBox(width: 12),
                Text(value, style: GoogleFonts.manrope(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
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

          // Sort bookings: Primary - appointmentDate (ASC) for chronological workflow
          bookings.sort((a, b) {
            int cmp = a.appointmentDate.compareTo(b.appointmentDate);
            if (cmp == 0) {
              return b.createdAt.compareTo(a.createdAt); // Secondary: Newest request first
            }
            return cmp;
          });
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
                child: filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 1;
                          if (constraints.maxWidth >= 1400) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth >= 900) {
                            crossAxisCount = 2;
                          }
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  mainAxisExtent: 400,
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Row(
      children: [
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
        const SizedBox(width: 24),
        InkWell(
          onTap: _showQuickBookingForm,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D40D4), Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D40D4).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quick Booking',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 64,
              color: Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No bookings found',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.manrope(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _activeFilter = 'All';
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Reset Filters',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
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
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search by customer, vehicle or booking ID...',
                hintStyle: GoogleFonts.manrope(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: const Color(0xFF94A3B8),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5D40D4) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF5D40D4) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF5D40D4).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
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

    switch (booking.status.toUpperCase()) {
      case 'PENDING':
        statusColor = Colors.orange;
        actionLabel = 'Accept Booking';
        actionColor = const Color(0xFF5D40D4);
        outlinesButton = false;
        break;
      case 'ACCEPTED':
        statusColor = Colors.blue;
        actionLabel = 'Start Diagnostics';
        actionColor = const Color(0xFF0F172A);
        outlinesButton = false;
        break;
      case 'DIAGNOSTICS':
        statusColor = Colors.teal;
        actionLabel = 'Start Service';
        actionColor = const Color(0xFF0F172A);
        outlinesButton = false;
        isHighlighted = true;
        break;
      case 'IN SERVICE':
        statusColor = const Color(0xFF5D40D4);
        actionLabel = 'Start Testing';
        actionColor = const Color(0xFF10B981);
        outlinesButton = false;
        isHighlighted = true;
        break;
      case 'TESTING':
        statusColor = Colors.indigo;
        actionLabel = 'Mark Completed';
        actionColor = const Color(0xFF10B981);
        outlinesButton = false;
        isHighlighted = true;
        break;
      case 'REJECTED':
      case 'CANCELLED':
      case 'REFUNDED':
        statusColor = Colors.red;
        actionLabel = booking.status == 'REFUNDED' ? 'Refunded' : 'Cancelled';
        actionColor = Colors.red;
        outlinesButton = true;
        break;
      case 'COMPLETED':
      default:
        statusColor = Colors.green;
        actionLabel = 'View Receipt';
        actionColor = const Color(0xFF64748B);
        outlinesButton = true;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF5D40D4).withValues(alpha: 0.3)
              : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFF5D40D4).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            booking.userId.isEmpty
                                ? Text(
                                    booking.name,
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(booking.userId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      String realName = booking.name;
                                      if (snapshot.hasData &&
                                          snapshot.data!.exists) {
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${booking.id}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (booking.rating != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < booking.rating!
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  if (booking.reviewText != null &&
                                      booking.reviewText!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '"${booking.reviewText}"',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          booking.status,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.directions_car_rounded,
                          'Vehicle',
                          booking.vehicle,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.settings_suggest_rounded,
                          'Service',
                          booking.service,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.event_available_rounded,
                          'Appointment',
                          '${DateFormat('MMM d').format(booking.appointmentDate)} at ${DateFormat('jm').format(booking.appointmentDate)}',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.phone_rounded,
                          'Contact',
                          booking.contact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (booking.deliveryOption != null)
                        Expanded(
                          child: _buildInfoItem(
                            booking.deliveryOption == 'delivery'
                                ? Icons.delivery_dining_rounded
                                : Icons.store_rounded,
                            'Type',
                            booking.deliveryOption!.toUpperCase(),
                            valueColor: booking.deliveryOption == 'delivery'
                                ? Colors.blue
                                : Colors.orange,
                          ),
                        ),
                      Expanded(
                        child: _buildInfoItem(
                          booking.paymentMethod == 'Cash'
                              ? Icons.payments_rounded
                              : Icons.credit_card_rounded,
                          'Payment',
                          booking.paymentMethod.isEmpty
                              ? 'N/A'
                              : booking.paymentMethod,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.currency_rupee_rounded,
                          'Amount',
                          '₹${booking.amount.toStringAsFixed(0)}',
                          valueColor: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  if (isHighlighted) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service Progress',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${(booking.progressVal * 100).toInt()}%',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D40D4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: booking.progressVal,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF5D40D4),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Actions Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  if (booking.status == 'PENDING') ...[
                    Expanded(
                      child: _buildActionButton(
                        'Reject',
                        () => _rejectBooking(booking),
                        color: Colors.red,
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (booking.status == 'COMPLETED' &&
                      booking.paymentStatus == 'PENDING') ...[
                    Expanded(
                      child: _buildActionButton(
                        'Mark Paid',
                        () => _markAsPaid(booking),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _buildActionButton(
                      actionLabel,
                      booking.status == 'REJECTED' ||
                              booking.status == 'CANCELLED' ||
                              booking.status == 'REFUNDED'
                          ? null
                          : () => _updateStatus(booking),
                      color: actionColor,
                      isOutlined: outlinesButton,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showBookingDetails(booking),
                    icon: const Icon(Icons.info_outline_rounded),
                    color: const Color(0xFF64748B),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback? onTap, {
    required Color color,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 44,
      child: onTap == null
          ? Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isOutlined ? Colors.transparent : color,
                  border: isOutlined
                      ? Border.all(color: color, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isOutlined
                      ? null
                      : [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    color: isOutlined ? color : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
    );
  }
}
