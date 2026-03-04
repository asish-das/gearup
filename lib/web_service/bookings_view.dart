import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookingData {
  final String id;
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
    required this.name,
    required this.status,
    required this.vehicle,
    required this.service,
    required this.appointmentDate,
    required this.contact,
    required this.amount,
    this.progressVal = 0.0,
  });
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
    'Accepted',
    'In Service',
    'Completed',
  ];

  late List<BookingData> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = [
      BookingData(
        id: '#BK-8291',
        name: 'Sarah Jenkins',
        status: 'PENDING',
        vehicle: 'Toyota Camry 2021',
        service: 'Full Service + Oil Change',
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
        contact: '+1 234-567-890',
        amount: 240.0,
      ),
      BookingData(
        id: '#BK-8292',
        name: 'Marcus Thorne',
        status: 'ACCEPTED',
        vehicle: 'BMW M4 2022',
        service: 'Brake Pad Replacement',
        appointmentDate: DateTime.now().add(
          const Duration(days: 1, hours: 2, minutes: 30),
        ),
        contact: '+1 987-654-321',
        amount: 180.0,
      ),
      BookingData(
        id: '#BK-8293',
        name: 'David Chen',
        status: 'IN SERVICE',
        vehicle: 'Audi Q7 2020',
        service: 'Engine Diagnostic',
        appointmentDate: DateTime.now().subtract(const Duration(hours: 1)),
        contact: '+1 555-123-456',
        amount: 320.0,
        progressVal: 0.75,
      ),
      BookingData(
        id: '#BK-8290',
        name: 'Elena Rossi',
        status: 'COMPLETED',
        vehicle: 'Tesla Model 3',
        service: 'Tire Rotation',
        appointmentDate: DateTime.now().subtract(const Duration(hours: 4)),
        contact: '+1 444-987-654',
        amount: 120.0,
        progressVal: 1.0,
      ),
    ];
  }

  void _updateStatus(BookingData booking) {
    setState(() {
      if (booking.status == 'PENDING') {
        booking.status = 'ACCEPTED';
      } else if (booking.status == 'ACCEPTED') {
        booking.status = 'IN SERVICE';
        booking.progressVal = 0.1;
      } else if (booking.status == 'IN SERVICE') {
        booking.status = 'COMPLETED';
        booking.progressVal = 1.0;
      } else if (booking.status == 'COMPLETED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing receipt for ${booking.id}...'),
            backgroundColor: const Color(0xFF5D40D4),
          ),
        );
      }
    });
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
    final filteredBookings = _bookings.where((booking) {
      final matchesFilter =
          _activeFilter == 'All' ||
          booking.status.toUpperCase() == _activeFilter.toUpperCase();
      final matchesSearch =
          booking.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          booking.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          booking.vehicle.toLowerCase().contains(_searchQuery.toLowerCase());
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
                    return _buildDynamicBookingCard(filteredBookings[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
                          Text(
                            booking.name,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
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
                  Expanded(
                    child: InkWell(
                      onTap: () => _updateStatus(booking),
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
                  if (booking.status != 'COMPLETED') ...[
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing info for ${booking.id}...'),
                          ),
                        );
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
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
