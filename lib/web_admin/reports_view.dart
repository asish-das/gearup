import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildQuickStats(isMobile),
                      const SizedBox(height: 32),
                      _buildReportSections(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Generation',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          'Detailed system reports and data export options',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        final bookings = snapshot.data?.docs ?? [];
        final completed = bookings.where((b) {
          final data = b.data() as Map<String, dynamic>;
          return (data['status'] ?? '').toString().toUpperCase() == 'COMPLETED';
        }).length;

        final cancelled = bookings.where((b) {
          final data = b.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toUpperCase();
          return status == 'CANCELLED' || status == 'REJECTED';
        }).length;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 1 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2,
          children: [
            _buildMiniStat(
              'Total Bookings',
              bookings.length.toString(),
              Icons.event_note,
              Colors.blue,
            ),
            _buildMiniStat(
              'Completion Rate',
              '${((completed / (bookings.isEmpty ? 1 : bookings.length)) * 100).toStringAsFixed(1)}%',
              Icons.check_circle_outline,
              Colors.green,
            ),
            _buildMiniStat(
              'Cancellation Rate',
              '${((cancelled / (bookings.isEmpty ? 1 : bookings.length)) * 100).toStringAsFixed(1)}%',
              Icons.cancel_outlined,
              Colors.red,
            ),
            _buildMiniStat(
              'Avg revenue/booking',
              '\$${_calculateAvgRevenue(bookings)}',
              Icons.payments_outlined,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  String _calculateAvgRevenue(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return '0';
    double total = 0;
    int count = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0).toDouble();
      final status = (data['status'] ?? '').toString().toUpperCase();
      final paymentStatus = (data['paymentStatus'] ?? '').toString().toUpperCase();

      if (paymentStatus == 'REFUNDED' || status == 'REFUNDED') {
        continue; // ignore refunds from revenue
      } else if (status == 'COMPLETED' || paymentStatus == 'PAID') {
        total += amount;
        count++;
      }
    }
    return (total / (count == 0 ? 1 : count)).toStringAsFixed(2);
  }

  Widget _buildMiniStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSections(bool isMobile) {
    return Column(
      children: [
        _buildReportCard(
          'Bookings Report',
          'Detailed analysis of service schedules, volume, and statuses.',
          Icons.calendar_today_rounded,
          () => _exportReport('bookings'),
        ),
        const SizedBox(height: 16),
        _buildReportCard(
          'Financial Performance',
          'Revenue trends, service center earnings, and refund analysis.',
          Icons.auto_graph_rounded,
          () => _exportReport('financial'),
        ),
        const SizedBox(height: 16),
        _buildReportCard(
          'Service Center Activity',
          'Registration trends, performance metrics, and compliance status.',
          Icons.business_rounded,
          () => _exportReport('centers'),
        ),
        const SizedBox(height: 16),
        _buildReportCard(
          'User Engagement',
          'User growth, booking frequency, and vehicle distributions.',
          Icons.people_alt_rounded,
          () => _exportReport('users'),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onExport,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5D40D4), size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(
              Icons.download_rounded,
              size: 18,
              color: Colors.indigo,
            ),
            label: const Text(
              'Export data',
              style: TextStyle(color: Colors.indigo),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D40D4).withValues(alpha: 0.05),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(String type) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preparing $type report export...')),
      );

      String title = '';
      List<String> headers = [];
      List<List<String>> data = [];
      String fileNamePrefix = '';

      final firestore = FirebaseFirestore.instance;

      switch (type) {
        case 'bookings':
          title = 'Bookings Report';
          fileNamePrefix = 'bookings_report';
          headers = [
            'Booking ID',
            'Customer',
            'Service Center',
            'Service Type',
            'Date',
            'Time',
            'Status',
            'Amount',
          ];
          final snapshot = await firestore.collection('bookings').get();
          data = snapshot.docs.map((doc) {
            final d = doc.data();
            return <String>[
              doc.id,
              d['customerName'] ?? 'N/A',
              d['serviceCenterName'] ?? 'N/A',
              d['serviceType'] ?? 'N/A',
              d['bookingDate'] ?? 'N/A',
              d['bookingTime'] ?? 'N/A',
              d['status'] ?? 'N/A',
              '₹${d['totalAmount'] ?? '0'}',
            ];
          }).toList();
          break;

        case 'financial':
          title = 'Financial Performance Report';
          fileNamePrefix = 'financial_report';
          headers = [
            'Booking ID',
            'Date',
            'Service Center',
            'Amount',
            'Payment Status',
            'Refund Status',
          ];
          final snapshot = await firestore.collection('bookings').get();
          data = snapshot.docs.map((doc) {
            final d = doc.data();
            return <String>[
              doc.id,
              d['bookingDate'] ?? 'N/A',
              d['serviceCenterName'] ?? 'N/A',
              '₹${d['totalAmount'] ?? '0'}',
              d['paymentStatus'] ?? 'N/A',
              d['refundStatus'] ?? 'None',
            ];
          }).toList();
          break;

        case 'centers':
          title = 'Service Centers Report';
          fileNamePrefix = 'service_centers_report';
          headers = [
            'Center Name',
            'Email',
            'Phone',
            'Status',
            'Joined Date',
            'Total Bookings',
          ];
          final snapshot = await firestore.collection('users').where('role', isEqualTo: 'serviceCenter').get();
          data = await Future.wait(
            snapshot.docs.map((doc) async {
              final d = doc.data();
              final bookingsCount = await firestore
                  .collection('bookings')
                  .where('serviceCenterId', isEqualTo: doc.id)
                  .count()
                  .get();

              String dateStr = 'N/A';
              if (d['createdAt'] != null) {
                if (d['createdAt'] is Timestamp) {
                  dateStr = DateFormat('yyyy-MM-dd').format((d['createdAt'] as Timestamp).toDate());
                } else if (d['createdAt'] is String) {
                  final parsed = DateTime.tryParse(d['createdAt']);
                  if (parsed != null) {
                    dateStr = DateFormat('yyyy-MM-dd').format(parsed);
                  }
                }
              }

              return <String>[
                d['businessName'] ?? d['name'] ?? 'N/A',
                d['email'] ?? 'N/A',
                d['phone'] ?? d['phoneNumber'] ?? 'N/A',
                d['status'] ?? 'N/A',
                dateStr,
                bookingsCount.count.toString(),
              ];
            }),
          );
          break;

        case 'users':
          title = 'User Engagement Report';
          fileNamePrefix = 'users_report';
          headers = ['Name', 'Email', 'Phone', 'Created At', 'Active Status'];
          final snapshot = await firestore.collection('users').get();
          data = snapshot.docs.map((doc) {
            final d = doc.data();

            String dateStr = 'N/A';
            if (d['createdAt'] != null) {
              if (d['createdAt'] is Timestamp) {
                dateStr = DateFormat('yyyy-MM-dd').format((d['createdAt'] as Timestamp).toDate());
              } else if (d['createdAt'] is String) {
                final parsed = DateTime.tryParse(d['createdAt']);
                if (parsed != null) {
                  dateStr = DateFormat('yyyy-MM-dd').format(parsed);
                }
              }
            }

            return <String>[
              d['fullName'] ?? d['name'] ?? 'N/A',
              d['email'] ?? 'N/A',
              d['phone'] ?? d['phoneNumber'] ?? 'N/A',
              dateStr,
              d['isSuspended'] == true || d['status'] == 'suspended' ? 'Suspended' : 'Active',
            ];
          }).toList();
          break;
      }

      // Default to PDF for now, can be extended to show a choice
      await ExportService.exportGenericToPDF(
        title: title,
        headers: headers,
        data: data,
        fileNamePrefix: fileNamePrefix,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}
