import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemSettingsView extends StatelessWidget {
  const SystemSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

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
                    _buildTab('Security', true),
                    const SizedBox(width: 32),
                    _buildTab('Role Permissions', false),
                    const SizedBox(width: 32),
                    _buildTab('Notification Toggles', false),
                    const SizedBox(width: 32),
                    _buildTab('Appearance', false),
                    const SizedBox(width: 32),
                    _buildTab('Profile', false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: isMobile || isTablet
                      ? Column(
                          children: [
                            _buildSecuritySettings(),
                            const SizedBox(height: 24),
                            _buildRolePermissions(),
                            const SizedBox(height: 24),
                            _buildNotificationToggles(),
                            const SizedBox(height: 24),
                            _buildAppearanceConfig(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildSecuritySettings(),
                                  const SizedBox(height: 24),
                                  _buildRolePermissions(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildNotificationToggles(),
                                  const SizedBox(height: 24),
                                  _buildAppearanceConfig(),
                                ],
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
      mainAxisAlignment: isMobile
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                return Column(
                  children: [
                    _buildInputField(
                      'PRIMARY ADMIN EMAIL',
                      'admin@gearup.enterprise',
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'TWO-FACTOR AUTHENTICATION',
                      'Enabled (SMS + App)',
                      hasDropdown: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField('SESSION TIMEOUT (MINUTES)', '30'),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          'PRIMARY ADMIN EMAIL',
                          'admin@gearup.enterprise',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildInputField(
                          'TWO-FACTOR AUTHENTICATION',
                          'Enabled (SMS + App)',
                          hasDropdown: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          'SESSION TIMEOUT (MINUTES)',
                          '30',
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF5D40D4),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D40D4).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Save Security Changes',
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
    );
  }

  Widget _buildRolePermissions() {
    return Container(
      width: double.infinity,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 500),
              child: IntrinsicWidth(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'MODULE',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'VIEW',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'EDIT',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'DELETE',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionRow('User Management', true, true, false),
                    const SizedBox(height: 16),
                    _buildPermissionRow(
                      'Financial Reports',
                      true,
                      false,
                      false,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionRow(
                      'Service Log Control',
                      true,
                      true,
                      true,
                    ),
                  ],
                ),
              ),
            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          _buildToggleRow('Email Alerts', 'Critical system updates', true),
          const SizedBox(height: 16),
          _buildToggleRow(
            'Push Notifications',
            'Desktop and mobile alerts',
            false,
          ),
          const SizedBox(height: 16),
          _buildToggleRow('Weekly Report', 'Summary via email', true),
        ],
      ),
    );
  }

  Widget _buildAppearanceConfig() {
    return Container(
      width: double.infinity,
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
                value: false,
                onChanged: (v) {},
                activeThumbColor: const Color(0xFF5D40D4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ACCENT COLOR',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildColorCircle(const Color(0xFF5D40D4), selected: true),
                const SizedBox(width: 8),
                _buildColorCircle(Colors.blue),
                const SizedBox(width: 8),
                _buildColorCircle(Colors.green),
                const SizedBox(width: 8),
                _buildColorCircle(Colors.orange),
                const SizedBox(width: 8),
                _buildColorCircle(Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Container(
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
    );
  }

  Widget _buildInputField(
    String label,
    String value, {
    bool hasDropdown = false,
  }) {
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
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (hasDropdown)
                const Icon(
                  Icons.expand_more,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool isActive) {
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
          value: isActive,
          onChanged: (v) {},
          activeThumbColor: const Color(0xFF5D40D4),
        ),
      ],
    );
  }

  Widget _buildPermissionRow(String title, bool v1, bool v2, bool v3) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Checkbox(
              value: v1,
              onChanged: (v) {},
              activeColor: const Color(0xFF5D40D4),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Checkbox(
              value: v2,
              onChanged: (v) {},
              activeColor: const Color(0xFF5D40D4),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Checkbox(
              value: v3,
              onChanged: (v) {},
              activeColor: const Color(0xFF5D40D4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color c, {bool selected = false}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: selected
            ? [BoxShadow(color: c, blurRadius: 4, spreadRadius: 2)]
            : null,
      ),
    );
  }
}
