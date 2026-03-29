import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'dart:async';
import '../models/user.dart';
import '../models/vehicle.dart';
import '../services/export_service.dart';
import 'package:intl/intl.dart';

class VehicleOwnersView extends StatefulWidget {
  const VehicleOwnersView({super.key});

  @override
  State<VehicleOwnersView> createState() => _VehicleOwnersViewState();
}

class _VehicleOwnersViewState extends State<VehicleOwnersView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<User> _users = [];
  List<Vehicle> _vehicles = [];
  String _searchQuery = '';
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All Owners', 'Active', 'Suspended'];
  String _selectedRegistration = 'Recent';
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  StreamSubscription<QuerySnapshot>? _vehiclesSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _vehiclesSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Real-time users listener
    _usersSubscription = _firestore
        .collection('users')
        .where('role', isEqualTo: 'vehicleOwner')
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            List<User> users = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['uid'] = doc.id;
              return User.fromMap(data);
            }).toList();

            // Sort locally in descending order by createdAt
            users.sort((a, b) {
              final aDate = a.createdAt ?? '';
              final bDate = b.createdAt ?? '';
              return bDate.compareTo(aDate);
            });

            if (mounted) {
              setState(() {
                _users = users;
              });
            }
          },
          onError: (error) {
            debugPrint('Error listening to users: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error loading users: $error',
                    style: GoogleFonts.manrope(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );

    // Real-time vehicles listener
    _vehiclesSubscription = _firestore.collection('vehicles').snapshots().listen(
      (QuerySnapshot snapshot) {
        List<Vehicle> vehicles = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Vehicle.fromMap(data);
        }).toList();

        // Sort in memory to catch items missing createdAt field
        vehicles.sort((a, b) {
          final aTime = a.createdAt != null ? DateTime.tryParse(a.createdAt!) : null;
          final bTime = b.createdAt != null ? DateTime.tryParse(b.createdAt!) : null;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (mounted) {
          setState(() {
            _vehicles = vehicles;
          });
        }
      },
          onError: (error) {
            debugPrint('Error listening to vehicles: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error loading vehicles: $error',
                    style: GoogleFonts.manrope(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
  }

  void _showExportDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Export Data',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose export format:', style: GoogleFonts.manrope()),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('PDF Document', style: GoogleFonts.manrope()),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    String filePath = await ExportService.exportToPDF(
                      _users,
                      _vehicles,
                    );
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PDF exported successfully!',
                              style: GoogleFonts.manrope(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saved to: $filePath',
                              style: GoogleFonts.manrope(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to export PDF: $e',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: Text('CSV File', style: GoogleFonts.manrope()),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    String filePath = await ExportService.exportToCSV(
                      _users,
                      _vehicles,
                    );
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CSV exported successfully!',
                              style: GoogleFonts.manrope(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saved to: $filePath',
                              style: GoogleFonts.manrope(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to export CSV: $e',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Colors.blue),
                title: Text('Text File', style: GoogleFonts.manrope()),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    String filePath = await ExportService.exportToText(
                      _users,
                      _vehicles,
                    );
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Text file exported successfully!',
                              style: GoogleFonts.manrope(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saved to: $filePath',
                              style: GoogleFonts.manrope(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to export Text: $e',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(color: const Color(0xFF5D40D4)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : 32.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildProfileSection(isMobile),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildSearchBar()),
                    _buildProfileSection(isMobile),
                  ],
                ),
              SizedBox(height: isMobile ? 16 : 32),
              // Title and Export
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 16),
                    _buildExportButton(),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_buildTitleSection(), _buildExportButton()],
                ),
              const SizedBox(height: 24),
              // Filters
              Builder(
                builder: (context) {
                  final tabCounts = [
                    _users.length,
                    _users
                        .where((u) => (u.status ?? 'active') == 'active')
                        .length,
                    _users
                        .where((u) => (u.status ?? 'active') == 'suspended')
                        .length,
                  ];
                  final tabsRow = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _tabs.length; i++) ...[
                        _buildTab(
                          '${_tabs[i]} (${tabCounts[i]})',
                          i,
                          i == _selectedTabIndex,
                        ),
                        if (i < _tabs.length - 1) const SizedBox(width: 32),
                      ],
                    ],
                  );

                  final filterWidget = _buildFilterDropdown(
                    'Registration',
                    _selectedRegistration,
                    ['Recent', 'Oldest'],
                    Icons.calendar_today,
                    (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRegistration = value;
                        });
                      }
                    },
                  );

                  if (isMobile) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          filterWidget,
                          const SizedBox(width: 32),
                          tabsRow,
                        ],
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: filterWidget,
                        ),
                      ),
                      tabsRow,
                      const Expanded(child: SizedBox()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Table Area
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _usersSubscription != null
                      ? FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'vehicleOwner')
                            .snapshots()
                      : Stream.empty(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Something went wrong'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasData) {
                      final docs = snapshot.data!.docs;
                      final users = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['uid'] = doc.id;
                        return User.fromMap(data);
                      }).toList();

                      // Sort users locally
                      users.sort((a, b) {
                        final aDate = a.createdAt ?? '';
                        final bDate = b.createdAt ?? '';
                        return bDate.compareTo(aDate);
                      });

                      List<User> filteredUsers = users;
                      if (_selectedTabIndex == 1) {
                        filteredUsers = users
                            .where((u) => u.status == 'active')
                            .toList();
                      } else if (_selectedTabIndex == 2) {
                        filteredUsers = users
                            .where((u) => u.status == 'suspended')
                            .toList();
                      }

                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        filteredUsers = filteredUsers.where((user) {
                          final nameMatches = user.name.toLowerCase().contains(
                            query,
                          );
                          final emailMatches = user.email
                              .toLowerCase()
                              .contains(query);
                          final phoneMatches = (user.phoneNumber ?? '')
                              .toLowerCase()
                              .contains(query);
                          return nameMatches || emailMatches || phoneMatches;
                        }).toList();
                      }

                      if (_selectedRegistration == 'Oldest') {
                        filteredUsers = filteredUsers.reversed.toList();
                      }

                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, tableConstraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 1000,
                                  ),
                                  child: SizedBox(
                                    width: tableConstraints.maxWidth > 1000
                                        ? tableConstraints.maxWidth
                                        : 1000,
                                    child: Column(
                                      children: [
                                        _buildTableHeader(),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: filteredUsers.length,
                                            itemBuilder: (context, index) {
                                              final user = filteredUsers[index];
                                              final userVehicles = _vehicles
                                                  .where(
                                                    (v) => v.userId == user.uid,
                                                  )
                                                  .toList();
                                              return _buildUserTableRow(
                                                user,
                                                userVehicles,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }

                    // Show empty state when no data
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return const Center(child: Text('No data available'));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search owners by name, email or phone...',
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
    );
  }

  Widget _buildProfileSection(bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            if (!isMobile)
              FutureBuilder<DocumentSnapshot?>(
                future: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get()
                    : Future.value(null),
                builder: (context, snapshot) {
                  String name = 'Admin';
                  String role = 'Admin';
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      name = data['name'] ?? 'Admin';
                      role = data['role'] ?? 'Admin';
                      role = role == 'superAdmin'
                          ? 'Super Admin'
                          : '${role[0].toUpperCase()}${role.substring(1)}';
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        role,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            if (!isMobile) const SizedBox(width: 12),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D40D4), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D40D4).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Owners',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and monitor registered vehicle owners across the platform.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: _showExportDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF5D40D4).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.file_download, color: Color(0xFF5D40D4), size: 20),
            const SizedBox(width: 8),
            Text(
              'Export Data',
              style: GoogleFonts.manrope(
                color: const Color(0xFF5D40D4),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String currentValue,
    List<String> items,
    IconData icon,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0F172A), size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.manrope(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              value: currentValue,
              icon: const Icon(
                Icons.expand_more,
                color: Color(0xFF64748B),
                size: 18,
              ),
              style: GoogleFonts.manrope(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF5D40D4) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.manrope(
            color: isActive ? const Color(0xFF5D40D4) : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No vehicle owners found',
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vehicle owners will appear here once they register',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NAME', style: _headerStyle())),
          Expanded(
            flex: 3,
            child: Text('CONTACT INFORMATION', style: _headerStyle()),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('VEHICLES', style: _headerStyle()),
            ),
          ),
          Expanded(flex: 3, child: Text('LAST BOOKING', style: _headerStyle())),
          Expanded(flex: 2, child: Text('STATUS', style: _headerStyle())),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('ACTIONS', style: _headerStyle()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _suspendOwner(User user) async {
    try {
      String newStatus = (user.status ?? 'active') == 'active'
          ? 'suspended'
          : 'active';

      await _firestore.collection('users').doc(user.uid).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'active'
                ? 'Owner activated successfully!'
                : 'Owner suspended successfully!',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: newStatus == 'active' ? Colors.green : Colors.orange,
        ),
      );

      // Data is now updated in real-time via listeners
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating owner status: $e',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteOwner(User user) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Owner',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this owner?',
                style: GoogleFonts.manrope(),
              ),
              const SizedBox(height: 12),
              Text(
                'Name: ${user.name}',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
              ),
              Text(
                'Email: ${user.email}',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: GoogleFonts.manrope(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        // Delete user's vehicles first
        QuerySnapshot vehicleSnapshot = await _firestore
            .collection('vehicles')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in vehicleSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete user
        await _firestore.collection('users').doc(user.uid).delete();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Owner and all associated vehicles deleted successfully!',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Data is now updated in real-time via listeners
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting owner: $e',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOwnerDetailsDialog(User user, List<Vehicle> userVehicles) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Owner Details',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name.substring(0, 1).toUpperCase()
                              : '?',
                          style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D40D4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,

                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.role.displayName,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (user.status ?? 'active') == 'active'
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.1)
                                  : const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: (user.status ?? 'active') == 'active'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (user.status ?? 'active') == 'active'
                                      ? 'Active'
                                      : 'Suspended',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: (user.status ?? 'active') == 'active'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
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
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoCard('Contact Information', [
                        _buildInfoRow('Email', user.email),
                        _buildInfoRow(
                          'Phone',
                          user.phoneNumber ?? 'Not provided',
                        ),
                        if (user.businessName != null)
                          _buildInfoRow('Business', user.businessName!),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard('Account Information', [
                        _buildInfoRow(
                          'User ID',
                          '${user.uid.substring(0, 8)}...',
                        ),
                        _buildInfoRow(
                          'Member Since',
                          user.createdAt != null
                              ? DateFormat(
                                  'y',
                                ).format(DateTime.parse(user.createdAt!))
                              : '2023',
                        ),
                        _buildInfoRow(
                          'Total Vehicles',
                          userVehicles.length.toString(),
                        ),
                      ]),
                    ),
                  ],
                ),
                if (userVehicles.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Vehicles',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: userVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = userVehicles[index];
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.displayName,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'License: ${vehicle.licensePlate}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Color: ${vehicle.color}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Mileage: ${vehicle.kilometers} KM',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF5D40D4),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Color(0xFF5D40D4),
                                    ),
                                    onPressed: () => _updateVehicleMileage(vehicle),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Update Mileage',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTableRow(User user, List<Vehicle> userVehicles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF5D40D4),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.createdAt != null
                            ? 'Member since ${DateFormat('MMM yyyy').format(DateTime.parse(user.createdAt!))}'
                            : 'Member since ${user.uid.substring(0, 8)}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
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
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.email,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.phoneNumber ?? 'No phone',
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
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D40D4).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_car_outlined,
                      size: 14,
                      color: Color(0xFF5D40D4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      userVehicles.length.toString(),
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF5D40D4),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recent bookings',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'N/A',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
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
                    color: (user.status ?? 'active') == 'active'
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: (user.status ?? 'active') == 'active'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (user.status ?? 'active') == 'active'
                            ? 'Active'
                            : 'Suspended',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (user.status ?? 'active') == 'active'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _showOwnerDetailsDialog(user, userVehicles),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
                    ),
                    child: Text(
                      'View',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF5D40D4),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _suspendOwner(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: (user.status ?? 'active') == 'active'
                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                    ),
                    child: Text(
                      (user.status ?? 'active') == 'active'
                          ? 'Suspend'
                          : 'Activate',
                      style: GoogleFonts.manrope(
                        color: (user.status ?? 'active') == 'active'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteOwner(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.manrope(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _updateVehicleMileage(Vehicle vehicle) {
    final controller = TextEditingController(
      text: vehicle.kilometers.toString(),
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(
              'Update Mileage',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Kilometers',
                labelStyle: TextStyle(color: Color(0xFF5D40D4)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newKms = int.tryParse(controller.text);
                  if (newKms != null) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('vehicles')
                          .doc(vehicle.id)
                          .update({'id': vehicle.id, 'kilometers': newKms});
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mileage updated!'),
                            backgroundColor: Colors.green,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D40D4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }
}
