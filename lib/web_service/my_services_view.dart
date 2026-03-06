import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyServicesView extends StatefulWidget {
  const MyServicesView({super.key});

  @override
  State<MyServicesView> createState() => _MyServicesViewState();
}

class _MyServicesViewState extends State<MyServicesView> {
  int _currentTab = 0; // 0: Active, 1: Slot Management, 2: Archived

  bool _isLoading = true;
  String? _error;

  double _dailyLimit = 12.0;
  bool _autoAccept = true;
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _services = [];

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Performance stats
  double _todayRevenue = 0.0;
  int _bookedSlotsCount = 0;
  double _revenueTrend = 0.0; // Simulated trend or calculated from yesterday

  @override
  void initState() {
    super.initState();
    _fetchRealtimeData();
  }

  void _fetchRealtimeData() {
    if (uid.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
      }
      return;
    }

    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((
      docSnapshot,
    ) {
      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final slotConfig = data['slotConfig'] as Map<String, dynamic>? ?? {};

        final dailyLimit =
            (slotConfig['dailyLimit'] as num?)?.toDouble() ?? 12.0;
        final autoAccept = slotConfig['autoAccept'] as bool? ?? true;

        final List<dynamic> slotsList =
            slotConfig['slots'] ??
            [
              {'time': '08:00 AM', 'status': 0},
              {'time': '09:00 AM', 'status': 0},
              {'time': '10:00 AM', 'status': 0},
              {'time': '11:00 AM', 'status': 0},
              {'time': '12:00 PM', 'status': 0},
              {'time': '01:00 PM', 'status': 0},
              {'time': '02:00 PM', 'status': 0},
              {'time': '03:00 PM', 'status': 0},
              {'time': '04:00 PM', 'status': 0},
              {'time': '05:00 PM', 'status': 0},
            ];

        final slots = slotsList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        setState(() {
          _dailyLimit = dailyLimit;
          _autoAccept = autoAccept;
          _slots = slots;
        });
      }
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('services')
        .snapshots()
        .listen((querySnapshot) {
          if (mounted) {
            final services = querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

            setState(() {
              _services = services;
              _isLoading = false;
            });
          }
        });

    // Listen to bookings for today's performance
    FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceCenterId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            double revenue = 0;
            int bookedCount = 0;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final appointmentTimestamp =
                  data['appointmentDate'] as Timestamp?;
              if (appointmentTimestamp == null) continue;

              final appointmentDate = appointmentTimestamp.toDate();
              final apptDay = DateTime(
                appointmentDate.year,
                appointmentDate.month,
                appointmentDate.day,
              );

              if (apptDay == today) {
                revenue += (data['amount'] ?? 0.0).toDouble();
                bookedCount++;
              }
            }

