import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyServicesView extends StatefulWidget {
  const MyServicesView({super.key});

  @override
  State<MyServicesView> createState() => _MyServicesViewState();
}

class _MyServicesViewState extends State<MyServicesView> {
  int _currentTab = 0; // 0: Active, 1: Slot Management, 2: Archived

  // Mock State for Slot Management
  double _dailyLimit = 12.0;
  bool _autoAccept = true;

  // 0: Available, 1: Booked, 2: Blocked/Unavailable
  final List<Map<String, dynamic>> _slots = [
    {'time': '08:00 AM', 'status': 0},
    {'time': '09:00 AM', 'status': 1},
    {'time': '10:00 AM', 'status': 0},
    {'time': '11:00 AM', 'status': 0},
    {'time': '12:00 PM', 'status': 1},
    {'time': '01:00 PM', 'status': 2},
    {'time': '02:00 PM', 'status': 0},
    {'time': '03:00 PM', 'status': 0},
    {'time': '04:00 PM', 'status': 1},
    {'time': '05:00 PM', 'status': 0},
  ];

  // Mock Data for Services
  final List<Map<String, dynamic>> _services = [
    {
      'id': '1',
      'title': 'Brake Pad Replacement',
      'desc': 'Premium ceramic brake pads installation for passenger vehicles.',
      'price': '\$80.00',
      'time': '1.5 hrs',
      'icon': Icons.car_repair,
      'isPopular': true,
      'isActive': true,
      'isArchived': false,
    },
    {
      'id': '2',
      'title': 'Full Synthetic Oil Change',
      'desc':
          'Includes filter replacement and 5-quart high-grade synthetic oil.',
      'price': '\$65.00',
      'time': '45 mins',
      'icon': Icons.oil_barrel,
      'isPopular': false,
      'isActive': true,
      'isArchived': false,
    },
    {
      'id': '3',
      'title': 'AC System Recharge',
      'desc': 'Coolant refill and leak inspection for R134a systems.',
      'price': '\$120.00',
      'time': '1.0 hr',
      'icon': Icons.ac_unit,
      'isPopular': false,
      'isActive': false,
      'isArchived': false,
    },
    {
      'id': '4',
      'title': 'Wiper Blade Replacement',
      'desc': 'Front and rear premium wiper blade replacement.',
      'price': '\$35.00',
      'time': '15 mins',
      'icon': Icons.water_drop,
      'isPopular': false,
      'isActive': false,
      'isArchived': true,
    },
  ];

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
                  onPressed: () {
                    if (isEdit) {
                      setState(() {
                        service['title'] = titleController.text;
                        service['desc'] = descController.text;
                        service['price'] = priceController.text;
                        service['time'] = timeController.text;
                        service['isPopular'] = isPopular;
                      });
                    } else {
                      setState(() {
                        _services.add({
                          'id': DateTime.now().millisecondsSinceEpoch
                              .toString(),
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
                          'icon': Icons.build,
                          'isPopular': isPopular,
                          'isActive': true,
                          'isArchived': false,
                        });
                      });
                    }
                    Navigator.pop(context);
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

  void _toggleServiceStatus(Map<String, dynamic> service, bool isActive) {
    setState(() {
      service['isActive'] = isActive;
    });
  }

  void _toggleArchiveStatus(Map<String, dynamic> service) {
    setState(() {
      service['isArchived'] = !(service['isArchived'] as bool);
      if (service['isArchived']) {
        service['isActive'] = false;
      }
    });
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
              child: Text(
                isArchivedTab ? 'No archived services' : 'No active services.',
                style: GoogleFonts.manrope(color: Colors.grey, fontSize: 16),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Slot preferences saved.'),
                        ),
                      );
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
          Text(
            'LIVE PERFORMANCE',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D40D4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$1,240',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+12%',
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
            value: 0.65,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D40D4)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(
            '65% of daily slots booked',
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
              service['icon'],
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
