import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gearup/services/vehicle_service.dart';
import 'package:gearup/models/vehicle.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isBooking = false;

  String? _serviceCenterId;
  String? _serviceCenterName;
  String? _serviceName;
  String? _serviceDesc;
  String? _priceStr;

  List<Map<String, dynamic>> _serviceCenterSlots = [];
  List<String> _bookedTimes = [];
  bool _isLoadingSlots = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_serviceCenterId == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _serviceName = args?['name'] ?? 'General Service';
      _serviceDesc = args?['desc'] ?? 'Standard maintenance';
      _priceStr = args?['price'] ?? '\$0';
      _serviceCenterId = args?['serviceCenterId'];
      _serviceCenterName = args?['serviceCenterName'];

      _fetchServiceCenterSlots();
    }
  }

  Future<void> _fetchServiceCenterSlots() async {
    if (_serviceCenterId == null) return;

    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_serviceCenterId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final slotConfig = data['slotConfig'] as Map<String, dynamic>? ?? {};
        final List<dynamic> slotsList =
            slotConfig['slots'] ??
            [
              {'time': '09:00 AM', 'status': 0},
              {'time': '10:30 AM', 'status': 0},
              {'time': '12:00 PM', 'status': 0},
              {'time': '01:30 PM', 'status': 0},
              {'time': '03:00 PM', 'status': 0},
              {'time': '04:30 PM', 'status': 0},
            ];

        if (mounted) {
          setState(() {
            _serviceCenterSlots = slotsList
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _fetchBookedSlotsForDate() async {
    if (_serviceCenterId == null || _selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceCenterId', isEqualTo: _serviceCenterId)
          .get();

      List<String> bookedTimes = [];
      for (var doc in query.docs) {
        final data = doc.data();
        final bookingDateStr = data['dateString'] as String?;
        final legacyDateIso = data['date'] as String?;

        bool isMatchingDate = false;
        if (bookingDateStr != null) {
          isMatchingDate = (bookingDateStr == dateStr);
        } else if (legacyDateIso != null) {
          try {
            final parsedDate = DateTime.parse(legacyDateIso);
            final formattedLegacy = DateFormat('yyyy-MM-dd').format(parsedDate);
            isMatchingDate = (formattedLegacy == dateStr);
          } catch (_) {}
        }

        if (isMatchingDate) {
          if (data['status'] != 'cancelled' && data['status'] != 'rejected') {
            if (data['time'] != null) {
              bookedTimes.add(data['time'] as String);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _bookedTimes = bookedTimes;
        });
      }
    } catch (e) {
      debugPrint('Error fetching booked slots: \$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: AppTheme.backgroundDark,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time on new date
      });
      _fetchBookedSlotsForDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse price
    final double basePrice =
        double.tryParse((_priceStr ?? '\$0').replaceAll('\$', '')) ?? 0.0;
    final double serviceFee = 5.00; // Mock service fee
    final double taxes = basePrice * 0.08;
    final double total = basePrice + serviceFee + taxes;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _serviceName ?? 'Service',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _serviceDesc ?? 'Description',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    _selectedDate == null
                        ? 'Choose Date'
                        : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedDate == null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.yellow.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber, color: Colors.yellow, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please select a date to view available time slots.',
                        style: TextStyle(color: Colors.yellow, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Select Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _isLoadingSlots
                    ? [const CircularProgressIndicator()]
                    : _serviceCenterSlots.isEmpty
                    ? [
                        const Text(
                          'No slots available',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ]
                    : _serviceCenterSlots.map((slot) {
                        final String time = slot['time'];
                        final int configStatus = slot['status'] ?? 0;
                        final bool isUnavailable =
                            configStatus != 0 || _bookedTimes.contains(time);
                        final isSelected = _selectedTime == time;

                        return InkWell(
                          onTap: isUnavailable
                              ? null
                              : () {
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : isUnavailable
                                  ? AppTheme.surface.withValues(alpha: 0.2)
                                  : AppTheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : isUnavailable
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : isUnavailable
                                        ? Colors.white24
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    decoration: isUnavailable
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUnavailable ? 'Booked' : 'Available',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white70
                                        : isUnavailable
                                        ? Colors.redAccent.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCostRow(
                    'Service Cost',
                    '\$${basePrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _buildCostRow(
                    'Service Fee',
                    '\$${serviceFee.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _buildCostRow('Taxes (8%)', '\$${taxes.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed:
                  (_selectedDate == null || _selectedTime == null || _isBooking)
                  ? null
                  : () async {
                      if (_serviceCenterId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid service center.'),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isBooking = true;
                      });

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          throw Exception('User not logged in');
                        }

                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                        final userData = userDoc.data() ?? {};

                        // Fetch user vehicles to attach to booking
                        final vehicles = await VehicleService.getUserVehicles(
                          user.uid,
                        );
                        Vehicle? defaultVehicle;
                        if (vehicles.isNotEmpty) {
                          defaultVehicle = vehicles.first;
                        }

                        DateTime appointmentDateTime = _selectedDate!;
                        if (_selectedTime != null &&
                            _selectedTime!.isNotEmpty) {
                          try {
                            final timeFormat = DateFormat('hh:mm a');
                            final parsedTime = timeFormat.parse(_selectedTime!);
                            appointmentDateTime = DateTime(
                              _selectedDate!.year,
                              _selectedDate!.month,
                              _selectedDate!.day,
                              parsedTime.hour,
                              parsedTime.minute,
                            );
                          } catch (e) {
                            // fallback
                          }
                        }

                        final bookingData = {
                          'userId': user.uid,
                          'name':
                              userData['name'] ??
                              userData['fullName'] ??
                              'Customer',
                          'contact': userData['phoneNumber'] ?? '',
                          'customerName':
                              userData['name'] ??
                              userData['fullName'] ??
                              'Customer', // legacy
                          'customerPhone':
                              userData['phoneNumber'] ?? '', // legacy
                          'vehicleId': defaultVehicle?.id ?? '',
                          'vehicle': defaultVehicle != null
                              ? '${defaultVehicle.year} ${defaultVehicle.make} ${defaultVehicle.model}'
                              : 'Unknown Vehicle',
                          'serviceCenterId': _serviceCenterId,
                          'serviceCenterName':
                              _serviceCenterName ?? 'Service Center',
                          'service': _serviceName,
                          'serviceName': _serviceName, // legacy
                          'date': _selectedDate!.toIso8601String(), // legacy
                          'dateString': DateFormat(
                            'yyyy-MM-dd',
                          ).format(_selectedDate!),
                          'time': _selectedTime,
                          'appointmentDate': Timestamp.fromDate(
                            appointmentDateTime,
                          ),
                          'amount': total,
                          'totalAmount': total, // legacy
                          'status': 'PENDING',
                          'createdAt': FieldValue.serverTimestamp(),
                        };

                        final docRef = await FirebaseFirestore.instance
                            .collection('bookings')
                            .add(bookingData);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking confirmed!')),
                        );
                        // Navigate to tracking or back to home
                        Navigator.pushNamed(
                          context,
                          '/tracking',
                          arguments: {
                            'trackingId': docRef.id,
                            'serviceName': _serviceName,
                          },
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to book: \$e')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isBooking = false;
                          });
                        }
                      }
                    },
              icon: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isBooking ? 'Processing...' : 'Confirm Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white54,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
