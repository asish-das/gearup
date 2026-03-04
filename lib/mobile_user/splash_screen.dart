import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:gearup/widgets/gear_up_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0x267311D4), Colors.transparent],
            center: Alignment(-0.6, -0.6),
            radius: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const GearUpLogo(size: 120),
            const SizedBox(height: 48),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'Gear'),
                  TextSpan(
                    text: 'Up',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elevate Your Performance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Column(
              children: [
                const Text(
                  'INITIALIZING',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(color: AppTheme.primary, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
