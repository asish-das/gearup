import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminManagementView extends StatelessWidget {
  const AdminManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final padding = isMobile ? 16.0 : 32.0;
        final availableWidth = constraints.maxWidth - (padding * 2);

        return Container(
          color: const Color(0xFFF6F6F8),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 32),
                _buildTitleSection(isMobile),
                const SizedBox(height: 24),
                _buildAccountDetailsSection(isMobile),
                const SizedBox(height: 24),
                _buildTableSection(isMobile, availableWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Management',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileActions(),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Admin Management',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        _buildProfileActions(),
      ],
    );
  }

  Widget _buildProfileActions() {
    return Row(
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
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'James Wilson',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'System Administrator',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(Icons.person, color: Color(0xFF64748B), size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(bool isMobile) {
    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Administrators',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage platform access and assign administrative roles.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );

    final actionButton = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5D40D4),
        gradient: const LinearGradient(
          colors: [Color(0xFF5D40D4), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D40D4).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Add New Admin',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          textContent,
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: actionButton),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [textContent, actionButton],
    );
  }

  Widget _buildAccountDetailsSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Details',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField('FULL NAME', 'John Doe'),
                const SizedBox(height: 16),
                _buildInputField('EMAIL ADDRESS', 'admin@gearup.com'),
                const SizedBox(height: 16),
                _buildInputField(
                  'TEMPORARY PASSWORD',
                  '••••••••',
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  'ROLE SELECTION',
                  'Select Role',
                  hasDropdown: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildInputField('FULL NAME', 'John Doe')),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildInputField('EMAIL ADDRESS', 'admin@gearup.com'),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildInputField(
                    'TEMPORARY PASSWORD',
                    '••••••••',
                    isPassword: true,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildInputField(
                    'ROLE SELECTION',
                    'Select Role',
                    hasDropdown: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableSection(bool isMobile, double availableWidth) {
    final double tableWidth = availableWidth < 900 ? 900 : availableWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  color: Color(0xFFF8FAFC),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('ADMIN USER', style: _headerStyle()),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('ROLE', style: _headerStyle()),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('LAST LOGIN', style: _headerStyle()),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('STATUS', style: _headerStyle()),
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
              _buildTableRow(
                'JD',
                'John Doe',
                'john.d@gearup.com',
                'Super Admin',
                Colors.purple,
                'Today, ${DateFormat('hh:mm a').format(DateTime.now())}',
                true,
              ),
              _buildTableRow(
                'SW',
                'Sarah Williams',
                'sarah.w@gearup.com',
                'Manager',
                Colors.blue,
                'Yesterday, ${DateFormat('hh:mm a').format(DateTime.now().subtract(const Duration(hours: 24)))}',
                true,
              ),
              _buildTableRow(
                'MB',
                'Mike Brown',
                'mike.b@gearup.com',
                'Support',
                Colors.grey,
                DateFormat(
                  'MMM dd, yyyy',
                ).format(DateTime.now().subtract(const Duration(days: 3))),
                false,
              ),
            ],
          ),
        ),
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

  Widget _buildInputField(
    String label,
    String placeholder, {
    bool isPassword = false,
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
              Expanded(
                child: Text(
                  placeholder,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8), // placeholder style
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildTableRow(
    String initials,
    String name,
    String email,
    String role,
    MaterialColor roleColor,
    String lastLogin,
    bool isActive,
  ) {
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: roleColor.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.manrope(
                        color: roleColor.shade700,
                        fontWeight: FontWeight.bold,
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: roleColor.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              lastLogin,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.grey,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 18,
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
