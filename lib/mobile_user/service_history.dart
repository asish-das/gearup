import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ServiceHistoryScreen extends StatelessWidget {
  const ServiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundDark,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hidden when in Bottom Navigation
        title: const Text(
          'Service History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF4d3267))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                    child: const Text(
                      'Past Services',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.transparent, width: 2),
                      ),
                    ),
                    child: const Text(
                      'Upcoming',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildServiceEntry(
              title: 'Full Engine Tune-up',
              date: DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.now().subtract(const Duration(days: 30))),
              location: 'GearUp Central Hub',
              price: '\$245.00',
              icon: Icons.settings_suggest,
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuB0q6iJWXWLUdi_sYx8c9Ia0kVnyib6brZU7j5oIOs-c9dEfdkH7afjQMu2L_bDYXHmWaPR421qqUtCzrXM2O3tnFShm0ZipYddhGUUlsTXL1GINM7FEnXugETh1VG58ALiRuEHwp29H-jaie86V6iAE_bIgAXJ8ZSVF_dZ2G31vGO3zkUzdLv7mzTAozYlVe8HfgUHqu2LLu1FSqsiUf8FxYC0-wiURQ0URJHYqC6HpvAc7etn7o4IcrGMbK8di73e891MHjcd4Oc',
              isFirst: true,
            ),
            _buildServiceEntry(
              title: 'Brake Pad Replacement',
              date: DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.now().subtract(const Duration(days: 65))),
              location: 'East Side Garage',
              price: '\$189.50',
              icon: Icons.tire_repair,
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDXlk0K2C5JL3LQsHQBNG8F3bn3GlqlBdgrTiL3nKNcicFr4kV4o2HBGkKi9ZNDoVUKuALqD95rGRslgee-Ap7EsWqkc_8WLA4E-ZCLZI4pVrDoZ_cwa8dVr7gJy0_AkNOVH7VOp6Uhk0dfTGPAmtgOfFXPdg1QMzbDEH_ABILl14um1pYHTIA_5FBy6SPPZ544NlwUTwRv0puqN15Ecf6xUVIjlnlb7TgRioP94ehI1LyjoJmZ-3yCaAqR11XX_et7bamDhkl5rNw',
            ),
            _buildServiceEntry(
              title: 'Oil & Filter Change',
              date: DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.now().subtract(const Duration(days: 120))),
              location: 'GearUp Express',
              price: '\$85.00',
              icon: Icons.oil_barrel,
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCUnratjf45PkYrKyseW73FGfvsiTPUkoUbrPmgRQYYynpIJXOMuh6bB3ztsjl2zvEtTtaWsKfKTrMP6FPpyyqKh1dhjmiFAiNEM9cuclkWR-Fzss5xsHcfgFEveree3YaMxYLqBvE8TZDWHL7ALCCFdl97DB_B_39SPCs6fV9o2XTIV4odI0EsC9gSIjsXE5azFIfHq8qqmZrTUPosKyV0c7g4oT_RZBvKjDwZYmjWqeT4rKF1M0L7Ueh7tJ4y64oxJIYGtuRaBwo',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceEntry({
    required String title,
    required String date,
    required String location,
    required String price,
    required IconData icon,
    required String imageUrl,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: 0,
                    child: Container(width: 2, color: const Color(0xFF4d3267)),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.backgroundDark,
                      width: 4,
                    ),
                  ),
                  child: Icon(icon, color: AppTheme.accent, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date • $location',
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 12),

                  // Service Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF261933),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4d3267)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Image(
                          image: CachedNetworkImageProvider(imageUrl),
                          width: double.infinity,
                          height: 128,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Paid',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.receipt_long,
                                  color: AppTheme.accent,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Invoice View',
                                  style: TextStyle(color: AppTheme.accent),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary.withValues(
                                    alpha: 0.2,
                                  ), // Use withValues if flutter version allows, string building takes withOpacity here implicitly
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
