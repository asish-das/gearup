import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:gearup/models/user.dart';
import '../services/auth_service.dart';

class WebRegistrationScreen extends StatefulWidget {
  const WebRegistrationScreen({super.key});

  @override
  State<WebRegistrationScreen> createState() => _WebRegistrationScreenState();
}

class _WebRegistrationScreenState extends State<WebRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.serviceCenter;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color _primaryColor = const Color(0xFF5D40D4);
  final Color _bgLight = const Color(0xFFF6F6F8);
  final Color _bgDark = const Color(0xFF15131F);

  @override
  void dispose() {
    _fullNameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Use AuthService to register
      await AuthService.signUp(
        email: email,
        password: password,
        name: _fullNameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim(),
        businessName: _businessNameController.text.trim(),
      );

      if (!mounted) return;
      // All enterprise roles (Admin, Service Center, etc.) start as pending and require approval.
      // Log them out immediately after registration and show the pending message.
      await auth.FirebaseAuth.instance.signOut();
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Registration Successful'),
          content: Text(
            'Your ${_selectedRole == UserRole.admin ? 'Admin' : 'Service Center'} account has been successfully created. '
            'However, it is currently waiting for Super Admin approval.\n\n'
            'You will receive an update once your account is activated.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      // Go back to the login screen
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? _bgDark : _bgLight;
    final Color cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color textMuted = isDark ? Colors.white54 : Colors.black54;
    final Color borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    const String roleName = 'Enterprise';

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Container(
            height: 64,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch, color: _primaryColor, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'GearUp',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Registration Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$roleName Registration',
                                style: GoogleFonts.manrope(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join GearUp to accelerate your enterprise growth and streamline operations.',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Form fields grid
                              const SizedBox(height: 32),
                              Text(
                                'Account Type',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole =
                                                UserRole.serviceCenter;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                _selectedRole ==
                                                    UserRole.serviceCenter
                                                ? _primaryColor
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Service Center',
                                              style: GoogleFonts.manrope(
                                                color:
                                                    _selectedRole ==
                                                        UserRole.serviceCenter
                                                    ? Colors.white
                                                    : textColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = UserRole.admin;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                _selectedRole == UserRole.admin
                                                ? _primaryColor
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Admin',
                                              style: GoogleFonts.manrope(
                                                color:
                                                    _selectedRole ==
                                                        UserRole.admin
                                                    ? Colors.white
                                                    : textColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final double width = constraints.maxWidth;
                                  final bool isMobile = width < 500;

                                  Widget buildField(
                                    String label,
                                    IconData icon,
                                    String hint,
                                    TextEditingController controller, {
                                    bool isPassword = false,
                                    bool isEmail = false,
                                    bool isPhone = false,
                                  }) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: controller,
                                          obscureText:
                                              isPassword &&
                                              (label.contains('Confirm')
                                                  ? _obscureConfirmPassword
                                                  : _obscurePassword),
                                          keyboardType: isEmail
                                              ? TextInputType.emailAddress
                                              : (isPhone
                                                    ? TextInputType.phone
                                                    : TextInputType.text),
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            hintText: hint,
                                            hintStyle: TextStyle(
                                              color: textMuted,
                                            ),
                                            prefixIcon: Icon(
                                              icon,
                                              color: textMuted,
                                            ),
                                            suffixIcon: isPassword
                                                ? IconButton(
                                                    icon: Icon(
                                                      (label.contains('Confirm')
                                                              ? _obscureConfirmPassword
                                                              : _obscurePassword)
                                                          ? Icons
                                                                .visibility_outlined
                                                          : Icons
                                                                .visibility_off_outlined,
                                                      color: textMuted,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        if (label.contains(
                                                          'Confirm',
                                                        )) {
                                                          _obscureConfirmPassword =
                                                              !_obscureConfirmPassword;
                                                        } else {
                                                          _obscurePassword =
                                                              !_obscurePassword;
                                                        }
                                                      });
                                                    },
                                                  )
                                                : null,
                                            filled: true,
                                            fillColor: isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFF8FAFC),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your $label';
                                            }
                                            if (isPassword &&
                                                value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      Flex(
                                        direction: isMobile
                                            ? Axis.vertical
                                            : Axis.horizontal,
                                        children: [
                                          Expanded(
                                            flex: isMobile ? 0 : 1,
                                            child: buildField(
                                              'Full Name',
                                              Icons.person_outline,
                                              'John Doe',
                                              _fullNameController,
                                            ),
                                          ),
                                          if (!isMobile)
                                            const SizedBox(width: 24),
                                          if (isMobile)
                                            const SizedBox(height: 24),
                                          Expanded(
                                            flex: isMobile ? 0 : 1,
                                            child: buildField(
                                              'Business Name',
                                              Icons.domain,
                                              'Acme Corp',
                                              _businessNameController,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Flex(
                                        direction: isMobile
                                            ? Axis.vertical
                                            : Axis.horizontal,
                                        children: [
                                          Expanded(
                                            flex: isMobile ? 0 : 1,
                                            child: buildField(
                                              'Work Email',
                                              Icons.mail_outline,
                                              'john@company.com',
                                              _emailController,
                                              isEmail: true,
                                            ),
                                          ),
                                          if (!isMobile)
                                            const SizedBox(width: 24),
                                          if (isMobile)
                                            const SizedBox(height: 24),
                                          Expanded(
                                            flex: isMobile ? 0 : 1,
                                            child: buildField(
                                              'Phone Number',
                                              Icons.phone_outlined,
                                              '+1 (555) 000-0000',
                                              _phoneController,
                                              isPhone: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Flex(
                                        direction: isMobile
                                            ? Axis.vertical
                                            : Axis.horizontal,
                                        children: [
                                          Expanded(
                                            flex: isMobile ? 0 : 1,
                                            child: buildField(
                                              'Password',
                                              Icons.lock_outline,
                                              '••••••••',
                                              _passwordController,
                                              isPassword: true,
                                            ),
                                          ),
                                          if (!isMobile)
                                            const SizedBox(width: 24),
                                          if (isMobile)
                                            const SizedBox(height: 24),
                                          Expanded(
                                            flex: isMobile ? 0 : 1,
                                            child: buildField(
                                              'Confirm Password',
                                              Icons.lock_reset,
                                              '••••••••',
                                              _confirmPasswordController,
                                              isPassword: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 32),

                              // Create Account Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: _primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Create Account',
                                              style: GoogleFonts.manrope(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: borderColor)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'SECURE REGISTRATION',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: borderColor)),
                                ],
                              ),

                              const SizedBox(height: 24),

                              Center(
                                child: Text.rich(
                                  TextSpan(
                                    text:
                                        'By clicking "Create Account", you agree to GearUp\'s ',
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: _primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: _primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer of the card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 48,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                              : const Color(0xFFF8FAFC),
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: textMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ISO 27001 Certified',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: textMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '256-bit Encryption',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
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
              ),
            ),
          ),

          // Bottom Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              '© ${DateTime.now().year} GearUp Enterprise Solutions. All rights reserved.',
              style: GoogleFonts.manrope(fontSize: 14, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
