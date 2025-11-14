import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage>
    with TickerProviderStateMixin {
  final api = ApiService();
  List suppliers = [];
  List purchaseOrders = [];
  List products = [];
  int? selectedSupplierId;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() => setState(() {}));
    fetchSuppliers();
    fetchProducts();
  }

  Future<void> fetchSuppliers() async {
    final data = await api.getSuppliers();
    setState(() => suppliers = data ?? []);
  }

  Future<void> fetchProducts() async {
    final data = await api.getProducts();
    setState(() => products = data ?? []);
  }

  Future<void> fetchPurchaseOrders([int? supplierId]) async {
    final data = await api.getPurchaseOrders(supplierId: supplierId);
    setState(() => purchaseOrders = data ?? []);
  }

  // ==================== SUPPLIER FORM ====================
  void showSupplierDialog([Map? supplier]) {
    final nameCtrl = TextEditingController(text: supplier?['name'] ?? '');
    final contactCtrl = TextEditingController(text: supplier?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Supplier'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contactCtrl,
              decoration: const InputDecoration(labelText: 'Kontak'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {'name': nameCtrl.text, 'phone': contactCtrl.text};
              if (supplier == null) {
                await api.createSupplier(data);
              } else {
                await api.updateSupplier(supplier['id'], data);
              }
              if (context.mounted) Navigator.pop(ctx);
              fetchSuppliers();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ==================== PURCHASE ORDER FORM ====================
  void showPurchaseDialog([Map? po]) {
    int? selectedProductId = po?['product_id'];
    int? supplierId = po?['supplier_id'] ?? selectedSupplierId;
    String status = po?['status'] ?? 'pending';
    final qtyCtrl = TextEditingController(
      text: po?['quantity']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          po == null ? 'Tambah Purchase Order' : 'Edit Purchase Order',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: supplierId,
                hint: const Text('Pilih Supplier'),
                items: suppliers.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem(
                    value: s['id'],
                    child: Text(s['name']),
                  );
                }).toList(),
                onChanged: (val) => supplierId = val,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedProductId,
                hint: const Text('Pilih Produk'),
                items: products.map<DropdownMenuItem<int>>((p) {
                  return DropdownMenuItem(
                    value: p['id'],
                    child: Text(p['name']),
                  );
                }).toList(),
                onChanged: (val) => selectedProductId = val,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'received', child: Text('Received')),
                ],
                onChanged: (val) => status = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (supplierId == null || selectedProductId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lengkapi semua data')),
                );
                return;
              }

              final data = {
                'supplier_id': supplierId,
                'product_id': selectedProductId,
                'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                'status': status,
              };

              bool success = false;
              if (po == null) {
                success = await api.postPurchaseOrder(data);
              } else {
                success = await api.updatePurchaseOrder(po['id'], data);
              }

              if (success) {
                if (context.mounted) Navigator.pop(ctx);
                fetchPurchaseOrders(supplierId);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menyimpan purchase order'),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier & Purchase Order'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Suppliers'),
            Tab(icon: Icon(Icons.assignment), text: 'Purchase Orders'),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? width * 0.1 : 8.0,
          vertical: 8.0,
        ),
        child: TabBarView(
          controller: tabController,
          children: [
            // SUPPLIER TAB
            RefreshIndicator(
              onRefresh: fetchSuppliers,
              child: ListView.builder(
                itemCount: suppliers.length,
                itemBuilder: (ctx, i) {
                  final s = suppliers[i];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          s['name'][0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        s['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(s['phone'] ?? '-'),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => showSupplierDialog(s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Supplier'),
                                  content: Text(
                                    'Yakin ingin menghapus ${s['name']}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await api.deleteSupplier(s['id']);
                                fetchSuppliers();
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() => selectedSupplierId = s['id']);
                        fetchPurchaseOrders(s['id']);
                        tabController.animateTo(1);
                      },
                    ),
                  );
                },
              ),
            ),

            // PURCHASE ORDER TAB
            RefreshIndicator(
              onRefresh: () => fetchPurchaseOrders(selectedSupplierId),
              child: ListView.builder(
                itemCount: purchaseOrders.length,
                itemBuilder: (ctx, i) {
                  final po = purchaseOrders[i];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        po['status'] == 'received'
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        color: po['status'] == 'received'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(po['product']['name']),
                      subtitle: Text(
                        'Qty: ${po['quantity']} | Status: ${po['status']}\nSupplier: ${po['supplier']['name']}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => showPurchaseDialog(po),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Purchase Order'),
                                  content: Text(
                                    'Yakin ingin menghapus purchase order ${po['product']['name']}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await api.deletePurchaseOrder(po['id']);
                                fetchPurchaseOrders(selectedSupplierId);
                              }
                            },
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

      // FLOATING ACTION BUTTON DINAMIS
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (tabController.index == 0) {
            showSupplierDialog();
          } else {
            showPurchaseDialog();
          }
        },
        icon: Icon(
          tabController.index == 0 ? Icons.person_add : Icons.add_shopping_cart,
        ),
        label: Text(
          tabController.index == 0
              ? 'Tambah Supplier'
              : 'Tambah Purchase Order',
        ),
      ),
    );
  }
}
