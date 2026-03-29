import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyRequestsView extends StatefulWidget {
  const EmergencyRequestsView({super.key});

  @override
  State<EmergencyRequestsView> createState() => _EmergencyRequestsViewState();
}

class _EmergencyRequestsViewState extends State<EmergencyRequestsView> {
  final _auth = FirebaseAuth.instance;
  bool _isEditingPersonnel = false;
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadPersonnelDetails();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPersonnelDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final team = data['emergencyTeam'] as List<dynamic>?;
          if (team != null) {
            _teamMembers = List<Map<String, dynamic>>.from(
              team.map((t) {
                final m = Map<String, dynamic>.from(t);
                // Ensure default status if missing
                m['status'] ??= 'AVAILABLE';
                return m;
              }),
            );
          } else {
            // Migration/Default: check old single field
            final p = data['emergencyPersonnel'] as Map<String, dynamic>?;
            if (p != null) {
              _teamMembers = [
                {
                  'name': p['name'] ?? '',
                  'vehicleNo': p['vehicleNo'] ?? '',
                  'contact': p['contact'] ?? '',
                  'status': 'AVAILABLE',
                }
              ];
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading personnel details: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _savePersonnelDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'emergencyTeam': _teamMembers,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _isEditingPersonnel = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving personnel details: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _addMember() {
    setState(() {
      _teamMembers.add({'name': '', 'vehicleNo': '', 'contact': '', 'status': 'AVAILABLE'});
    });
  }

  void _removeMember(int index) {
    setState(() {
      _teamMembers.removeAt(index);
    });
  }

  Future<void> _quickUpdateStatus(int index, String newStatus) async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => _teamMembers[index]['status'] = newStatus);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'emergencyTeam': _teamMembers,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error quick updating status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return Container(
      color: const Color(0xFFF6F6F8),
      padding: const EdgeInsets.all(32),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergencies')
            .where('serviceCenterId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          int activeCount = sortedDocs.where((d) => (d.data() as Map)['status'] != 'COMPLETED').length;
          int completedCount = sortedDocs.length - activeCount;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(activeCount),
              const SizedBox(height: 32),
              _buildStatsRow(activeCount, completedCount),
              const SizedBox(height: 32),
              Expanded(
                child: sortedDocs.isEmpty
                    ? _buildEmptyState()
                    : Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: sortedDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final id = doc.id;
                              return _buildPremiumEmergencyCard(id, data);
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(int activeCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Center',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor and respond to urgent assistance requests',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (activeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emergency_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$activeCount ACTIVE ALERTS',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(int active, int completed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildMiniStat('Active Requests', active.toString(), Colors.orange),
            const SizedBox(height: 24),
            _buildMiniStat('Resolved Today', completed.toString(), Colors.green),
          ],
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _buildEmergencyPersonnelBox(),
        ),
      ],
    );
  }

  Widget _buildEmergencyPersonnelBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isEditingPersonnel ? const Color(0xFF5D40D4).withValues(alpha: 0.2) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF5D40D4),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Emergency Response Team',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (!_isEditingPersonnel)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingPersonnel = true),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Manage Team'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5D40D4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        _loadPersonnelDetails(); // Revert
                        setState(() => _isEditingPersonnel = false);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _savePersonnelDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D40D4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingData)
            const Center(child: LinearProgressIndicator())
          else if (_isEditingPersonnel)
            Column(
              children: [
                ..._teamMembers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> member = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(flex: 2, child: _buildInlineFieldList('Name', member, 'name', Icons.person, idx)),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _buildInlineFieldList('Vehicle', member, 'vehicleNo', Icons.tag, idx)),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _buildInlineFieldList('Phone', member, 'contact', Icons.phone, idx)),
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: _buildStatusSelector(idx)),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeMember(idx),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _addMember,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Add Team Member'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF5D40D4)),
                ),
              ],
            )
          else if (_teamMembers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No team members registered yet.',
                  style: GoogleFonts.manrope(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: _teamMembers.length > 2 ? 150 : null,
              child: SingleChildScrollView(
                child: Column(
                  children: _teamMembers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final member = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
                      ),
                      child: Row(
                        children: [
                          _buildPersonnelInfoItem(
                            'Officer',
                            member['name']?.toString().isEmpty ?? true ? 'N/A' : member['name'],
                            Icons.person_rounded,
                          ),
                          _buildPersonnelInfoItem(
                            'Vehicle',
                            member['vehicleNo']?.toString().isEmpty ?? true ? 'N/A' : member['vehicleNo'],
                            Icons.local_shipping_rounded,
                          ),
                          _buildContactItemWithStatus(
                            'Contact',
                            member['contact']?.toString().isEmpty ?? true ? 'N/A' : member['contact'],
                            Icons.phone_rounded,
                            member['status'] ?? 'AVAILABLE',
                            idx,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInlineFieldList(String label, Map<String, dynamic> member, String key, IconData icon, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: member[key])..selection = TextSelection.fromPosition(TextPosition(offset: member[key]?.length ?? 0)),
          onChanged: (val) => _teamMembers[index][key] = val,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B), // High visibility Slate
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.manrope(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 14, color: const Color(0xFF5D40D4)),
            filled: true,
            fillColor: Colors.grey.shade50.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5D40D4), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector(int index) {
    String currentStatus = _teamMembers[index]['status'] ?? 'AVAILABLE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentStatus,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              items: [
                _buildStatusItem('AVAILABLE', Colors.green, Icons.check_circle_rounded),
                _buildStatusItem('ASSIGNED', Colors.blue, Icons.assignment_turned_in_rounded),
                _buildStatusItem('UNAVAILABLE', Colors.red, Icons.cancel_rounded),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _teamMembers[index]['status'] = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildStatusItem(String value, Color color, IconData icon) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(value.substring(0, 1) + value.substring(1).toLowerCase(), style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildContactItemWithStatus(String label, String value, IconData icon, String status, int index) {
    Color statusColor = status == 'AVAILABLE' ? Colors.green : (status == 'ASSIGNED' ? Colors.blue : Colors.red);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF5D40D4)),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (val) => _quickUpdateStatus(index, val),
                offset: const Offset(0, 30),
                itemBuilder: (context) => [
                  _buildStatusMenuItem('AVAILABLE', Colors.green, Icons.check_circle_rounded),
                  _buildStatusMenuItem('ASSIGNED', Colors.blue, Icons.assignment_turned_in_rounded),
                  _buildStatusMenuItem('UNAVAILABLE', Colors.red, Icons.cancel_rounded),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem(String value, Color color, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPersonnelInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF5D40D4)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green.shade200),
          ),
          const SizedBox(height: 32),
          Text(
            "All clear!",
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No active emergency requests at the moment.",
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEmergencyCard(String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'PENDING';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final isPending = status == 'PENDING';
    final isDispatched = status == 'DISPATCHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPending ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          width: isPending ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isPending ? Icons.emergency_rounded : (isDispatched ? Icons.local_shipping_rounded : Icons.check_circle_rounded),
                color: _getStatusColor(status),
                size: 36,
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _getStatusColor(status),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        timestamp != null ? _formatDate(timestamp) : 'Just now',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['serviceType'] ?? 'SOS Alert',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildInfoRows(data),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            SizedBox(
              width: 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPending)
                    _buildActionButton(
                      'Dispatch Helper',
                      const Color(0xFF5D40D4),
                      id,
                      isPending,
                      isDispatched,
                    )
                  else if (isDispatched)
                    _buildActionButton(
                      'Mark Resolved',
                      Colors.green,
                      id,
                      isPending,
                      isDispatched,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Resolved',
                            style: GoogleFonts.manrope(
                              color: Colors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
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
    );
  }

  List<Widget> _buildInfoRows(Map<String, dynamic> data, {bool isRow = false}) {
    final list = [
      _buildCompactInfo(Icons.person_rounded, data['userName'] ?? data['name'] ?? 'Unknown'),
      if (isRow) const SizedBox(width: 32) else const SizedBox(height: 12),
      _buildPhoneNumberWidget(data['userId'], data['userPhone'] ?? data['phoneNumber'] ?? data['phone']),
      if (isRow) const SizedBox(width: 32) else const SizedBox(height: 12),
      _buildAddressWidget(data, isRow: isRow),
    ];
    return list;
  }

  Widget _buildAddressWidget(Map<String, dynamic> data, {bool isRow = false}) {
    String address = data['address'] ?? data['location'] ?? 'N/A';
    if (address == 'N/A' && data['latitude'] != null) {
      address = "Coordinates: ${data['latitude']}, ${data['longitude']}";
    }

    Widget content = _buildCompactInfo(Icons.location_on_rounded, address);
    if (isRow) return Expanded(child: content);
    return content;
  }

  Widget _buildCompactInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNumberWidget(String? userId, String? currentPhone) {
    if (currentPhone != null &&
        currentPhone != 'N/A' &&
        currentPhone.toString().trim().isNotEmpty) {
      return _buildCompactInfo(Icons.phone_rounded, currentPhone);
    }

    if (userId == null || userId.isEmpty) {
      return _buildCompactInfo(Icons.phone_rounded, 'N/A');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCompactInfo(Icons.phone_rounded, 'Loading...');
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final phone = userData?['phone'] ?? userData?['phoneNumber'] ?? 'N/A';
          return _buildCompactInfo(Icons.phone_rounded, phone);
        }
        return _buildCompactInfo(Icons.phone_rounded, 'N/A');
      },
    );
  }

  Widget _buildActionButton(String label, Color color, String id, bool isPending, bool isDispatched) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          if (isPending) {
            _showDispatchDialog(context, id);
          } else if (isDispatched) {
            _updateStatus(id, 'COMPLETED');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showDispatchDialog(BuildContext context, String emergencyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Dispatch Response Team',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a member from your team to dispatch for this request:',
                style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              if (_teamMembers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'No team members added yet. Please add them in the "Manage Team" section first.',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.orange.shade800),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _teamMembers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final member = _teamMembers[idx];
                      final isAvailable = member['status'] == 'AVAILABLE';
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _updateStatus(emergencyId, 'DISPATCHED', personnel: member);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (isAvailable ? const Color(0xFF5D40D4) : Colors.grey.shade400),
                                      (isAvailable ? const Color(0xFF8B5CF6) : Colors.grey.shade500),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['name'] ?? 'Unknown',
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: const Color(0xFF0F172A), // Slate
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${member['vehicleNo']} • ${member['contact']}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (isAvailable ? Colors.green : (member['status'] == 'ASSIGNED' ? Colors.blue : Colors.red)).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (isAvailable ? Colors.green : (member['status'] == 'ASSIGNED' ? Colors.blue : Colors.red)).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: (isAvailable ? Colors.green : (member['status'] == 'ASSIGNED' ? Colors.blue : Colors.red)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      member['status'] ?? 'AVAILABLE',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: isAvailable ? Colors.green : (member['status'] == 'ASSIGNED' ? Colors.blue : Colors.red),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'DISPATCHED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    String amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:${dt.minute.toString().padLeft(2, '0')} $amPm";
  }

  Future<void> _updateStatus(String id, String newStatus, {Map<String, dynamic>? personnel}) async {
    Map<String, dynamic> updates = {'status': newStatus};
    if (personnel != null) {
      updates['dispatchedPersonnel'] = personnel;
      updates['dispatchedAt'] = FieldValue.serverTimestamp();
    }
    await FirebaseFirestore.instance.collection('emergencies').doc(id).update(updates);
  }
}
