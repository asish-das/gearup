import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/system_settings.dart';

class SystemSettingsView extends StatefulWidget {
  const SystemSettingsView({super.key});

  @override
  State<SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends State<SystemSettingsView> {
  final _emailController = TextEditingController();
  final _timeoutController = TextEditingController();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  
  SystemSettings _settings = SystemSettings.initial();
  bool _isLoading = true;
  bool _isSaving = false;
  String _activeTab = 'Security';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _timeoutController.dispose();
    _nameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('admin_settings')
          .get();
      
      if (doc.exists) {
        setState(() {
          _settings = SystemSettings.fromMap(doc.data()!);
          _emailController.text = _settings.primaryAdminEmail;
          _timeoutController.text = _settings.sessionTimeout.toString();
          _nameController.text = _settings.adminName;
          _designationController.text = _settings.adminDesignation;
        });
      } else {
        // Initialize with default
        _emailController.text = _settings.primaryAdminEmail;
        _timeoutController.text = _settings.sessionTimeout.toString();
        _nameController.text = _settings.adminName;
        _designationController.text = _settings.adminDesignation;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      // Update from controllers
      final updatedSettings = SystemSettings(
        primaryAdminEmail: _emailController.text,
        twoFactorAuth: _settings.twoFactorAuth,
        sessionTimeout: int.tryParse(_timeoutController.text) ?? 30,
        rolePermissions: _settings.rolePermissions,
        emailAlerts: _settings.emailAlerts,
        pushNotifications: _settings.pushNotifications,
        weeklyReport: _settings.weeklyReport,
        darkMode: _settings.darkMode,
        accentColor: _settings.accentColor,
        adminName: _nameController.text,
        adminDesignation: _designationController.text,
      );

      await FirebaseFirestore.instance
          .collection('config')
          .doc('admin_settings')
          .set(updatedSettings.toMap());
      
      setState(() => _settings = updatedSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updatePermission(String module, String action, bool value) {
    setState(() {
      final perms = Map<String, PermissionSet>.from(_settings.rolePermissions);
      final current = perms[module] ?? PermissionSet(view: false, edit: false, delete: false);
      
      PermissionSet updated;
      if (action == 'view') {
        updated = PermissionSet(view: value, edit: current.edit, delete: current.delete);
      } else if (action == 'edit') {
        updated = PermissionSet(view: current.view, edit: value, delete: current.delete);
      } else {
        updated = PermissionSet(view: current.view, edit: current.edit, delete: value);
      }
      
      perms[module] = updated;
      _settings = SystemSettings(
        primaryAdminEmail: _settings.primaryAdminEmail,
        twoFactorAuth: _settings.twoFactorAuth,
        sessionTimeout: _settings.sessionTimeout,
        rolePermissions: perms,
        emailAlerts: _settings.emailAlerts,
        pushNotifications: _settings.pushNotifications,
        weeklyReport: _settings.weeklyReport,
        darkMode: _settings.darkMode,
        accentColor: _settings.accentColor,
        adminName: _settings.adminName,
        adminDesignation: _settings.adminDesignation,
      );
    });
  }

  void _updateToggle(String key, bool value) {
    setState(() {
      _settings = SystemSettings(
        primaryAdminEmail: _settings.primaryAdminEmail,
        twoFactorAuth: _settings.twoFactorAuth,
        sessionTimeout: _settings.sessionTimeout,
        rolePermissions: _settings.rolePermissions,
        emailAlerts: key == 'emailAlerts' ? value : _settings.emailAlerts,
        pushNotifications: key == 'pushNotifications' ? value : _settings.pushNotifications,
        weeklyReport: key == 'weeklyReport' ? value : _settings.weeklyReport,
        darkMode: _settings.darkMode,
        accentColor: _settings.accentColor,
        adminName: _settings.adminName,
        adminDesignation: _settings.adminDesignation,
      );
    });
  }

  void _updateAppearance(bool darkMode) {
    setState(() {
      _settings = SystemSettings(
        primaryAdminEmail: _settings.primaryAdminEmail,
        twoFactorAuth: _settings.twoFactorAuth,
        sessionTimeout: _settings.sessionTimeout,
        rolePermissions: _settings.rolePermissions,
        emailAlerts: _settings.emailAlerts,
        pushNotifications: _settings.pushNotifications,
        weeklyReport: _settings.weeklyReport,
        darkMode: darkMode,
        accentColor: _settings.accentColor,
        adminName: _settings.adminName,
        adminDesignation: _settings.adminDesignation,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Settings',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopActions(isMobile: true),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'System Settings',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    _buildTopActions(isMobile: false),
                  ],
                ),

              const SizedBox(height: 32),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab('Security'),
                    const SizedBox(width: 32),
                    _buildTab('Role Permissions'),
                    const SizedBox(width: 32),
                    _buildTab('Notification Toggles'),
                    const SizedBox(width: 32),
                    _buildTab('Appearance'),
                    const SizedBox(width: 32),
                    _buildTab('Profile'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content based on tab or layout
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_activeTab == 'Security' || (!isMobile && !isTablet))
                         _buildSecuritySettings(),
                      if (_activeTab == 'Role Permissions' || (!isMobile && !isTablet))
                         Padding(padding: const EdgeInsets.only(top: 24), child: _buildRolePermissions()),
                      if (_activeTab == 'Notification Toggles' || (!isMobile && !isTablet))
                         Padding(padding: const EdgeInsets.only(top: 24), child: _buildNotificationToggles()),
                      if (_activeTab == 'Appearance' || (!isMobile && !isTablet))
                         Padding(padding: const EdgeInsets.only(top: 24), child: _buildAppearanceConfig()),
                      if (_activeTab == 'Profile' || (!isMobile && !isTablet))
                         Padding(padding: const EdgeInsets.only(top: 24), child: _buildProfileSettings()),
                         
                      const SizedBox(height: 40),
                      // Universal save button at the bottom for better visibility
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: _isSaving ? null : _saveSettings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D40D4),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5D40D4).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Save All Settings',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopActions({required bool isMobile}) {
    final searchField = Container(
      height: 48,
      width: isMobile ? double.infinity : 250,
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
                hintText: 'Search settings...',
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

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isMobile ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE2E8F0),
          child: Icon(Icons.person, color: Color(0xFF64748B)),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: actionButtons),
        ],
      );
    } else {
      return Row(
        children: [searchField, const SizedBox(width: 16), actionButtons],
      );
    }
  }

  Widget _buildSecuritySettings() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Configuration',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'PRIMARY ADMIN EMAIL',
                  'admin@gearup.enterprise',
                  _emailController,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildTextField(
                  'SESSION TIMEOUT (MINUTES)',
                  '30',
                  _timeoutController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolePermissions() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Permissions',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: Text('MODULE', style: _headerStyle())),
                  Expanded(flex: 1, child: Center(child: Text('VIEW', style: _headerStyle()))),
                  Expanded(flex: 1, child: Center(child: Text('EDIT', style: _headerStyle()))),
                  Expanded(flex: 1, child: Center(child: Text('DELETE', style: _headerStyle()))),
                ],
              ),
              const SizedBox(height: 16),
              ..._settings.rolePermissions.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.key,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Checkbox(
                            value: entry.value.view,
                            onChanged: (v) => _updatePermission(entry.key, 'view', v ?? false),
                            activeColor: const Color(0xFF5D40D4),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Checkbox(
                            value: entry.value.edit,
                            onChanged: (v) => _updatePermission(entry.key, 'edit', v ?? false),
                            activeColor: const Color(0xFF5D40D4),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Checkbox(
                            value: entry.value.delete,
                            onChanged: (v) => _updatePermission(entry.key, 'delete', v ?? false),
                            activeColor: const Color(0xFF5D40D4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggles() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Toggles',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          _buildToggleRow('Email Alerts', 'Critical system updates', 'emailAlerts', _settings.emailAlerts),
          const SizedBox(height: 16),
          _buildToggleRow('Push Notifications', 'Desktop and mobile alerts', 'pushNotifications', _settings.pushNotifications),
          const SizedBox(height: 16),
          _buildToggleRow('Weekly Report', 'Summary via email', 'weeklyReport', _settings.weeklyReport),
        ],
      ),
    );
  }

  Widget _buildAppearanceConfig() {
    final colors = [
      const Color(0xFF5D40D4),
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dark Mode',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Switch(
                value: _settings.darkMode,
                onChanged: _updateAppearance,
                activeThumbColor: const Color(0xFF5D40D4),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'ACCENT COLOR',
            style: _headerStyle(),
          ),
          const SizedBox(height: 12),
          Row(
            children: colors.map((color) {
              final hex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
              bool isSelected = _settings.accentColor == hex;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _settings = SystemSettings(
                        primaryAdminEmail: _settings.primaryAdminEmail,
                        twoFactorAuth: _settings.twoFactorAuth,
                        sessionTimeout: _settings.sessionTimeout,
                        rolePermissions: _settings.rolePermissions,
                        emailAlerts: _settings.emailAlerts,
                        pushNotifications: _settings.pushNotifications,
                        weeklyReport: _settings.weeklyReport,
                        darkMode: _settings.darkMode,
                        accentColor: hex,
                        adminName: _settings.adminName,
                        adminDesignation: _settings.adminDesignation,
                      );
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSettings() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Profile',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.person, size: 50, color: Color(0xFF64748B)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5D40D4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('FULL NAME', 'System Administrator', _nameController),
          const SizedBox(height: 16),
          _buildTextField('DESIGNATION', 'Chief Technology Officer', _designationController),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    bool isActive = _activeTab == title;
    return InkWell(
      onTap: () => setState(() => _activeTab = title),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF5D40D4) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.manrope(
            color: isActive ? const Color(0xFF5D40D4) : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String placeholder, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: placeholder,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String title, String subtitle, String key, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
            Text(
              subtitle,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: (v) => _updateToggle(key, v),
          activeThumbColor: const Color(0xFF5D40D4),
        ),
      ],
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
}
