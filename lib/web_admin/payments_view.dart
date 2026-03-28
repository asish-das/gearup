import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 32),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('bookings').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allBookings = snapshot.data?.docs ?? [];
                    final payments = _processPayments(allBookings);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(payments, isMobile),
                        const SizedBox(height: 32),
                        _buildTransactionsTable(payments),
                      ],
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

  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments Monitoring',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Track transactions and revenue performance',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        if (!isMobile)
          Row(
            children: [
              SizedBox(
                width: 300,
                height: 48,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: GoogleFonts.manrope(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5D40D4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _exportTransactions,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Export history'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5D40D4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _exportTransactions() async {
    try {
      final snapshot = await _firestore.collection('bookings').get();
      final data = snapshot.docs.map((doc) {
        final d = doc.data();
        final date = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return <String>[
          doc.id,
          DateFormat('yyyy-MM-dd HH:mm').format(date),
          d['customerName'] ?? d['userName'] ?? 'N/A',
          d['serviceCenterName'] ?? d['centerName'] ?? 'N/A',
          '${(d['amount'] ?? 0).toDouble().toStringAsFixed(2)}',
          (d['paymentStatus'] ?? 'PENDING').toString().toUpperCase(),
          (d['status'] ?? 'PENDING').toString().toUpperCase(),
        ];
      }).toList();

      await ExportService.exportGenericToPDF(
        title: 'Transactions History',
        headers: [
          'ID',
          'Date',
          'Customer',
          'Service Center',
          'Amount',
          'Payment Status',
          'Booking Status',
        ],
        data: data,
        fileNamePrefix: 'transactions_history',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions exported successfully!')),
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

  List<Map<String, dynamic>> _processPayments(
    List<QueryDocumentSnapshot> docs,
  ) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Widget _buildStatsGrid(List<Map<String, dynamic>> payments, bool isMobile) {
    double totalRevenue = 0;
    double totalRefunds = 0;
    int paidCount = 0;
    int refundCount = 0;

    for (var p in payments) {
      final amount = (p['amount'] ?? 0).toDouble();
      final status = (p['status'] ?? '').toString().toUpperCase();
      final paymentStatus = (p['paymentStatus'] ?? '').toString().toUpperCase();

      if (paymentStatus == 'REFUNDED' || status == 'REFUNDED') {
        totalRefunds += amount;
        refundCount++;
      } else if (paymentStatus == 'PAID' || status == 'COMPLETED') {
        totalRevenue += amount;
        paidCount++;
      }
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: isMobile ? 1 : 3,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: isMobile ? 3 : 2.5,
      children: [
        _buildStatCard(
          'Total Revenue',
          '\$${totalRevenue.toStringAsFixed(2)}',
          '$paidCount Successful Transactions',
          Icons.payments_outlined,
          const Color(0xFF10B981),
        ),
        _buildStatCard(
          'Total Refunds',
          '\$${totalRefunds.toStringAsFixed(2)}',
          '$refundCount Processed Refunds',
          Icons.restore_outlined,
          const Color(0xFFF43F5E),
        ),
        _buildStatCard(
          'Net Revenue',
          '\$${(totalRevenue - totalRefunds).toStringAsFixed(2)}',
          'After refunds and cancellations',
          Icons.account_balance_wallet_outlined,
          const Color(0xFF5D40D4),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable(List<Map<String, dynamic>> payments) {
    final filtered = payments.where((p) {
      if (_searchQuery.isEmpty) return true;
      final customer = (p['customerName'] ?? p['userName'] ?? '')
          .toString()
          .toLowerCase();
      final center = (p['serviceCenterName'] ?? p['centerName'] ?? '')
          .toString()
          .toLowerCase();
      final id = (p['id'] ?? '').toString().toLowerCase();
      return customer.contains(_searchQuery) ||
          center.contains(_searchQuery) ||
          id.contains(_searchQuery);
    }).toList();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DataTableTheme(
            data: DataTableThemeData(
              headingTextStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF475569),
              ),
              dataTextStyle: GoogleFonts.manrope(
                color: const Color(0xFF0F172A),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        columns: const [
                          DataColumn(label: Text('Transaction ID')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Customer')),
                          DataColumn(label: Text('Service Center')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: filtered.map((p) => _buildDataRow(p)).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> p) {
    final status = (p['status'] ?? 'PENDING').toString().toUpperCase();
    final paymentStatus = (p['paymentStatus'] ?? 'PENDING')
        .toString()
        .toUpperCase();
    final isRefunded = paymentStatus == 'REFUNDED' || status == 'REFUNDED';

    Color statusColor;
    if (isRefunded) {
      statusColor = const Color(0xFFF43F5E);
    } else if (paymentStatus == 'PAID' || status == 'COMPLETED') {
      statusColor = const Color(0xFF10B981);
    } else {
      statusColor = const Color(0xFFF59E0B);
    }

    final date = (p['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return DataRow(
      cells: [
        DataCell(Text('#${p['id']?.toString().substring(0, 8) ?? 'N/A'}')),
        DataCell(Text(DateFormat('MMM dd, yyyy HH:mm').format(date))),
        DataCell(Text(p['customerName'] ?? p['userName'] ?? 'Unknown')),
        DataCell(Text(p['serviceCenterName'] ?? p['centerName'] ?? 'N/A')),
        DataCell(Text('\$${(p['amount'] ?? 0).toDouble().toStringAsFixed(2)}')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isRefunded ? 'REFUNDED' : paymentStatus,
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
  }
}
