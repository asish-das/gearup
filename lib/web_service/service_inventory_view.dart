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
  final TextEditingController _searchController = TextEditingController();
  String _filterCategory = 'All';

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
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
                      'Service Inventory',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Manage parts and track customer orders.',
                      style: GoogleFonts.manrope(color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddPartDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Part'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D40D4),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF5D40D4),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF5D40D4),
                labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Spare Parts Stock'),
                  Tab(text: 'Part Purchase Orders'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInventoryTab(),
                  _buildOrdersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('purchases')
          .where('serviceCenterId', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, purchaseSnapshot) {
        final Map<String, int> pendingCounts = {};
        if (purchaseSnapshot.hasData) {
          for (var doc in purchaseSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'pending' || data['status'] == 'shipped') {
              final partName = data['partName'] as String?;
              if (partName != null) {
                pendingCounts[partName] = (pendingCounts[partName] ?? 0) + 1;
              }
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryStats(),
            const SizedBox(height: 32),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildInventoryTable(pendingCounts),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 1,
                    child: _buildLowStockPanel(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOrdersSummary(),
        const SizedBox(height: 32),
        Expanded(child: _buildFullOrdersList()),
      ],
    );
  }

  Widget _buildOrdersSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('purchases')
          .where('serviceCenterId', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final docs = snapshot.data!.docs;
        int pending = 0;
        int shipped = 0;
        double totalRevenue = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          final price = (data['price'] ?? 0.0).toDouble();
          final qty = (data['quantity'] ?? 0).toDouble();
          
          if (status == 'pending') pending++;
          if (status == 'shipped') shipped++;
          if (status == 'delivered') totalRevenue += (price * qty);
        }

        return Row(
          children: [
            _buildStatCard('Pending Orders', pending.toString(), Icons.pending_actions_outlined, Colors.orange),
            const SizedBox(width: 24),
            _buildStatCard('Shipped Orders', shipped.toString(), Icons.local_shipping_outlined, Colors.blue),
            const SizedBox(width: 24),
            _buildStatCard('Total Sales (Delivered)', '₹${totalRevenue.toStringAsFixed(0)}', Icons.payments_outlined, Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildFullOrdersList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: Color(0xFF5D40D4), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Order Tracking & Management',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('purchases')
                  .where('serviceCenterId', isEqualTo: _currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final salesDocs = snapshot.data!.docs;
                final sales = salesDocs.toList()..sort((a, b) {
                  final ta = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final tb = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (ta == null) return 1;
                  if (tb == null) return -1;
                  return tb.compareTo(ta);
                });

                if (sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text('No purchase orders found.', style: GoogleFonts.manrope(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1000,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: sales.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final doc = sales[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'pending';
                        final imageUrl = data['imageUrl'] as String?;

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: imageUrl.startsWith('data:image')
                                          ? MemoryImage(base64Decode(imageUrl.split(',').last))
                                          : NetworkImage(imageUrl) as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['partName'] ?? 'Unknown Part',
                                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
                                    ),
                                    Text('Qty: ${data['quantity']} | Total: ₹${(data['price'] ?? 0) * (data['quantity'] ?? 0)}',
                                      style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B))),
                                    Text(data['userName'] ?? 'User', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order Status', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B))),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: ['pending', 'shipped', 'delivered', 'cancelled'].contains(status) ? status : 'pending',
                                          isDense: true,
                                          dropdownColor: Colors.white,
                                          items: ['pending', 'shipped', 'delivered', 'cancelled'].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: value == 'pending' ? Colors.orange : (value == 'delivered' ? Colors.green : Colors.blue),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              FirebaseFirestore.instance.collection('purchases').doc(doc.id).update({'status': newStatus});
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tracking ID', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B))),
                                    Text(data['trackingId'] ?? 'Not set', 
                                      style: GoogleFonts.manrope(
                                        fontSize: 13, 
                                        color: data['trackingId'] != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                        fontStyle: data['trackingId'] != null ? FontStyle.normal : FontStyle.italic,
                                      )),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _showOrderDetails(data, doc.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF5D40D4),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Review Order'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spareParts')
          .where('serviceCenterId', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final docs = snapshot.data!.docs;
        double totalValue = 0;
        int totalItems = 0;
        int lowStockCount = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final price = (data['price'] ?? 0.0).toDouble();
          final stock = data['stock'] ?? 0;
          totalValue += price * stock;
          totalItems += stock as int;
          if (stock < 5) lowStockCount++;
        }

        return Row(
          children: [
            _buildStatCard('Inventory Value', '₹${totalValue.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined, const Color(0xFF5D40D4)),
            const SizedBox(width: 24),
            _buildStatCard('Total Stock', totalItems.toString(), Icons.inventory_2_outlined, const Color(0xFF10B981)),
            const SizedBox(width: 24),
            _buildStatCard('Low Stock', lowStockCount.toString(), Icons.warning_amber_rounded, lowStockCount > 0 ? Colors.orange : Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                hintText: 'Search parts by name...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterCategory,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Color(0xFF0F172A)),
              items: ['All', ..._categories].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) => setState(() => _filterCategory = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTable(Map<String, int> pendingCounts) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spareParts')
          .where('serviceCenterId', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final category = data['category'] ?? '';
          final matchesSearch = name.contains(_searchController.text.toLowerCase());
          final matchesCategory = _filterCategory == 'All' || category == _filterCategory;
          return matchesSearch && matchesCategory;
        }).toList();

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
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerTheme: const DividerThemeData(thickness: 1, color: Color(0xFFE2E8F0)),
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
                  DataColumn(label: Text('Orders')),
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
                    DataCell(Text(
                      '${part['stock']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (part['stock'] ?? 0) < 5 ? Colors.red : const Color(0xFF0F172A),
                      ),
                    )),
                    DataCell(
                      pendingCounts[part['name']] != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pendingCounts[part['name']]} PENDING',
                                style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
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
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1B29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    docId == null ? 'Add New Spare Part' : 'Edit Spare Part',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDialogField('Part Name', _nameController, Icons.label_outline),
              const SizedBox(height: 16),
              _buildDialogField('Description', _descController, Icons.description_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDialogField('Price (₹)', _priceController, Icons.payments_outlined, isNumeric: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDialogField('Stock Quantity', _stockController, Icons.inventory_2_outlined, isNumeric: true)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Part Category', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1926),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2B3D)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    dropdownColor: const Color(0xFF1A1926),
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Part Image', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 12),
                      if (_base64Image != null)
                        Container(
                          height: 120,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2D2B3D)),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(_base64Image!.split(',').last)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      InkWell(
                        onTap: () async {
                          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setDialogState(() {
                              _base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1926),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D2B3D), style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image_outlined, color: Color(0xFF8B5CF6)),
                              const SizedBox(width: 12),
                              Text(
                                _base64Image == null ? 'Upload Part Image' : 'Change Image',
                                style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF94A3B8))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Save Part', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, IconData icon, {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1926),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2D2B3D)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
              border: InputBorder.none,
              hintText: 'Enter $label',
              hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _deletePart(String id) {
    FirebaseFirestore.instance.collection('spareParts').doc(id).delete();
  }

  Widget _buildLowStockPanel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spareParts')
          .where('serviceCenterId', isEqualTo: _currentUid)
          .where('stock', isLessThan: 5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final lowStockItems = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Low Stock Alert',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...lowStockItems.take(3).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? '',
                          style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Stock: ${data['stock']}',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }),
              if (lowStockItems.length > 3)
                Text(
                  '+ ${lowStockItems.length - 3} more items',
                  style: GoogleFonts.manrope(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1B29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Review',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: data['imageUrl'].toString().startsWith('data:image')
                              ? MemoryImage(base64Decode(data['imageUrl'].toString().split(',').last))
                              : NetworkImage(data['imageUrl']) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['partName'] ?? 'Spare Part',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Price: ₹${data['price']}',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          'Quantity: ${data['quantity']}',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total: ₹${(data['price'] ?? 0) * (data['quantity'] ?? 0)}',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 48, color: Color(0xFF2D2B3D)),
              Text(
                'Live Order Tracking',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildTrackingStepper(data['status'] ?? 'pending'),
              const Divider(height: 48, color: Color(0xFF2D2B3D)),
              Text(
                'Customer Information',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.person_outline, 
                'Name', 
                (data['userName']?.toString().isEmpty ?? true) ? 'Unknown' : data['userName']
              ),
              _buildInfoRow(
                Icons.phone_outlined, 
                'Phone', 
                (data['phone']?.toString().isEmpty ?? true) ? 'No contact' : data['phone']
              ),
              _buildInfoRow(
                Icons.location_on_outlined, 
                'Delivery Address', 
                (data['address']?.toString().isEmpty ?? true) ? 'Not provided' : data['address']
              ),
              const SizedBox(height: 16),
              Text(
                'Tracking Information',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: data['trackingId'] ?? ''),
                decoration: InputDecoration(
                  hintText: 'Enter Tracking ID (e.g. BLUEDART123)',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF1A1926),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2D2B3D)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2D2B3D)),
                  ),
                  prefixIcon: const Icon(Icons.local_shipping_outlined, color: Color(0xFF8B5CF6)),
                ),
                onChanged: (val) {
                  FirebaseFirestore.instance.collection('purchases').doc(docId).update({'trackingId': val});
                },
              ),
              const Divider(height: 48, color: Color(0xFF2D2B3D)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (data['status'] == 'delivered' ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (data['status'] ?? 'pending').toUpperCase(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: data['status'] == 'delivered' ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (data['status'] != 'delivered' && data['status'] != 'cancelled')
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ElevatedButton(
                            onPressed: () {
                              final steps = ['pending', 'shipped', 'out for delivery', 'delivered'];
                              final currentIdx = steps.indexOf(data['status'] ?? 'pending');
                              if (currentIdx < steps.length - 1) {
                                final nextStatus = steps[currentIdx + 1];
                                FirebaseFirestore.instance.collection('purchases').doc(docId).update({'status': nextStatus});
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1926),
                              side: const BorderSide(color: Color(0xFF8B5CF6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _getNextStatusAction(data['status'] ?? 'pending'),
                              style: GoogleFonts.manrope(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNextStatusAction(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        return 'Mark as Shipped';
      case 'shipped':
        return 'Mark as Out for Delivery';
      case 'out for delivery':
        return 'Mark as Delivered';
      default:
        return 'Update Status';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(String status) {
    final steps = ['pending', 'shipped', 'out for delivery', 'delivered'];
    final currentIndex = steps.indexOf(status.toLowerCase());
    
    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;
        
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF8B5CF6) : const Color(0xFF2D2B3D),
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted 
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index].toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    color: isCompleted ? const Color(0xFF8B5CF6) : const Color(0xFF2D2B3D),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
