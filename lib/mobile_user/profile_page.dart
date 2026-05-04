import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gearup/mobile_user/service_history.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gearup/services/auth_service.dart';
import 'package:gearup/models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gearup/services/vehicle_service.dart';
import 'package:gearup/models/vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';


class ProfilePage extends StatefulWidget {
  final Function(int)? onTabSelected;
  const ProfilePage({super.key, this.onTabSelected});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  bool _isLoading = true;
  List<Vehicle> _vehicles = [];
  bool _isLoadingVehicles = true;

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
            _vehicles = vehicles;
            _isLoadingVehicles = false;
          });
        } catch (vehicleError) {
          debugPrint('Error loading vehicles: $vehicleError');
          setState(() {
            _isLoadingVehicles = false;
          });
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingVehicles = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingVehicles = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (imageFile != null) {
        final File image = File(imageFile.path);
        await _uploadImageToFirebase(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageToFirebase(File image) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Encode image to Base64 string directly
      final bytes = await image.readAsBytes();
      final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

      // Update user data in Firestore
      await AuthService.updateProfileImageUrl(_currentUser!.uid, base64Image);

      // Reload user data to get updated profile image
      await _loadUserData();

      setState(() {
        _isLoading = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image stored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          _isLoadingVehicles = true;
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
              content: Text('Vehicle image saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
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
        title: Text(
          'Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface.withValues(alpha: 0.5),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white70,
                size: 22,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppTheme.surface,
                    backgroundImage: _getProfileImageProvider(_currentUser!.profileImageUrl),
                    child: (_currentUser!.profileImageUrl == null || _currentUser!.profileImageUrl!.isEmpty)
                        ? const Icon(
                            Icons.person_outline,
                            color: AppTheme.primary,
                            size: 40,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _currentUser!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_currentUser!.role.displayName} • Since ${DateTime.now().year}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showEditProfileDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surface.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildPreferredServicesSection(),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MANAGE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppTheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildVehiclesSection(),

            const SizedBox(height: 12),
            _buildListTile(
              Icons.history,
              'Activity History',
              'View services & orders',
              onTap: () {
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
            const SizedBox(height: 12),
            _buildListTile(Icons.payments, 'Subscription', 'GearUp Gold Plan', onTap: () {}),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () async {
                await AuthService.signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildListTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    ),
    );
  }

  Widget _buildVehiclesSection() {
    if (_isLoadingVehicles) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.directions_car, color: AppTheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              'No Vehicles Registered',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to manage your fleet',
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

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              '${_vehicles.length} Vehicle${_vehicles.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddVehicleDialog(),
                  icon: const Icon(Icons.add, color: AppTheme.primary),
                  label: const Text(
                    'Add Vehicle',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._vehicles.map((vehicle) => _buildVehicleCard(vehicle)),
      ],
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Decorative background glow
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Image or Icon
                        GestureDetector(
                          onTap: () => _pickVehicleImage(vehicle),
                          child: Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: vehicle.imageUrl.isNotEmpty && _getProfileImageProvider(vehicle.imageUrl) != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image(
                                          image: _getProfileImageProvider(vehicle.imageUrl)!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.directions_car,
                                              color: AppTheme.primary.withValues(
                                                alpha: 0.8,
                                              ),
                                              size: 32,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.directions_car,
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                        size: 32,
                                      ),
                              ),
                              Positioned(
                                bottom: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.surface, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Vehicle Identity
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
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
                                  vehicle.licensePlate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.speed,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${vehicle.kilometers}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Status indicators removed as requested
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: Colors.white70,
                          onTap: () => _showEditVehicleDialog(vehicle),
                        ),
                        _buildActionButton(
                          icon: Icons.info_outline,
                          label: 'Details',
                          color: Colors.blueAccent.withValues(alpha: 0.8),
                          onTap: () => _showVehicleDetails(vehicle),
                        ),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Remove',
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          onTap: () => _deleteVehicle(vehicle),
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferredServicesSection() {
    final Map<String, dynamic> categoryConfig = {
      'Engine': {'icon': Icons.engineering, 'color': const Color(0xFF6366F1)},
      'Wash': {'icon': Icons.local_car_wash, 'color': const Color(0xFF0EA5E9)},
      'Oil': {'icon': Icons.water_drop, 'color': const Color(0xFFF59E0B)},
      'Brakes': {'icon': Icons.album, 'color': const Color(0xFFEF4444)},
      'Tyres': {'icon': Icons.adjust, 'color': const Color(0xFF10B981)},
      'Repair': {'icon': Icons.build_circle, 'color': const Color(0xFF8B5CF6)},
      'AC': {'icon': Icons.ac_unit, 'color': const Color(0xFF06B6D4)},
      'Electrical': {'icon': Icons.electric_bolt, 'color': const Color(0xFFEAB308)},
    };

    final userCategories = _currentUser?.serviceCategories ?? {};
    final selectedCategories = userCategories.entries
        .where((e) => e.value == true)
        .map((e) {
          final config = categoryConfig[e.key] ?? {'icon': Icons.build, 'color': AppTheme.primary};
          return {
            'label': e.key,
            'icon': config['icon'],
            'color': config['color'],
          };
        })
        .toList();

    if (selectedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIGHLIGHTED SERVICES',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your frequently used categories',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Priority',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: selectedCategories.length,
            itemBuilder: (context, index) {
              final cat = selectedCategories[index];
              final color = cat['color'] as Color;
              return Container(
                width: 85,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 12,
                            spreadRadius: -2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.08),
                            ),
                          ),
                          Icon(
                            cat['icon'] as IconData,
                            color: color,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat['label'] as String,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showVehicleDetails(Vehicle vehicle) {
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
                        Icons.info_outline,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        vehicle.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.directions_car, 'Make', vehicle.make),
                    _buildDetailRow(Icons.category, 'Model', vehicle.model),
                    _buildDetailRow(Icons.calendar_today, 'Year', vehicle.year),
                    _buildDetailRow(Icons.palette, 'Color', vehicle.color),
                    _buildDetailRow(
                      Icons.confirmation_number,
                      'License Plate',
                      vehicle.licensePlate,
                    ),
                    _buildDetailRow(
                      Icons.speed,
                      'Mileage',
                      '${vehicle.kilometers}',
                    ),
                  ],
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
                child: SizedBox(
                  width: double.infinity,
                  child: _buildDialogButton(
                    'Close',
                    AppTheme.primary,
                    () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primary.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog() {
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final colorController = TextEditingController();
    final licensePlateController = TextEditingController();
    final kilometersController = TextEditingController();

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
                        controller: licensePlateController,
                        label: 'License Plate',
                        hint: 'e.g., ABC-1234',
                        icon: Icons.confirmation_number,
                      ),
                      const SizedBox(height: 16),
                      _buildThemedTextField(
                        controller: kilometersController,
                        label: 'Mileage',
                        hint: 'e.g., 1000',
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
                                kilometers: int.tryParse(kilometersController.text.trim()) ?? 0,
                                isConnected: true,
                              );

                              await VehicleService.addVehicle(vehicle);
                              await _loadUserData(); // Refresh vehicle list

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vehicle added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding vehicle: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
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

  void _showEditVehicleDialog(Vehicle vehicle) {
    final makeController = TextEditingController(text: vehicle.make);
    final modelController = TextEditingController(text: vehicle.model);
    final yearController = TextEditingController(text: vehicle.year);
    final colorController = TextEditingController(text: vehicle.color);
    final licensePlateController = TextEditingController(
      text: vehicle.licensePlate,
    );
    final kilometersController = TextEditingController(
      text: vehicle.kilometers.toString(),
    );

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
                        Icons.edit_road,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Edit Vehicle',
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
                        controller: licensePlateController,
                        label: 'License Plate',
                        hint: 'e.g., ABC-1234',
                        icon: Icons.confirmation_number,
                      ),
                      const SizedBox(height: 16),
                      _buildThemedTextField(
                        controller: kilometersController,
                        label: 'Mileage',
                        hint: 'e.g., 5000',
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
                        'Save Changes',
                        AppTheme.primary,
                        () async {
                          if (makeController.text.isNotEmpty &&
                              modelController.text.isNotEmpty &&
                              yearController.text.isNotEmpty) {
                            try {
                              final updatedVehicle = Vehicle(
                                id: vehicle.id,
                                make: makeController.text.trim(),
                                model: modelController.text.trim(),
                                year: yearController.text.trim(),
                                color: colorController.text.trim(),
                                licensePlate: licensePlateController.text
                                    .trim(),
                                userId: vehicle.userId,
                                imageUrl: vehicle.imageUrl,
                                kilometers: int.tryParse(kilometersController.text.trim()) ?? 0,
                                lastServiceKm: vehicle.lastServiceKm,
                                isConnected: vehicle.isConnected,
                              );

                              await VehicleService.updateVehicle(
                                vehicle.id,
                                updatedVehicle.toMap(),
                              );
                              await _loadUserData(); // Refresh vehicle list

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Vehicle updated successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating vehicle: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
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

  void _showEditProfileDialog() {
    if (_currentUser == null) return;

    final nameController = TextEditingController(text: _currentUser!.name);
    final phoneController = TextEditingController(
      text: _currentUser!.phoneNumber,
    );
    Map<String, bool> selectedCategories = Map<String, bool>.from(_currentUser!.serviceCategories ?? {});
    
    final List<String> availableCategories = [
      'Engine', 'Wash', 'Oil', 'Brakes', 'Tyres', 'Repair', 'AC', 'Electrical'
    ];

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
                      child: const Icon(Icons.person, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildThemedTextField(
                        controller: nameController,
                        label: 'Full Name',
                        hint: 'e.g., John Doe',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildThemedTextField(
                        controller: phoneController,
                        label: 'Phone Number',
                        hint: 'e.g., +1 234 567 8900',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SERVICE PREFERENCES',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppTheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatefulBuilder(
                        builder: (context, setDialogState) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableCategories.map((category) {
                              final isSelected = selectedCategories[category] ?? false;
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (bool value) {
                                  setDialogState(() {
                                    selectedCategories[category] = value;
                                  });
                                },
                                backgroundColor: AppTheme.surface,
                                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppTheme.primary : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
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
                        'Save',
                        AppTheme.primary,
                        () async {
                          if (nameController.text.isNotEmpty) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_currentUser!.uid)
                                  .update({
                                    'name': nameController.text.trim(),
                                    'phoneNumber': phoneController.text.trim(),
                                    'serviceCategories': selectedCategories,
                                  });
                              await _loadUserData();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profile updated successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating profile: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
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

  void _deleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.2),
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
                      color: Colors.redAccent.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Remove Vehicle',
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Are you sure you want to remove your ${vehicle.displayName} from the fleet? This action cannot be undone.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
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
                      color: Colors.redAccent.withValues(alpha: 0.2),
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
                        'Remove',
                        Colors.redAccent,
                        () async {
                          try {
                            await VehicleService.deleteVehicle(vehicle.id);
                            await _loadUserData(); // Refresh vehicle list

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vehicle removed successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error removing vehicle: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
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
