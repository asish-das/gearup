import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _garageNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isLoading = true;

  final Map<String, Map<String, dynamic>> _operatingHours = {
    'Monday': {'isOpen': true, 'open': '08:00 AM', 'close': '06:00 PM'},
    'Tuesday': {'isOpen': true, 'open': '08:00 AM', 'close': '06:00 PM'},
    'Wednesday': {'isOpen': true, 'open': '08:00 AM', 'close': '06:00 PM'},
    'Thursday': {'isOpen': true, 'open': '08:00 AM', 'close': '06:00 PM'},
    'Friday': {'isOpen': true, 'open': '08:00 AM', 'close': '06:00 PM'},
    'Saturday': {'isOpen': false, 'open': '08:00 AM', 'close': '06:00 PM'},
    'Sunday': {'isOpen': false, 'open': '08:00 AM', 'close': '06:00 PM'},
  };

  final Map<String, String> _serviceCategoryDesc = {
    'Mechanic': 'General repairs, engines',
    'Wash & Detail': 'Interior & exterior cleaning',
    'Tire Shop': 'Alignment & replacement',
    'Electrical': 'Diagnostics & wiring',
    'Oil & Fluids': 'Fast maintenance',
    'Body Shop': 'Paint & collision repair',
  };

  final Map<String, bool> _serviceCategories = {
    'Mechanic': false,
    'Wash & Detail': false,
    'Tire Shop': false,
    'Electrical': false,
    'Oil & Fluids': false,
    'Body Shop': false,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _garageNameController.text = data['businessName'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phoneNumber'] ?? '';
            _descriptionController.text = data['description'] ?? '';
            _imageUrlController.text = data['profileImageUrl'] ?? '';

            if (data['operatingHours'] != null) {
              final hours = data['operatingHours'] as Map<String, dynamic>;
              hours.forEach((key, value) {
                if (_operatingHours.containsKey(key)) {
                  _operatingHours[key] = Map<String, dynamic>.from(value);
                }
              });
            }

            if (data['serviceCategories'] != null) {
              final cats = data['serviceCategories'] as Map<String, dynamic>;
              cats.forEach((key, value) {
                if (_serviceCategories.containsKey(key)) {
                  _serviceCategories[key] = value as bool;
                }
              });
            }
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'businessName': _garageNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'profileImageUrl': _imageUrlController.text.trim(),
        // Cannot update auth email safely here, just contact email optionally:
        'email': _emailController.text.trim(),
        'operatingHours': _operatingHours,
        'serviceCategories': _serviceCategories,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      final String base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
      setState(() {
        _imageUrlController.text = base64Image;
      });
    }
  }

  @override
  void dispose() {
    _garageNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(String day, bool isOpeningTime) async {
    final currentTimeStr = isOpeningTime
        ? _operatingHours[day]!['open'] as String
        : _operatingHours[day]!['close'] as String;

    TimeOfDay initialTime = TimeOfDay.now();
    try {
      if (currentTimeStr.isNotEmpty) {
        final isPM = currentTimeStr.contains('PM');
        final parts = currentTimeStr.split(RegExp(r'[: ]'));
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          if (isPM && hour != 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && mounted) {
      setState(() {
        final formattedTime = picked.format(context);
        if (isOpeningTime) {
          _operatingHours[day]!['open'] = formattedTime;
        } else {
          _operatingHours[day]!['close'] = formattedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final Widget hoursColumn = Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: Text('DAY', style: _headerStyle())),
            Expanded(flex: 2, child: Text('OPEN', style: _headerStyle())),
            Expanded(flex: 2, child: Text('CLOSE', style: _headerStyle())),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('STATUS', style: _headerStyle()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (String day in [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ])
          _buildHoursRow(day),
      ],
    );

    return Container(
      color: const Color(0xFFF6F6F8),
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Settings',
                      style: GoogleFonts.manrope(
                        fontSize: isDesktop ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Manage your garage details and operating preferences.',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 32),

          // Section 1: Business Details
          _buildResponsiveSection(
            isDesktop: isDesktop,
            title: 'Business Details',
            subtitle:
                'Basic information about your service center visible to customers.',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isMobile ? 60 : 80,
                      height: isMobile ? 60 : 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        image: _imageUrlController.text.isNotEmpty
                            ? DecorationImage(
                                image: _buildImageProvider(_imageUrlController.text),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageUrlController.text.isEmpty
                          ? Icon(
                              Icons.image,
                              color: const Color(0xFF94A3B8),
                              size: isMobile ? 24 : 32,
                            )
                          : null,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Garage Logo',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recommended: 400x400px, PNG or JPG.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.upload, size: 16),
                                label: const Text('Change Logo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5D40D4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              if (_imageUrlController.text.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () => setState(() => _imageUrlController.clear()),
                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildTextField('Garage Name', _garageNameController),
                const SizedBox(height: 24),
                if (isMobile) ...[
                  _buildTextField(
                    'Contact Email',
                    _emailController,
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField('Phone Number', _phoneController),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Contact Email',
                          _emailController,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          'Phone Number',
                          _phoneController,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                _buildTextField(
                  'Business Description',
                  _descriptionController,
                  maxLines: 3,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Section 2: Operating Hours
          _buildResponsiveSection(
            isDesktop: isDesktop,
            title: 'Operating Hours',
            subtitle: 'Set your weekly schedule and break times.',
            content: isDesktop
                ? hoursColumn
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width:
                          600, // ensure horizontal scroll works correctly on narrow screens
                      child: hoursColumn,
                    ),
                  ),
          ),

          const SizedBox(height: 48),

          // Section 3: Service Categories
          _buildResponsiveSection(
            isDesktop: isDesktop,
            title: 'Service Categories',
            subtitle:
                'Select the types of services you provide at this location.',
            content: Column(
              children: [
                if (isMobile) ...[
                  _buildCategoryCard('Mechanic'),
                  const SizedBox(height: 16),
                  _buildCategoryCard('Wash & Detail'),
                  const SizedBox(height: 16),
                  _buildCategoryCard('Tire Shop'),
                  const SizedBox(height: 16),
                  _buildCategoryCard('Electrical'),
                  const SizedBox(height: 16),
                  _buildCategoryCard('Oil & Fluids'),
                  const SizedBox(height: 16),
                  _buildCategoryCard('Body Shop'),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _buildCategoryCard('Mechanic')),
                      const SizedBox(width: 24),
                      Expanded(child: _buildCategoryCard('Wash & Detail')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildCategoryCard('Tire Shop')),
                      const SizedBox(width: 24),
                      Expanded(child: _buildCategoryCard('Electrical')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildCategoryCard('Oil & Fluids')),
                      const SizedBox(width: 24),
                      Expanded(child: _buildCategoryCard('Body Shop')),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 48),
          // Section 4: Account & Security
          _buildResponsiveSection(
            isDesktop: isDesktop,
            title: 'Account & Security',
            subtitle: 'Manage your login credentials and security.',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registered Email',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emailController.text,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    if (email.isNotEmpty) {
                      try {
                        await AuthService.resetPassword(email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password reset email sent to $email',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
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
                    }
                  },
                  icon: const Icon(Icons.lock_reset, size: 20),
                  label: const Text('Send Password Reset Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5D40D4),
                    side: const BorderSide(color: Color(0xFF5D40D4)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadProfile();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cancel Changes',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _saveProfile(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D40D4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Save All Settings',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveSection({
    required bool isDesktop,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
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
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: content,
            ),
          ),
        ],
      );
    } else {
      return Column(
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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: content,
          ),
        ],
      );
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _buildImageProvider(String source) {
    if (source.startsWith('data:image')) {
      try {
        final base64Str = source.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        return const NetworkImage('https://via.placeholder.com/150');
      }
    }
    return NetworkImage(source.isNotEmpty ? source : 'https://via.placeholder.com/150');
  }

  TextStyle _headerStyle() {
    return GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF94A3B8),
      letterSpacing: 1.1,
    );
  }

  Widget _buildHoursRow(String day) {
    bool isOpen = _operatingHours[day]!['isOpen'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isOpen ? FontWeight.w600 : FontWeight.normal,
                color: isOpen
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(flex: 2, child: _buildTimePicker(day, true, isOpen)),
          Expanded(flex: 2, child: _buildTimePicker(day, false, isOpen)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Switch(
                value: isOpen,
                onChanged: (v) {
                  setState(() {
                    _operatingHours[day]!['isOpen'] = v;
                  });
                },
                activeThumbColor: const Color(0xFF5D40D4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String day, bool isOpeningTime, bool isActive) {
    String time = isOpeningTime
        ? _operatingHours[day]!['open'] as String
        : _operatingHours[day]!['close'] as String;

    return InkWell(
      onTap: isActive ? () => _pickTime(day, isOpeningTime) : null,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: const Color(0xFFE2E8F0))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: isActive
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
            if (isActive)
              const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title) {
    bool isSelected = _serviceCategories[title] ?? false;
    String subtitle = _serviceCategoryDesc[title] ?? '';

    return InkWell(
      onTap: () {
        setState(() {
          _serviceCategories[title] = !isSelected;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5D40D4)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5D40D4)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : const SizedBox(width: 16, height: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
