import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Select Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServiceTile(
            context,
            'Oil Change & Filter',
            'Full synthetic oil change and filter replacement',
            '\$85',
            Icons.water_drop,
          ),
          const SizedBox(height: 12),
          _buildServiceTile(
            context,
            'Comprehensive Diagnostics',
            'Complete system scan and engine diagnostics',
            '\$120',
            Icons.build,
          ),
          const SizedBox(height: 12),
          _buildServiceTile(
            context,
            'Brake Inspection & Repair',
            'Pad replacement and rotor resurfacing',
            '\$150',
            Icons.speed,
          ),
          const SizedBox(height: 12),
          _buildServiceTile(
            context,
            'Tire Rotation & Balance',
            'Extend tire life and improve ride quality',
            '\$60',
            Icons.tire_repair,
          ),
          const SizedBox(height: 12),
          _buildServiceTile(
            context,
            'Wash & Premium Detail',
            'Interior/exterior cleaning and waxing',
            '\$200',
            Icons.local_car_wash,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    String name,
    String desc,
    String price,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/booking',
          arguments: {'name': name, 'desc': desc, 'price': price},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
