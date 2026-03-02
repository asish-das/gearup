import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingsView extends StatelessWidget {
  const BookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F6F8),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Row(
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
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
                          decoration: InputDecoration(
                            hintText:
                                'Search by customer, vehicle or service ID...',
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
              const SizedBox(width: 24),
              _buildFilterChip('All', true),
              const SizedBox(width: 12),
              _buildFilterChip('Pending', false),
              const SizedBox(width: 12),
              _buildFilterChip('Accepted', false),
              const SizedBox(width: 12),
              _buildFilterChip('In Service', false),
              const SizedBox(width: 12),
              _buildFilterChip('Completed', false),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.6,
              children: [
                _buildBookingCard(
                  name: 'Sarah Jenkins',
                  id: '#BK-8291',
                  status: 'PENDING',
                  statusColor: Colors.orange,
                  vehicle: 'Toyota Camry 2021',
                  service: 'Full Service + Oil Change',
                  bottomLeftLabel: 'Appointment',
                  bottomLeftValue: 'Oct 24, 09:00 AM',
                  bottomRightLabel: 'Contact',
                  bottomRightValue: '+1 234-567-890',
                  actionButtonLabel: 'Accept Booking',
                  actionColor: const Color(0xFF5D40D4),
                  outlinesButton: false,
                  hasIconAction: true,
                ),
                _buildBookingCard(
                  name: 'Marcus Thorne',
                  id: '#BK-8292',
                  status: 'ACCEPTED',
                  statusColor: Colors.blue,
                  vehicle: 'BMW M4 2022',
                  service: 'Brake Pad Replacement',
                  bottomLeftLabel: 'Appointment',
                  bottomLeftValue: 'Oct 24, 11:30 AM',
                  bottomRightLabel: 'Status',
                  bottomRightValue: 'Scheduled',
                  bottomRightValueColor: Colors.blue,
                  actionButtonLabel: 'Start Service',
                  actionColor: const Color(0xFF0F172A), // Dark navy
                  outlinesButton: false,
                  hasIconAction: true,
                ),
                _buildBookingCard(
                  name: 'David Chen',
                  id: '#BK-8293',
                  status: 'IN SERVICE',
                  statusColor: const Color(0xFF5D40D4),
                  vehicle: 'Audi Q7 2020',
                  vehicleColor: const Color(0xFF5D40D4),
                  service: 'Engine Diagnostic',
                  bottomLeftLabel: '',
                  bottomLeftValue: '',
                  bottomRightLabel: '',
                  bottomRightValue: '',
                  actionButtonLabel: 'Mark Completed',
                  actionColor: const Color(0xFF10B981), // Green
                  outlinesButton: false,
                  hasIconAction: true,
                  isHighlighted: true,
                  progressVal: 0.75,
                ),
                _buildBookingCard(
                  name: 'Elena Rossi',
                  id: '#BK-8290',
                  status: 'COMPLETED',
                  statusColor: Colors.green,
                  vehicle: 'Tesla Model 3',
                  service: 'Tire Rotation',
                  bottomLeftLabel: 'Completed At',
                  bottomLeftValue: 'Today, 08:30 AM',
                  bottomRightLabel: 'Bill Amount',
                  bottomRightValue: '\$120.00',
                  bottomRightValueColor: Colors.green,
                  actionButtonLabel: 'View Receipt',
                  actionColor: const Color(0xFF64748B),
                  outlinesButton: true,
                  hasIconAction: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return Container(
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
    );
  }

  Widget _buildBookingCard({
    required String name,
    required String id,
    required String status,
    required Color statusColor,
    required String vehicle,
    Color vehicleColor = const Color(0xFF0F172A),
    required String service,
    required String bottomLeftLabel,
    required String bottomLeftValue,
    required String bottomRightLabel,
    required String bottomRightValue,
    Color bottomRightValueColor = const Color(0xFF0F172A),
    required String actionButtonLabel,
    required Color actionColor,
    required bool outlinesButton,
    required bool hasIconAction,
    bool isHighlighted = false,
    double progressVal = 0,
  }) {
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
                  color: const Color(0xFF5D40D4).withOpacity(0.1),
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
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: statusColor),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: $id',
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
                          : statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
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
                          vehicle,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: vehicleColor,
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
                          service,
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
                              color: bottomRightValueColor,
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
                      '75%',
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
                    value: progressVal,
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
                          actionButtonLabel,
                          style: GoogleFonts.manrope(
                            color: outlinesButton ? actionColor : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasIconAction) ...[
                    const SizedBox(width: 16),
                    Container(
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
