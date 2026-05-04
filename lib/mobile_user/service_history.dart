import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: const Center(
          child: Text(
            'Please log in to view history.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.backgroundDark,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            'Activity History',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: [
              Tab(text: 'Past Services'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Product Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildServicesStream(isPast: true),
            _buildServicesStream(isPast: false),
            _buildOrdersStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesStream({required bool isPast}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        
        final docs = snapshot.data?.docs ?? [];
        final sortedDocs = docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['appointmentDate'] as Timestamp?)?.toDate() ??
                (aData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final bDate = (bData['appointmentDate'] as Timestamp?)?.toDate() ??
                (bData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
            return bDate.compareTo(aDate);
          });

        final filteredDocs = sortedDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] as String?)?.toUpperCase() ?? '';
          if (isPast) {
            return ['COMPLETED', 'REJECTED', 'CANCELLED'].contains(status);
          } else {
            return [
              'PENDING',
              'ACCEPTED',
              'DIAGNOSTICS',
              'IN_PROGRESS',
              'IN SERVICE',
              'TESTING',
            ].contains(status);
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isPast ? Icons.history : Icons.event_available, size: 64, color: Colors.white12),
                const SizedBox(height: 16),
                Text(
                  isPast ? 'No past services found.' : 'No upcoming services found.',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) setState(() {});
          },
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) => _buildServiceItem(filteredDocs[index], index == filteredDocs.length - 1, isPast),
          ),
        );
      },
    );
  }

  Widget _buildOrdersStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('purchases')
          .where('userId', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        
        final docs = snapshot.data?.docs ?? [];
        final sortedDocs = docs.toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

        if (sortedDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.white12),
                const SizedBox(height: 16),
                const Text('No product orders found.', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) setState(() {});
          },
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) => _buildOrderItem(sortedDocs[index], index == sortedDocs.length - 1),
          ),
        );
      },
    );
  }

  Widget _buildServiceItem(QueryDocumentSnapshot doc, bool isLast, bool isPast) {
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    data['id'] = doc.id;
    
    final title = data['service'] ?? 'General Service';
    final vehicle = data['vehicle'] ?? 'Unknown Vehicle';
    final status = data['status'] ?? 'UNKNOWN';
    final price = data['amount'] != null
        ? '\$${(data['amount'] as num).toStringAsFixed(2)}'
        : '\$0.00';
    final date = (data['appointmentDate'] as Timestamp?)?.toDate() ??
        (data['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(date);
    final location = data['serviceCenterName'] ?? 'GearUp Service Center';

    IconData icon = Icons.settings_suggest;
    if (title.toLowerCase().contains('oil')) icon = Icons.oil_barrel;
    if (title.toLowerCase().contains('brake') || title.toLowerCase().contains('tire')) icon = Icons.tire_repair;

    return _buildEntry(
      title: title,
      subtitle: vehicle,
      status: status,
      date: dateStr,
      location: location,
      price: price,
      icon: icon,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBr7wk28RrPX4KcQ5ArovZK7lQ45_yrnIN5OL8xKr_6NQPK-v6eHCtKJAUG5ClosQfMnm9iJNf_M5-sFuqSEwf2ACFnIcECeZXYHvwU6ggl9pyCgxV0y2LoEwiVNdd6DHTkpvUJJcHzsQ2pPBAuAGEudo3pyOfjPE-ESafoUwwfFteRunQ0OpFcKYeK9dG2FO-MhMiT7Soxl1HZeQz2rymbSKAnJlCn8eutNkTRCoegElLE4vn5d5GomiOMi-D5wb1N6ZN42t_TbWI',
      isLast: isLast,
      data: data,
      isPast: isPast,
      isService: true,
    );
  }

  Widget _buildOrderItem(QueryDocumentSnapshot doc, bool isLast) {
    final data = doc.data() as Map<String, dynamic>;
    final total = (data['price'] ?? 0.0) * (data['quantity'] ?? 1);
    final status = data['status'] ?? 'pending';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(createdAt);
    
    final title = data['partName'] ?? 'Spare Part';
    final subtitle = 'Qty: ${data['quantity'] ?? 1}';
    final price = '₹${total.toStringAsFixed(2)}';
    final location = data['trackingId'] != null ? 'Tracking: ${data['trackingId']}' : 'Preparing for shipment';
    final imageUrl = data['imageUrl'] ?? '';

    return _buildEntry(
      title: title,
      subtitle: subtitle,
      status: status,
      date: dateStr,
      location: location,
      price: price,
      icon: Icons.local_shipping,
      imageUrl: imageUrl,
      isLast: isLast,
      data: data,
      isPast: status == 'delivered',
      isService: false,
    );
  }

  Widget _buildEntry({
    required String title,
    required String subtitle,
    required String status,
    required String date,
    required String location,
    required String price,
    required IconData icon,
    required String imageUrl,
    required bool isLast,
    required Map<String, dynamic> data,
    required bool isPast,
    required bool isService,
  }) {
    Color statusColor = AppTheme.accent;
    final paymentStatus = (data['paymentStatus'] as String?)?.toUpperCase() ?? '';
    final isRefunded = paymentStatus == 'REFUNDED' || status.toUpperCase() == 'REFUNDED';

    if (isRefunded) {
      statusColor = Colors.red;
    } else if (status.toUpperCase() == 'REJECTED' || status.toUpperCase() == 'CANCELLED') {
      statusColor = Colors.red;
    } else if (status.toUpperCase() == 'PENDING') {
      statusColor = Colors.orange;
    } else if (status.toUpperCase() == 'COMPLETED' || status.toUpperCase() == 'DELIVERED') {
      statusColor = Colors.greenAccent;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: 0,
                    child: Container(width: 2, color: const Color(0xFF4d3267)),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.backgroundDark, width: 4),
                  ),
                  child: Icon(icon, color: AppTheme.accent, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRefunded ? 'REFUNDED' : status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('$date • $location', style: const TextStyle(fontSize: 13, color: Colors.white54)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF261933),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4d3267)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        if (imageUrl.isNotEmpty)
                          _buildImage(imageUrl, width: double.infinity, height: 128),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRefunded ? 'Amount Refunded' : (isPast ? 'Total Paid' : 'Amount'),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  Text(
                                    price,
                                    style: TextStyle(
                                      color: isRefunded ? Colors.white54 : AppTheme.accent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      decoration: isRefunded ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                              if (isService && status.toUpperCase() == 'COMPLETED')
                                _buildActionButton('View Receipt', () => _viewReceipt(title, subtitle, location, price, date, data)),
                              if (!isService)
                                _buildActionButton('Details', () => _viewOrderDetails(data)),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
        foregroundColor: AppTheme.accent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  void _viewOrderDetails(Map<String, dynamic> initialData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('purchases').doc(initialData['id'] ?? initialData['orderId']).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.hasData ? (snapshot.data!.data() as Map<String, dynamic>?) ?? initialData : initialData;
            final status = data['status'] ?? 'pending';
            
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Live Tracking', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailedTrackingStepper(status),
                  const Divider(height: 48, color: Colors.white12),
                  const Text('Item Information', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                          ? _buildImage(data['imageUrl'].toString(), width: 64, height: 64)
                          : Container(width: 64, height: 64, color: Colors.white10),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['partName'] ?? 'Spare Part', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Qty: ${data['quantity']} • ₹${(data['price'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 48, color: Colors.white12),
                  _detailRow('Order Status', status.toUpperCase(), isBold: true),
                  _detailRow('Tracking ID', data['trackingId'] ?? 'Not assigned yet'),
                  _detailRow('Delivery Address', data['address'] ?? 'N/A'),
                  _detailRow('Contact Phone', data['phone'] ?? 'N/A'),
                  const Divider(height: 48, color: Colors.white12),
                  _detailRow('Total Amount', '₹${((data['price'] ?? 0) * (data['quantity'] ?? 1)).toStringAsFixed(2)}', isBold: true),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('BACK TO HISTORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildDetailedTrackingStepper(String status) {
    final steps = ['pending', 'shipped', 'out for delivery', 'delivered'];
    final currentIndex = steps.indexOf(status.toLowerCase());
    
    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == steps.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.primary : Colors.white10,
                      shape: BoxShape.circle,
                      border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 14,
                      color: isCompleted ? Colors.white : Colors.white24,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted ? AppTheme.primary : Colors.white10,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index].toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.white : Colors.white24,
                      ),
                    ),
                    Text(
                      _getTrackingStepDesc(steps[index]),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.white54 : Colors.white10,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getTrackingStepDesc(String step) {
    switch (step) {
      case 'pending': return 'Service center is reviewing your order';
      case 'shipped': return 'Your package has been handed over to courier';
      case 'out for delivery': return 'The delivery partner is on the way to you';
      case 'delivered': return 'Package delivered successfully';
      default: return '';
    }
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  void _viewReceipt(String title, String subtitle, String location, String price, String date, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        double selectedRating = 0;
        return Dialog(
          backgroundColor: AppTheme.backgroundDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECEIPT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  _receiptRow('Service', title),
                  _receiptRow('Vehicle', subtitle),
                  _receiptRow('Center', location),
                  _receiptRow('Date', date),
                  const Divider(height: 48, color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL PAID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
                      Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Simple rating if completed
                  if (data['status'] == 'COMPLETED' && data['rating'] == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RATE YOUR EXPERIENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
                        const SizedBox(height: 8),
                        StatefulBuilder(builder: (context, setStarState) {
                          return Row(
                            children: List.generate(5, (index) => IconButton(
                              icon: Icon(index < selectedRating ? Icons.star : Icons.star_border, color: AppTheme.accent),
                              onPressed: () => setStarState(() => selectedRating = index + 1.0),
                            )),
                          );
                        }),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedRating == 0) return;
                            await FirebaseFirestore.instance.collection('bookings').doc(data['id']).update({'rating': selectedRating});
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 44)),
                          child: const Text('SUBMIT'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Center(child: Text('Close', style: TextStyle(color: Colors.white54)))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildImage(String source, {double? width, double? height}) {
    if (source.startsWith('data:image')) {
      try {
        final base64Str = source.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.white10,
          child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
        );
      }
    }
    return CachedNetworkImage(
      imageUrl: source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(width: width, height: height, color: Colors.white10),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.white10,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
      ),
    );
  }
}
