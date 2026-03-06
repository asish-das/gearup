import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerData {
  final String userId;
  String name;
  String email;
  String phone;
  final String vehicle;
  final DateTime lastServiceDate;
  final int bookingsCount;
  final List<DocumentSnapshot> bookings;

  CustomerData({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicle,
    required this.lastServiceDate,
    required this.bookingsCount,
    required this.bookings,
  });
}

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  String _searchQuery = '';
  CustomerData? _selectedCustomer;

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

        // Group bookings by user
        Map<String, List<DocumentSnapshot>> userBookingsMap = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId']?.toString() ?? 'unknown';
            if (!userBookingsMap.containsKey(userId)) {
              userBookingsMap[userId] = [];
            }
            userBookingsMap[userId]!.add(doc);
          }
        }

        List<CustomerData> customers = userBookingsMap.entries.map((entry) {
          final userId = entry.key;
          final bookings = entry.value;

          // Sort bookings by date descending
          bookings.sort((a, b) {
            final dateA =
                (a.data() as Map<String, dynamic>)['appointmentDate']
                    as Timestamp?;
            final dateB =
                (b.data() as Map<String, dynamic>)['appointmentDate']
                    as Timestamp?;
            final tA =
                dateA?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tB =
                dateB?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA);
          });

          final latestBookingData =
              bookings.first.data() as Map<String, dynamic>;
          final name =
              latestBookingData['name'] ??
              latestBookingData['customerName'] ??
              'Unknown Customer';
          final vehicle = latestBookingData['vehicle'] ?? 'Unknown Vehicle';
          final contact = latestBookingData['contact'] ?? 'Unknown Contact';
          final lastDateStamp =
              latestBookingData['appointmentDate'] as Timestamp?;
          final lastDate = lastDateStamp?.toDate() ?? DateTime.now();

          return CustomerData(
            userId: userId,
            name: name,
            email: 'Loading...',
            phone: contact,
            vehicle: vehicle,
            lastServiceDate: lastDate,
            bookingsCount: bookings.length,
            bookings: bookings,
          );
        }).toList();

        // Apply Search Filter
        final filteredCustomers = customers.where((c) {
          final s = _searchQuery.toLowerCase();
          return c.name.toLowerCase().contains(s) ||
              c.email.toLowerCase().contains(s) ||
              c.phone.toLowerCase().contains(s) ||
              c.vehicle.toLowerCase().contains(s);
        }).toList();

        // Ensure selected customer exists or clear selection
        if (_selectedCustomer != null) {
          try {
            _selectedCustomer = filteredCustomers.firstWhere(
              (c) => c.userId == _selectedCustomer!.userId,
            );
          } catch (_) {
            _selectedCustomer = null; // not found in list anymore
          }
        }

        if (_selectedCustomer == null && filteredCustomers.isNotEmpty) {
          _selectedCustomer = filteredCustomers.first;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double padding = constraints.maxWidth < 600 ? 16.0 : 32.0;
            return Container(
              color: const Color(0xFFF6F6F8),
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 600;
                      final headerContent = [
                        Text(
                          'Customer Management',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (!isDesktop) const SizedBox(height: 16),
                      ];

                      if (isDesktop) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: headerContent,
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: headerContent,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(
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
                              hintText:
                                  'Search by name, email, phone or vehicle ...',
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
                  const SizedBox(height: 32),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isDesktop = constraints.maxWidth > 1100;

                        Widget customerList = _buildCustomerList(
                          filteredCustomers,
                          isMobile: !isDesktop,
                        );
                        Widget customerDetails = _buildCustomerDetails(
                          _selectedCustomer,
                        );

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: customerList),
                              const SizedBox(width: 32),
                              Expanded(flex: 2, child: customerDetails),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                customerList,
                                const SizedBox(height: 32),
                                customerDetails,
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerList(
    List<CustomerData> customers, {
    bool isMobile = false,
  }) {
    if (customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: Text("No customers found")),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              color: Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('CUSTOMER NAME', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('LAST SERVICE', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('BOOKINGS', style: _headerStyle()),
                ),
                Expanded(
                  flex: 3,
                  child: Text('CONTACT INFO', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('ACTIONS', style: _headerStyle()),
                  ),
                ),
              ],
            ),
          ),
          if (isMobile)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return _buildCustomerRow(customer);
              },
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return _buildCustomerRow(customer);
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${customers.length} customers',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails(CustomerData? customer) {
    if (customer == null) {
      return Container();
    }

    // Attempt real-time fetch of user info if possible (though we can also just rely on stream, it's safer doing it dynamically)
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(customer.userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          customer.name = data['name'] ?? data['fullName'] ?? customer.name;
          customer.email = data['email'] ?? 'No email';
          customer.phone = data['phone'] ?? customer.phone;
        } else {
          customer.email = 'No email in profile';
        }

        return Column(
          children: [
            Container(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'ID: #${customer.userId.length > 8 ? customer.userId.substring(0, 8) : customer.userId}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF5D40D4),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('VEHICLE DETAILS', style: _headerStyle()),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.vehicle,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Registered Vehicle',
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
                  const SizedBox(height: 24),
                  Text('SERVICE HISTORY', style: _headerStyle()),
                  const SizedBox(height: 16),
                  ...customer.bookings.take(5).map((doc) {
                    final bData = doc.data() as Map<String, dynamic>;
                    final serviceName = bData['service'] ?? 'General Service';
                    final sDate = bData['appointmentDate'] as Timestamp?;
                    final dateStr = sDate != null
                        ? DateFormat('dd MMM yyyy').format(sDate.toDate())
                        : 'Unknown Date';
                    final bStatus = bData['status'] ?? 'PENDING';

                    return _buildHistoryRow(
                      '$serviceName ($bStatus)',
                      dateStr,
                      'Vehicle: ${bData['vehicle']}',
                    );
                  }),
                  if (customer.bookings.length > 5) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _showAllBookingsDialog(customer);
                        },
                        child: Text(
                          'View All History (${customer.bookings.length})',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D40D4),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.loyalty,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOYALTY STATUS',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        customer.bookingsCount > 5
                            ? 'Premium Member'
                            : 'Standard Member',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

  Widget _buildCustomerRow(CustomerData customer) {
    bool isSelected = _selectedCustomer?.userId == customer.userId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(customer.userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          customer.name = data['name'] ?? data['fullName'] ?? customer.name;
          customer.email = data['email'] ?? 'No email';
          customer.phone = data['phone'] ?? customer.phone;
        }

        return InkWell(
          onTap: () {
            setState(() {
              _selectedCustomer = customer;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
              border: Border(
                left: BorderSide(
                  color: isSelected
                      ? const Color(0xFF5D40D4)
                      : Colors.transparent,
                  width: 4,
                ),
                bottom: const BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF5D40D4)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        customer.vehicle,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(customer.lastServiceDate),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
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
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          customer.bookingsCount.toString(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.email,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        customer.phone,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      isSelected ? 'Selected' : 'Details',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D40D4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryRow(String title, String date, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllBookingsDialog(CustomerData customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Complete Service History',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Customer: ${customer.name}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: customer.bookings.length,
                    itemBuilder: (context, index) {
                      final booking = customer.bookings[index];
                      final data = booking.data() as Map<String, dynamic>;
                      final date =
                          (data['appointmentDate'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      final dateStr = DateFormat('MMM dd, yyyy').format(date);
                      final serviceName =
                          data['serviceName'] ?? 'Unknown Service';
                      final status = data['status'] ?? 'Unknown';
                      final vehicle = data['vehicle'] ?? 'Unknown Vehicle';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceName,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  dateStr,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vehicle: $vehicle',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF10B981);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      case 'IN_PROGRESS':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }
}
