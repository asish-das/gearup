import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ServiceInventoryView extends StatefulWidget {
  const ServiceInventoryView({super.key});

  @override
  State<ServiceInventoryView> createState() => _ServiceInventoryViewState();
}

class _ServiceInventoryViewState extends State<ServiceInventoryView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String _selectedCategory = 'Engine';
  final List<String> _categories = ['Engine', 'Brakes', 'Oil & Fluids', 'Filters', 'Wheels', 'Exterior'];
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F6F8),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Spare Parts',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Manage spare parts available at your service center.',
                    style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPartDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Part'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D40D4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInventoryTable(),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: _buildRecentSalesPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Color(0xFF5D40D4), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Recent Sales',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('purchases')
                  .where('serviceCenterId', isEqualTo: _currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final sales = snapshot.data!.docs;
                if (sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.grey[300], size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'No sales yet',
                          style: GoogleFonts.manrope(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = sales[index].data() as Map<String, dynamic>;
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['partName'] ?? 'Unknown Part',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${data['price']}',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['userName'] ?? 'Web User',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spareParts')
          .where('serviceCenterId', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text('No spare parts added yet.', style: GoogleFonts.manrope(color: Colors.grey)),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerTheme: const DividerThemeData(thickness: 1, color: Color(0xFFF1F5F9)),
            ),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
                dataTextStyle: GoogleFonts.manrope(
                  color: const Color(0xFF0F172A),
                  fontSize: 14,
                ),
                columns: const [
                  DataColumn(label: Text('Part Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: docs.map((doc) {
                  final part = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        if (part['imageUrl'] != null && part['imageUrl'].toString().isNotEmpty)
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              image: DecorationImage(
                                image: part['imageUrl'].toString().startsWith('data:image')
                                    ? MemoryImage(base64Decode(part['imageUrl'].toString().split(',').last))
                                    : NetworkImage(part['imageUrl']) as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Text(part['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    )),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D40D4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        part['category'] ?? '',
                        style: const TextStyle(color: Color(0xFF5D40D4), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )),
                    DataCell(Text('₹${part['price']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('${part['stock']}')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF5D40D4), size: 20),
                          onPressed: () => _showAddPartDialog(docId: doc.id, initialData: part),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                          onPressed: () => _deletePart(doc.id),
                          tooltip: 'Delete',
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddPartDialog({String? docId, Map<String, dynamic>? initialData}) {
    if (initialData != null) {
      _nameController.text = initialData['name'];
      _descController.text = initialData['description'];
      _priceController.text = initialData['price'].toString();
      _base64Image = initialData['imageUrl'];
      _stockController.text = initialData['stock'].toString();
      _selectedCategory = initialData['category'];
    } else {
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _base64Image = null;
      _stockController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Add Part' : 'Edit Part'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price')),
              TextField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock')),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    children: [
                      if (_base64Image != null)
                        Container(
                          height: 100,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(_base64Image!.split(',').last)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setDialogState(() {
                              _base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Part Image'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': _nameController.text,
                'description': _descController.text,
                'price': double.tryParse(_priceController.text) ?? 0.0,
                'stock': int.tryParse(_stockController.text) ?? 0,
                'imageUrl': _base64Image ?? '',
                'category': _selectedCategory,
                'serviceCenterId': _currentUid,
              };
              if (docId == null) {
                await FirebaseFirestore.instance.collection('spareParts').add(data);
              } else {
                await FirebaseFirestore.instance.collection('spareParts').doc(docId).update(data);
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deletePart(String id) {
    FirebaseFirestore.instance.collection('spareParts').doc(id).delete();
  }
}