            setState(() {
              _todayRevenue = revenue;
              _bookedSlotsCount = bookedCount;
              _revenueTrend = revenue > 0 ? 12.5 : 0.0;
            });
          }
        });
  }

  void _showAddEditServiceDialog([Map<String, dynamic>? service]) {
    final bool isEdit = service != null;
    final titleController = TextEditingController(
      text: isEdit ? service['title'] : '',
    );
    final descController = TextEditingController(
      text: isEdit ? service['desc'] : '',
    );
    final priceController = TextEditingController(
      text: isEdit ? service['price'] : '',
    );
    final timeController = TextEditingController(
      text: isEdit ? service['time'] : '',
    );
    bool isPopular = isEdit ? (service['isPopular'] ?? false) : false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? 'Edit Service' : 'Add New Service',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Service Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'Price (e.g., \$50.00)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: timeController,
                            decoration: InputDecoration(
                              labelText: 'Duration (e.g., 1 hr)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Mark as Popular'),
                      value: isPopular,
                      onChanged: (val) {
                        setDialogState(() {
                          isPopular = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFF5D40D4),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D40D4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (uid.isEmpty) return;

                    final serviceData = {
                      'title': titleController.text.isNotEmpty
                          ? titleController.text
                          : 'New Service',
                      'desc': descController.text.isNotEmpty
                          ? descController.text
                          : 'Description',
                      'price': priceController.text.isNotEmpty
                          ? priceController.text
                          : '\$0.00',
                      'time': timeController.text.isNotEmpty
                          ? timeController.text
                          : '0 min',
                      'isPopular': isPopular,
                    };

                    if (isEdit) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('services')
                          .doc(service['id'])
                          .update(serviceData);
                    } else {
                      serviceData['isActive'] = true;
                      serviceData['isArchived'] = false;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('services')
                          .add(serviceData);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    isEdit ? 'Save Changes' : 'Add Service',
                    style: GoogleFonts.manrope(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadDemoServices() async {
    if (uid.isEmpty) return;

    setState(() => _isLoading = true);

    final demoServices = [
      {
        'title': 'General Oil Change',
        'desc': 'Full synthetic oil change including filter replacement.',
        'price': '\$49.99',
        'time': '30 min',
        'isPopular': true,
        'isActive': true,
        'isArchived': false,
      },
      {
        'title': 'Brake Pad Replacement',
        'desc':
            'High quality ceramic brake pads installation for front or rear wheels.',
        'price': '\$129.99',
        'time': '1.5 hr',
        'isPopular': false,
        'isActive': true,
        'isArchived': false,
      },
      {
        'title': 'Full Detailing',
        'desc': 'Interior and exterior detailing with waxing and tire shine.',
        'price': '\$99.00',
        'time': '2 hr',
        'isPopular': true,
        'isActive': true,
        'isArchived': false,
      },
    ];

    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('services');

      for (var service in demoServices) {
        batch.set(collection.doc(), service);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error adding demo services: \$e');
    }
  }

  Future<void> _toggleServiceStatus(
    Map<String, dynamic> service,
    bool isActive,
  ) async {
    if (uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('services')
        .doc(service['id'])
        .update({'isActive': isActive});
  }

  Future<void> _toggleArchiveStatus(Map<String, dynamic> service) async {
    if (uid.isEmpty) return;
    final bool isArchived = !(service['isArchived'] as bool? ?? false);
    final updates = <String, dynamic>{'isArchived': isArchived};
    if (isArchived) {
      updates['isActive'] = false;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('services')
        .doc(service['id'])
        .update(updates);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final isMobile = constraints.maxWidth < 600;

        return Container(
          color: const Color(0xFFF6F6F8),
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile, isDesktop),
              const SizedBox(height: 32),
              _buildTabs(isMobile),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 32),
              Expanded(child: _buildContent(isDesktop)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile, bool isDesktop) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Management',
          style: GoogleFonts.manrope(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          'Configure your offerings and availability slots.',
          style: GoogleFonts.manrope(
            fontSize: isMobile ? 14 : 16,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );

    final actionBtn = InkWell(
      onTap: () => _showAddEditServiceDialog(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF5D40D4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            if (!isMobile) const SizedBox(width: 8),
            if (!isMobile)
              Text(
                'Add New Service',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: titleWidget),
          const SizedBox(width: 16),
          actionBtn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [titleWidget, actionBtn],
    );
  }

  Widget _buildTabs(bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabItem('ACTIVE SERVICES', 0),
          SizedBox(width: isMobile ? 16 : 32),
          _buildTabItem('SLOT MANAGEMENT', 1),
          SizedBox(width: isMobile ? 16 : 32),
          _buildTabItem('ARCHIVED', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? const Color(0xFF5D40D4)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          if (isActive)
            Container(height: 2, width: 60, color: const Color(0xFF5D40D4))
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5D40D4)),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: GoogleFonts.manrope(color: Colors.red)),
      );
    }

    if (_currentTab == 1) {
      return _buildSlotManagement(isDesktop);
    }

    final isArchivedTab = _currentTab == 2;
    final displayList = _services
        .where((s) => s['isArchived'] == isArchivedTab)
        .toList();

    Widget listView = ListView.builder(
      itemCount: displayList.isEmpty ? 1 : displayList.length,
      itemBuilder: (context, index) {
        if (displayList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArchivedTab
                        ? 'No archived services'
                        : 'No active services.',
                    style: GoogleFonts.manrope(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  if (!isArchivedTab) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadDemoServices,
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text(
                        'Load Demo Services',
                        style: GoogleFonts.manrope(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D40D4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return _buildServiceCard(displayList[index], isDesktop);
      },
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: listView),
          const SizedBox(width: 32),
          Expanded(flex: 2, child: _buildDesktopSidebarItems()),
        ],
      );
    }

    return listView;
  }

  Widget _buildDesktopSidebarItems() {
    // Performance and selection hints on desktop view
    return Column(
      children: [
        _buildLivePerformanceCard(),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note, color: Color(0xFFCBD5E1), size: 32),
              const SizedBox(height: 16),
              Text(
                'Select a service to edit details and pricing or click the edit icon on any active service.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotManagement(bool isDesktop) {
    final slotContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity Control',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Icon(Icons.event_available, color: Color(0xFF5D40D4)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Manage how many vehicles you can handle per day across all services.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Vehicle Limit',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_dailyLimit.toInt()} Cars',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D40D4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF5D40D4),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    trackHeight: 6,
                    thumbColor: const Color(0xFF5D40D4),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayColor: const Color(
                      0xFF5D40D4,
                    ).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _dailyLimit,
                    min: 0,
                    max: 50,
                    divisions: 50,
                    onChanged: (v) {
                      setState(() {
                        _dailyLimit = v;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Slots Availability',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Available',
                          style: GoogleFonts.manrope(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Booked',
                          style: GoogleFonts.manrope(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Blocked',
                          style: GoogleFonts.manrope(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_slots.length, (index) {
                    final slot = _slots[index];
                    Color bgColor;
                    Color textColor;
                    if (slot['status'] == 0) {
                      // Available
                      bgColor = const Color(0xFFEEF2FF);
                      textColor = const Color(0xFF5D40D4);
                    } else if (slot['status'] == 1) {
                      // Booked
                      bgColor = const Color(0xFFFEE2E2);
                      textColor = const Color(0xFFDC2626);
                    } else {
                      // Blocked
                      bgColor = const Color(0xFFF1F5F9);
                      textColor = const Color(0xFF64748B);
                    }

                    return PopupMenuButton<int>(
                      tooltip: 'Change slot status',
                      onSelected: (int value) {
                        setState(() {
                          _slots[index]['status'] = value;
                        });
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<int>>[
                            PopupMenuItem<int>(
                              value: 0,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Available',
                                    style: GoogleFonts.manrope(),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 1,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_busy,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Booked', style: GoogleFonts.manrope()),
                                ],
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 2,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.block,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Blocked', style: GoogleFonts.manrope()),
                                ],
                              ),
                            ),
                          ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: slot['status'] == 0
                                ? const Color(0xFFC7D2FE)
                                : slot['status'] == 1
                                ? const Color(0xFFFECACA)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          slot['time'],
                          style: GoogleFonts.manrope(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Auto-accept Appointments',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Switch(
                      value: _autoAccept,
                      onChanged: (v) {
                        setState(() {
                          _autoAccept = v;
                        });
                      },
                      activeThumbColor: const Color(0xFF5D40D4),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (uid.isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                            'slotConfig': {
                              'dailyLimit': _dailyLimit,
                              'autoAccept': _autoAccept,
                              'slots': _slots,
                            },
                          }, SetOptions(merge: true));

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Slot preferences saved.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D40D4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Save Slot Configurations',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: slotContent),
          const SizedBox(width: 32),
          Expanded(flex: 2, child: _buildLivePerformanceCard()),
        ],
      );
    }
    return slotContent;
  }

  Widget _buildLivePerformanceCard() {
    final occupancy = _dailyLimit > 0 ? (_bookedSlotsCount / _dailyLimit) : 0.0;
    final occupancyPercent = (occupancy * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE PERFORMANCE',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D40D4),
                ),
              ),
              if (_bookedSlotsCount > 0)
                const Icon(Icons.sensors, color: Color(0xFF10B981), size: 14),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${_todayRevenue.toStringAsFixed(0)}',
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projected Revenue (Today)',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (_revenueTrend != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+${_revenueTrend.toStringAsFixed(1)}%',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: occupancy.clamp(0.0, 1.0),
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D40D4)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(
            '$occupancyPercent% of daily slots booked',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isDesktop) {
    bool isActive = service['isActive'] ?? false;
    bool isPopular = service['isPopular'] ?? false;
    bool isArchived = service['isArchived'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isArchived ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isArchived
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_repair_service,
              color: isArchived ? Colors.grey : const Color(0xFF5D40D4),
            ),
          ),
          SizedBox(width: isDesktop ? 24 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service['title'],
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isArchived
                              ? Colors.grey
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isPopular && !isArchived) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'POPULAR',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service['desc'],
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          service['price'],
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isArchived
                                ? Colors.grey
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          service['time'],
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isArchived
                                ? Colors.grey
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isDesktop) const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isArchived)
                Switch(
                  value: isActive,
                  onChanged: (v) => _toggleServiceStatus(service, v),
                  activeThumbColor: const Color(0xFF5D40D4),
                )
              else
                IconButton(
                  icon: const Icon(Icons.unarchive, color: Color(0xFF5D40D4)),
                  tooltip: 'Unarchive Service',
                  onPressed: () => _toggleArchiveStatus(service),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isArchived)
                    IconButton(
                      icon: const Icon(Icons.archive, color: Colors.grey),
                      tooltip: 'Archive Service',
                      onPressed: () => _toggleArchiveStatus(service),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    tooltip: 'Edit Service',
                    onPressed: () => _showAddEditServiceDialog(service),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
