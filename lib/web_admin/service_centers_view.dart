import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/user.dart';
import '../services/export_service.dart';
import 'package:intl/intl.dart';

class ServiceCentersView extends StatefulWidget {
  const ServiceCentersView({super.key});

  @override
  State<ServiceCentersView> createState() => _ServiceCentersViewState();
}

class _ServiceCentersViewState extends State<ServiceCentersView> {
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  String _selectedRegistration = 'Recent';
  final List<String> _tabs = [
    'All Centers',
    'Approved (Active)',
    'Suspended',
    'Pending Approval',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 800;
        final padding = isSmall ? 16.0 : 32.0;

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(isSmall),
              SizedBox(height: isSmall ? 16 : 32),
              _buildHeader(isSmall),
              SizedBox(height: isSmall ? 16 : 32),
              Expanded(child: _buildMainContent(isSmall)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(bool isSmall) {
    final searchWidget = Container(
      height: 48,
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
                hintText: 'Search centers...',
                hintStyle: GoogleFonts.manrope(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );

    final profileWidget = Row(
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
            if (!isSmall)
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
                      // format role
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
            if (!isSmall) const SizedBox(width: 12),
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

    if (isSmall) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: searchWidget),
              const SizedBox(width: 16),
              profileWidget,
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: searchWidget,
          ),
        ),
        profileWidget,
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
                    final snapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'serviceCenter')
                        .get();
                    final usersList = snapshot.docs
                        .map((doc) => User.fromMap(doc.data()))
                        .toList();
                    String filePath = await ExportService.exportToPDF(
                      usersList,
                      [],
                    );
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'PDF exported successfully to $filePath',
                          style: GoogleFonts.manrope(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
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
                    final snapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'serviceCenter')
                        .get();
                    final usersList = snapshot.docs
                        .map((doc) => User.fromMap(doc.data()))
                        .toList();
                    String filePath = await ExportService.exportToCSV(
                      usersList,
                      [],
                    );
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'CSV exported successfully to $filePath',
                          style: GoogleFonts.manrope(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
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
                    final snapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'serviceCenter')
                        .get();
                    final usersList = snapshot.docs
                        .map((doc) => User.fromMap(doc.data()))
                        .toList();
                    String filePath = await ExportService.exportToText(
                      usersList,
                      [],
                    );
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Text file exported successfully to $filePath',
                          style: GoogleFonts.manrope(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
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

  void _showServiceCenterDetailsDialog(User user) {
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
                          user.businessName?.isNotEmpty == true
                              ? user.businessName!.substring(0, 1).toUpperCase()
                              : user.name.isNotEmpty
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
                            user.businessName ?? user.name,
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
                              color: (user.status ?? 'pending') == 'active'
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.1)
                                  : ((user.status ?? 'pending') == 'suspended'
                                        ? const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.1)
                                        : const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        (user.status ?? 'pending') == 'active'
                                        ? const Color(0xFF10B981)
                                        : ((user.status ?? 'pending') ==
                                                  'suspended'
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF59E0B)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (user.status ?? 'pending') == 'active'
                                      ? 'Active'
                                      : ((user.status ?? 'pending') ==
                                                'suspended'
                                            ? 'Suspended'
                                            : 'Pending'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        (user.status ?? 'pending') == 'active'
                                        ? const Color(0xFF10B981)
                                        : ((user.status ?? 'pending') ==
                                                  'suspended'
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF59E0B)),
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
                              : 'Recent',
                        ),
                      ]),
                    ),
                  ],
                ),
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
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Centers',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and monitor your global network of automotive experts.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 16),
          _buildExportButton(),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [titleWidget, _buildExportButton()],
    );
  }

  Widget _buildMainContent(bool isSmall) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'serviceCenter')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final users = docs
            .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        final tabCounts = [
          users.length,
          users.where((u) => u.status == 'active').length,
          users.where((u) => u.status == 'suspended').length,
          users.where((u) => u.status == 'pending').length,
          users.where((u) => u.status == 'rejected').length,
        ];

        List<User> filteredUsers = users;
        if (_selectedTabIndex == 1) {
          filteredUsers = users.where((u) => u.status == 'active').toList();
        } else if (_selectedTabIndex == 2) {
          filteredUsers = users.where((u) => u.status == 'suspended').toList();
        } else if (_selectedTabIndex == 3) {
          filteredUsers = users.where((u) => u.status == 'pending').toList();
        } else if (_selectedTabIndex == 4) {
          filteredUsers = users.where((u) => u.status == 'rejected').toList();
        }

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredUsers = filteredUsers.where((user) {
            final nameMatches = user.name.toLowerCase().contains(query);
            final emailMatches = user.email.toLowerCase().contains(query);
            final phoneMatches = (user.phoneNumber ?? '')
                .toLowerCase()
                .contains(query);
            final businessMatches = (user.businessName ?? '')
                .toLowerCase()
                .contains(query);
            return nameMatches ||
                emailMatches ||
                phoneMatches ||
                businessMatches;
          }).toList();
        }

        if (_selectedRegistration == 'Oldest') {
          filteredUsers = filteredUsers.reversed.toList();
        }

        return Column(
          children: [
            Builder(
              builder: (context) {
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

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1100) {
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
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, tableConstraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1000),
                          child: SizedBox(
                            width: tableConstraints.maxWidth > 1000
                                ? tableConstraints.maxWidth
                                : 1000,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'CENTER DETAILS',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'CONTACT INFORMATION',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'STATUS',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'BOOKINGS',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'RATING',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'ACTIONS',
                                            style: _headerStyle(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (filteredUsers.isEmpty)
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'No Centers Found',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final initials =
                                            user.businessName?.isNotEmpty ==
                                                true
                                            ? user.businessName!
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : user.name.isNotEmpty
                                            ? user.name
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : '?';
                                        return _buildTableRow(
                                          user.uid,
                                          initials,
                                          user.businessName ?? user.name,
                                          'Unknown Location', // Placeholder
                                          user.status ?? 'pending',
                                          '0', // Bookings placeholder
                                          '0.0', // Rating placeholder
                                          '0', // Reviews placeholder
                                          user,
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
              ),
            ),
          ],
        );
      },
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

  TextStyle _headerStyle() {
    return GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF64748B),
      letterSpacing: 1.1,
    );
  }

  Widget _buildTableRow(
    String uid,
    String initials,
    String name,
    String location,
    String status,
    String bookings,
    String rating,
    String reviews,
    User user,
  ) {
    Color statusBgColor;
    Color statusColor;
    String statusText;

    if (status == 'active') {
      statusText = 'Active';
      statusColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
    } else if (status == 'suspended') {
      statusText = 'Suspended';
      statusColor = const Color(0xFFEF4444);
      statusBgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
    } else if (status == 'rejected') {
      statusText = 'Rejected';
      statusColor = const Color(0xFF64748B);
      statusBgColor = const Color(0xFF64748B).withValues(alpha: 0.1);
    } else {
      statusText = 'Pending Approval';
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
    }

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
                      initials,
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
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                      user.phoneNumber?.isNotEmpty == true
                          ? user.phoneNumber!
                          : 'Not provided',
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookings,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'lifetime',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
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
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviews reviews)',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex:
                2, // slightly gave more flex to actions while maybe I should just use Wrap
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionIcon(
                  icon: Icons.visibility_outlined,
                  color: const Color(0xFF5D40D4),
                  tooltip: 'View Details',
                  onTap: () => _showServiceCenterDetailsDialog(user),
                ),
                if (status != 'active') ...[
                  _buildActionIcon(
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    tooltip: 'Approve',
                    onTap: () => _updateStatus(uid, 'active'),
                  ),
                ],
                if (status != 'suspended') ...[
                  _buildActionIcon(
                    icon: Icons.pause_circle_outline,
                    color: const Color(0xFFF59E0B),
                    tooltip: 'Suspend',
                    onTap: () => _updateStatus(uid, 'suspended'),
                  ),
                ],
                if (status != 'rejected') ...[
                  _buildActionIcon(
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFEF4444),
                    tooltip: 'Reject',
                    onTap: () => _updateStatus(uid, 'rejected'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String uid, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': newStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
