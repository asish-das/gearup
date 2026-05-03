import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gearup/services/auth_service.dart';
import 'package:gearup/models/user.dart';
import 'package:gearup/services/vehicle_service.dart';
import 'package:gearup/models/vehicle.dart';
import 'package:gearup/mobile_user/service_centers.dart';
import 'package:gearup/mobile_user/service_history.dart';
import 'package:gearup/mobile_user/notification_screen.dart';
import 'package:gearup/services/ai_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeDashboard extends StatefulWidget {
  final Function(int)? onTabSelected;
  const HomeDashboard({super.key, this.onTabSelected});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  User? _currentUser;
  bool _isLoading = true;
  Vehicle? _primaryVehicle;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        // Load User Data first
        final userData = await AuthService.getUserData(user.uid);
        setState(() {
          _currentUser = userData;
        });

        // Then try to load vehicles independently
        try {
          final vehicles = await VehicleService.getUserVehicles(user.uid);
          setState(() {
            _primaryVehicle = vehicles.isNotEmpty ? vehicles.first : null;
          });
        } catch (vehicleError) {
          debugPrint('Error loading vehicles: $vehicleError');
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickVehicleImage(Vehicle vehicle) async {
    try {
      final picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (imageFile != null) {
        setState(() {
          _isLoading = true;
        });
        
        final File image = File(imageFile.path);
        final bytes = await image.readAsBytes();
        final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

        await VehicleService.updateVehicle(vehicle.id, {
          'imageUrl': base64Image,
        });

        await _loadUserData(); // Reload list
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle image updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking vehicle image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No user data available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              backgroundImage: _getProfileImageProvider(_currentUser!.profileImageUrl),
              child: (_currentUser!.profileImageUrl == null || _currentUser!.profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person, color: AppTheme.primary, size: 20)
                  : null,
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: AuthService.currentUser?.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface.withValues(alpha: 0.5),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${DateTime.now().hour < 12
                  ? 'Morning'
                  : DateTime.now().hour < 17
                  ? 'Afternoon'
                  : 'Evening'}, ${_currentUser!.name.split(' ').first}.',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _primaryVehicle != null
                  ? 'Your ${_primaryVehicle!.make} is looking great today.'
                  : 'Welcome to GearUp.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 32),
            _buildVehicleCard(),
            const SizedBox(height: 32),
            _buildAIRecommendations(),
            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    Icons.calendar_month_outlined,
                    'Service',
                    () {
                      if (widget.onTabSelected != null) {
                        widget.onTabSelected!(2);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServiceCentersScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  _buildQuickAction(
                    Icons.history_outlined,
                    'History',
                    () {
                      if (widget.onTabSelected != null) {
                        widget.onTabSelected!(4);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActivityHistoryScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  _buildQuickAction(Icons.near_me_outlined, 'Nearby', () {}),
                  _buildQuickAction(
                    Icons.emergency_outlined,
                    'Emergency',
                    () => Navigator.pushNamed(context, '/emergency'),
                    isAlert: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendations() {
    if (_primaryVehicle == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AIService.aiConfigStream(),
      builder: (context, snapshot) {
        final config = snapshot.data?.data();
        final enableHealth = config?['enable_health_alerts'] ?? true;
        final enableSuggestions = config?['enable_service_suggestions'] ?? true;

        if (!enableHealth && !enableSuggestions) return const SizedBox.shrink();

        // Dynamic checks based on real vehicle data
        final List<Widget> alerts = [];
        
        if (enableHealth) {
          final kmSinceService = _primaryVehicle!.kilometers - _primaryVehicle!.lastServiceKm;
          if (kmSinceService > 5000) {
            alerts.add(_buildInsightCard(
              'Maintenance Alert',
              'Your ${_primaryVehicle!.make} has traveled $kmSinceService km since the last service. A checkup is recommended.',
              Icons.warning_amber_rounded,
              Colors.orangeAccent,
            ));
          } else if (!_primaryVehicle!.isConnected) {
            alerts.add(_buildInsightCard(
              'Connection Lost',
              'We haven\'t received data from your vehicle in a while.',
              Icons.link_off_rounded,
              Colors.orangeAccent,
            ));
          } else {
            // Default "Good Health" info
            alerts.add(_buildInsightCard(
              'System Health',
              'All systems in your ${_primaryVehicle!.make} are performing optimally.',
              Icons.check_circle_outline_rounded,
              Colors.greenAccent,
            ));
          }
        }

        if (enableSuggestions) {
          if (alerts.isNotEmpty) alerts.add(const SizedBox(height: 12));
          
          // Time-based or randomized relevant tips
          final now = DateTime.now();
          if (now.hour < 10) {
            alerts.add(_buildInsightCard(
              'Morning Tip',
              'Smooth acceleration helps improve fuel/energy efficiency and extends engine life.',
              Icons.lightbulb_outline_rounded,
              AppTheme.primary,
            ));
          } else {
            alerts.add(_buildInsightCard(
              'Maintenance Tip',
              'Check your tire pressure monthly for better safety and longevity.',
              Icons.info_outline_rounded,
              AppTheme.primary,
            ));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'BETA',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...alerts,
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
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
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    if (_primaryVehicle == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.directions_car, color: AppTheme.primary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Vehicle Registered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first vehicle to get started',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddVehicleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () => _pickVehicleImage(_primaryVehicle!),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _primaryVehicle!.imageUrl.isNotEmpty &&
                                  _getProfileImageProvider(
                                        _primaryVehicle!.imageUrl,
                                      ) !=
                                      null
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  child: Image(
                                    image: _getProfileImageProvider(
                                      _primaryVehicle!.imageUrl,
                                    )!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderCar(),
                                  ),
                                )
                              : _buildPlaceholderCar(),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _primaryVehicle!.model.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (_primaryVehicle!.licensePlate.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _primaryVehicle!.licensePlate.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailItem('Make', _primaryVehicle!.make),
                            _buildDetailVerticalDivider(),
                            _buildDetailItem('Model', _primaryVehicle!.model),
                            _buildDetailVerticalDivider(),
                            _buildDetailItem('Year', _primaryVehicle!.year),
                            _buildDetailVerticalDivider(),
                            _buildDetailItem('Color', _primaryVehicle!.color),
                            _buildDetailVerticalDivider(),
                            _buildDetailItem('Mileage', '${_primaryVehicle!.kilometers}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderCar() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.directions_car, color: AppTheme.primary, size: 48),
      ),
    );
  }

  void _showAddVehicleDialog() {
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final colorController = TextEditingController();
    final licensePlateController = TextEditingController();
    final kmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Area
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Add New Vehicle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildThemedTextField(
                        controller: makeController,
                        label: 'Make',
                        hint: 'e.g., Tesla',
                        icon: Icons.directions_car,
                      ),
                      const SizedBox(height: 16),
                      _buildThemedTextField(
                        controller: modelController,
                        label: 'Model',
                        hint: 'e.g., Model S',
                        icon: Icons.category,
                      ),
                      const SizedBox(height: 16),
                      _buildThemedTextField(
                        controller: yearController,
                        label: 'Year',
                        hint: 'e.g., 2023',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildThemedTextField(
                        controller: colorController,
                        label: 'Color',
                        hint: 'e.g., Red',
                        icon: Icons.palette,
                      ),
                      const SizedBox(height: 16),
                      _buildThemedTextField(
                        controller: kmController,
                        label: 'Mileage',
                        hint: 'e.g., 12000',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions Area
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDialogButton(
                        'Cancel',
                        Colors.grey,
                        () => Navigator.pop(context),
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDialogButton(
                        'Add Vehicle',
                        AppTheme.primary,
                        () async {
                          if (_currentUser != null &&
                              makeController.text.isNotEmpty &&
                              modelController.text.isNotEmpty &&
                              yearController.text.isNotEmpty) {
                            try {
                              final vehicle = Vehicle(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                make: makeController.text.trim(),
                                model: modelController.text.trim(),
                                year: yearController.text.trim(),
                                color: colorController.text.trim(),
                                licensePlate: licensePlateController.text
                                    .trim(),
                                userId: _currentUser!.uid,
                                kilometers: int.tryParse(kmController.text.trim()) ?? 0,
                                lastServiceKm: int.tryParse(kmController.text.trim()) ?? 0,
                                isConnected: true,
                              );

                              await VehicleService.addVehicle(vehicle);
                              await _loadUserData(); // Refresh vehicle list

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vehicle added successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error adding vehicle: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: AppTheme.primary.withValues(alpha: 0.8),
            size: 22,
          ),
          labelStyle: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    return Container(
      decoration: isOutlined
          ? BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            )
          : BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  color: isOutlined ? Colors.white : AppTheme.backgroundDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isAlert = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAlert
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppTheme.surface.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: isAlert
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Icon(
              icon,
              color: isAlert ? Colors.redAccent : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isAlert ? Colors.redAccent : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImageProvider(String? source) {
    if (source == null || source.isEmpty) return null;
    if (source.startsWith('data:image')) {
      try {
        final base64Str = source.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        return null;
      }
    }
    return CachedNetworkImageProvider(source);
  }
}
