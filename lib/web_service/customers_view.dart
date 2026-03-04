import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CustomersView extends StatelessWidget {
  const CustomersView({super.key});

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
                'Customer Management',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
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
                    const Icon(Icons.person_add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Customer',
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
                    decoration: InputDecoration(
                      hintText:
                          'Search by name, email, phone or vehicle plate...',
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Customer List
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            color: Color(0xFFF8FAFC),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'CUSTOMER NAME',
                                  style: _headerStyle(),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'LAST SERVICE',
                                  style: _headerStyle(),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('BOOKINGS', style: _headerStyle()),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'CONTACT INFO',
                                  style: _headerStyle(),
                                ),
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
                        Expanded(
                          child: ListView(
                            children: [
                              _buildCustomerRow(
                                'Alex Johnson',
                                'BMW 3 Series (${DateTime.now().year - 2})',
                                DateFormat('MMM dd, yyyy').format(
                                  DateTime.now().subtract(
                                    const Duration(days: 5),
                                  ),
                                ),
                                '12',
                                'alex.j@email.com',
                                '+1 555-0102',
                                true,
                              ),
                              _buildCustomerRow(
                                'Maria Garcia',
                                'Audi Q5 (${DateTime.now().year - 4})',
                                DateFormat('MMM dd, yyyy').format(
                                  DateTime.now().subtract(
                                    const Duration(days: 8),
                                  ),
                                ),
                                '5',
                                'm.garcia@email.com',
                                '+1 555-0198',
                                false,
                              ),
                              _buildCustomerRow(
                                'James Smith',
                                'Tesla Model 3 (${DateTime.now().year})',
                                DateFormat('MMM dd, yyyy').format(
                                  DateTime.now().subtract(
                                    const Duration(days: 15),
                                  ),
                                ),
                                '24',
                                'jsmith@email.com',
                                '+1 555-0144',
                                false,
                              ),
                              _buildCustomerRow(
                                'Linda Chen',
                                'Honda Civic (${DateTime.now().year - 5})',
                                DateFormat('MMM dd, yyyy').format(
                                  DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                ),
                                '2',
                                'lchen@email.com',
                                '+1 555-0155',
                                false,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing 4 of 248 customers',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left,
                                      size: 20,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Right Panel: Customer Details
                Expanded(
                  flex: 2,
                  child: Column(
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
                                      'Alex Johnson',
                                      style: GoogleFonts.manrope(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'ID: #CUST-9821',
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BMW 3 Series',
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '2021 • G20 • 330i',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'PLATE',
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          color: const Color(0xFF5D40D4),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'B8821-XP',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
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
                            _buildHistoryRow(
                              'Oil Change & Inspection',
                              DateFormat('dd MMM yyyy').format(
                                DateTime.now().subtract(
                                  const Duration(days: 45),
                                ),
                              ),
                              'Full synthetic oil, oil filter, air filter, multipoint inspection.',
                            ),
                            _buildHistoryRow(
                              'Brake Pad Replacement',
                              DateFormat('dd MMM yyyy').format(
                                DateTime.now().subtract(
                                  const Duration(days: 120),
                                ),
                              ),
                              'Front ceramic brake pads, rotor resurfacing.',
                            ),
                            _buildHistoryRow(
                              'Tire Rotation',
                              DateFormat('dd MMM yyyy').format(
                                DateTime.now().subtract(
                                  const Duration(days: 200),
                                ),
                              ),
                              'Four wheel balance and rotation.',
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'View All History (12)',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D40D4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text('INTERNAL NOTES', style: _headerStyle()),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                '"Customer prefers original BMW parts only. Usually drops off the car early in the morning."',
                                style: GoogleFonts.manrope(
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5D40D4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Create Order',
                                        style: GoogleFonts.manrope(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Edit Profile',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF0F172A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.2),
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
                                  'Premium Member • 15% Discount',
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
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildCustomerRow(
    String name,
    String vehicle,
    String date,
    String bookings,
    String email,
    String phone,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isSelected ? const Color(0xFF5D40D4) : Colors.transparent,
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
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF5D40D4)
                        : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  vehicle,
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
              date,
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
                    bookings,
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
                  email,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  phone,
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
                'Details',
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
}
