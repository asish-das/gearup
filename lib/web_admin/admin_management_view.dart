import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_models;

class AdminManagementView extends StatefulWidget {
  const AdminManagementView({super.key});

  @override
  State<AdminManagementView> createState() => _AdminManagementViewState();
}

class _AdminManagementViewState extends State<AdminManagementView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  app_models.UserRole? _selectedRole;

  bool _isCreating = false;
  bool _obscurePassword = true;
  List<app_models.User> _admins = [];
  bool _isLoadingAdmins = true;

  app_models.User? get _currentAdmin {
    final curUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    try {
      return _admins.firstWhere((a) => a.uid == curUid);
    } catch (_) {
      return null;
    }
  }

  bool get _isSuperAdmin => _currentAdmin?.email == 'admin@gmail.com' || _currentAdmin?.role == app_models.UserRole.superAdmin;

  final List<app_models.UserRole> _adminRoles = [
    app_models.UserRole.superAdmin,
    app_models.UserRole.admin,
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fetchAdmins() {
    FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: ['admin', 'superAdmin'])
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _admins = snapshot.docs.map((d) {
          final data = d.data();
          data['uid'] = d.id;
          return app_models.User.fromMap(data);
        }).toList();
        _isLoadingAdmins = false;
      });
    });
  }

  Future<void> _createNewAdmin() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isCreating = true);

    try {
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final auth = firebase_auth.FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final newUser = app_models.User(
        uid: cred.user!.uid,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole!,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      await auth.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin created successfully!')));
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() => _selectedRole = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _updateStatus(app_models.User admin, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(admin.uid)
          .update({'status': newStatus});
      
      final message = newStatus == 'active' ? 'Account activated!' : 'Account updated to $newStatus';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  Future<void> _deleteAdmin(app_models.User admin) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin?'),
        content: Text('Are you sure you want to remove ${admin.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(admin.uid).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error deleting admin: $e')));
        }
      }
    }
  }

  Future<void> _editAdminRole(app_models.User admin) async {
    app_models.UserRole? newRole = admin.role;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Change Admin Role'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select a new role for ${admin.name}:'),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<app_models.UserRole>(
                        value: newRole,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF0F172A)),
                        items: _adminRoles.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(r.displayName, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF0F172A))),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() => newRole = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true && newRole != null && newRole != admin.role) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(admin.uid).update({'role': newRole!.name});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated successfully!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating role: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final padding = isMobile ? 16.0 : 40.0;
        final availableWidth = constraints.maxWidth - (padding * 2);

        return Container(
          color: const Color(0xFFF9FAFB),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: 0,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 8),
                _buildTitleSection(isMobile),
                if (_isSuperAdmin) ...[
                  const SizedBox(height: 24),
                  _buildAccountDetailsSection(constraints.maxWidth),
                ],
                const SizedBox(height: 32),
                _buildTableSection(isMobile, availableWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = Text(
      'Admin Management',
      style: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          _buildProfileActions(),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        title,
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
                color: Colors.black.withOpacity(0.02),
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
                color: Colors.black.withOpacity(0.02),
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
                    _currentAdmin?.name ?? 'System Admin',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _currentAdmin?.role.toString().split('.').last.toUpperCase() ?? 'ADMINISTRATIVE ROLE',
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



    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          textContent,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        textContent,
        // The submission button is now inside the Account Details card for better UX
      ],
    );
  }

  Widget _buildAccountDetailsSection(double screenWidth) {
    final bool isCompact = screenWidth < 1200;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Text(
              'Account Details',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: isCompact ? _buildCompactForm() : _buildWideForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildWideForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: _buildInputField('FULL NAME', 'Admin Name', controller: _nameController),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: _buildInputField('EMAIL ADDRESS', 'admin@gearup.com', controller: _emailController),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 3,
          child: _buildInputField('TEMPORARY PASSWORD', '••••••••', isPassword: true, controller: _passwordController),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: _buildRoleDropdown(),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildSubmitButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildInputField('FULL NAME', 'Admin Name', controller: _nameController)),
            const SizedBox(width: 20),
            Expanded(child: _buildInputField('EMAIL ADDRESS', 'admin@gearup.com', controller: _emailController)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _buildInputField('TEMPORARY PASSWORD', '••••••••', isPassword: true, controller: _passwordController)),
            const SizedBox(width: 20),
            Expanded(child: _buildRoleDropdown()),
            const SizedBox(width: 20),
            _buildSubmitButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    if (!_isSuperAdmin) return const SizedBox.shrink();
    
    return InkWell(
      onTap: _isCreating ? null : _createNewAdmin,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF5D40D4),
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF5D40D4), Color(0xFF7C3AED)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D40D4).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isCreating 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                'Create Account',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
        ),
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoadingAdmins ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())) : SingleChildScrollView(
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
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Text('ROLE', style: _headerStyle()),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Text('MEMBERSHIP DATE', style: _headerStyle()),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Text('STATUS', style: _headerStyle()),
                    ),
                    const SizedBox(width: 20),
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
              if (_admins.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("No admins found.")),
                ),
              ..._admins.map((admin) {
                // Determine colors based on role
                MaterialColor roleColor = Colors.purple;
                if (admin.role == app_models.UserRole.superAdmin) {
                  roleColor = Colors.purple;
                } else if (admin.role == app_models.UserRole.admin) {
                  roleColor = Colors.blue;
                } else {
                  roleColor = Colors.grey;
                }

                String initials = admin.name.isNotEmpty 
                   ? admin.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                   : 'AD';
                   
                String dateString = 'Unknown';
                if (admin.createdAt != null) {
                  try {
                     final d = DateTime.parse(admin.createdAt!);
                     dateString = DateFormat('MMM dd, yyyy').format(d);
                  } catch(e) {}
                }

                return _buildTableRow(
                  admin,
                  initials,
                  admin.name.isEmpty ? 'Unknown' : admin.name,
                  admin.email,
                  admin.role.displayName,
                  roleColor,
                  dateString,
                  admin.status == 'active',
                );
              }),
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
      color: const Color(0xFF475569), // Darker for high contrast
      letterSpacing: 1.1,
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROLE SELECTION',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<app_models.UserRole>(
              value: _selectedRole,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF0F172A)),
              hint: Text(
                'Select Role',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              icon: const Icon(Icons.expand_more, color: Color(0xFF64748B), size: 20),
              items: _adminRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.displayName, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF0F172A))),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedRole = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String placeholder, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              suffixIcon: isPassword ? IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
              ) : null,
              hintStyle: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF5D40D4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(
    app_models.User admin,
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(width: 20),
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
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lastLogin,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isSuperAdmin && admin.uid != _currentAdmin?.uid && admin.role != app_models.UserRole.superAdmin && admin.email != 'admin@gmail.com') ...[
                  // If Pending, show Approve and Delete (Reject)
                  if (admin.status == 'pending') ...[
                    _buildActionButton(
                      onTap: () => _updateStatus(admin, 'active'),
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF10B981), // Green
                      bgColor: const Color(0xFFECFDF5),
                      tooltip: 'Approve',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      onTap: () {
                        // Reject is essentially deleting the pending account
                        _deleteAdmin(admin);
                      },
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFEF4444), // Red
                      bgColor: const Color(0xFFFEF2F2),
                      tooltip: 'Reject',
                    ),
                  ] 
                  // If Active, show Suspend, Edit, and Delete
                  else if (admin.status == 'active') ...[
                    _buildActionButton(
                      onTap: () => _updateStatus(admin, 'suspended'),
                      icon: Icons.block,
                      color: const Color(0xFFF59E0B), // Orange/Amber
                      bgColor: const Color(0xFFFFFBEB),
                      tooltip: 'Suspend',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      onTap: () => _editAdminRole(admin),
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF3B82F6), // Blue
                      bgColor: const Color(0xFFEFF6FF),
                      tooltip: 'Edit Role',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      onTap: () => _deleteAdmin(admin),
                      icon: Icons.delete_outline,
                      color: const Color(0xFFEF4444), // Red
                      bgColor: const Color(0xFFFEF2F2),
                      tooltip: 'Delete',
                    ),
                  ]
                  // If Suspended, show Activate and Delete
                  else ...[
                    _buildActionButton(
                      onTap: () => _updateStatus(admin, 'active'),
                      icon: Icons.check_circle,
                      color: const Color(0xFF10B981), // Green
                      bgColor: const Color(0xFFECFDF5),
                      tooltip: 'Activate',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      onTap: () => _deleteAdmin(admin),
                      icon: Icons.delete_outline,
                      color: const Color(0xFFEF4444), // Red
                      bgColor: const Color(0xFFFEF2F2),
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }
}
