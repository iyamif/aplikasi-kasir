import 'package:flutter/material.dart';
import 'package:point_of_sale/services/api_service.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final api = ApiService();
  List products = [];
  List filteredProducts = [];
  List categories = [];

  String searchQuery = '';
  int? selectedCategoryId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    final data = await api.getProducts(); // <-- sesuai API Backend

    // Ambil kategori unik dari product
    final cats = data != null
        ? data
              .map((p) {
                return p['category'] ?? {'id': null, 'name': 'Uncategorized'};
              })
              .toSet()
              .toList()
        : [];

    setState(() {
      products = data ?? [];
      categories = cats;
      filteredProducts = products;
      isLoading = false;
    });
  }

  void filterProducts() {
    setState(() {
      filteredProducts = products.where((p) {
        final matchesName = p['name'].toString().toLowerCase().contains(
          searchQuery.toLowerCase(),
        );

        final matchesCategory =
            selectedCategoryId == null ||
            p['category']?['id'] == selectedCategoryId;

        return matchesName && matchesCategory;
      }).toList();
    });
  }

  // ============================
  // UPDATE STOCK (+/-)
  // ============================
  void showUpdateStockDialog(Map product) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text("Update Stok: ${product['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Stok saat ini: ${product['stock']}"),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Jumlah perubahan (contoh: +5 atau -3)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () async {
                int value = int.tryParse(controller.text) ?? 0;

                final res = await api.updateStock(
                  product['id'],
                  value,
                ); // <-- sesuai API

                Navigator.pop(context);
                fetchData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res ? 'Stok berhasil diperbarui' : 'Gagal update',
                    ),
                  ),
                );
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // ============================
  // STOCK OPNAME (SET VALUE)
  // ============================
  void showOpnameDialog(Map product) {
    final controller = TextEditingController(text: product['stock'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text("Stock Opname: ${product['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Masukkan stok aktual hasil pengecekan:"),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stok Aktual",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () async {
                int actualStock = int.tryParse(controller.text) ?? 0;

                final res = await api.stockOpname(
                  product['id'],
                  actualStock,
                ); // <-- sesuai API

                Navigator.pop(context);
                fetchData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res ? 'Opname berhasil' : 'Gagal melakukan opname',
                    ),
                  ),
                );
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // SEARCH & FILTER
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Cari produk...',
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                searchQuery = val;
                                filterProducts();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<int?>(
                            value: selectedCategoryId,
                            hint: const Text('Filter kategori'),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Semua'),
                              ),
                              ...categories.map<DropdownMenuItem<int?>>((c) {
                                return DropdownMenuItem(
                                  value: c['id'],
                                  child: Text(c['name']),
                                );
                              }).toList(),
                            ],
                            onChanged: (val) {
                              selectedCategoryId = val;
                              filterProducts();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TABLE
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchData,
                      child: filteredProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada produk ditemukan.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: isWide ? size.width - 100 : 650,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.blue[50],
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('No')),
                                      DataColumn(label: Text('Produk')),
                                      DataColumn(label: Text('Kategori')),
                                      DataColumn(label: Text('Harga')),
                                      DataColumn(label: Text('Stok')),
                                      DataColumn(label: Text('Aksi')),
                                    ],
                                    rows: List<DataRow>.generate(
                                      filteredProducts.length,
                                      (i) {
                                        final p = filteredProducts[i];

                                        return DataRow(
                                          cells: [
                                            DataCell(Text('${i + 1}')),
                                            DataCell(Text(p['name'] ?? '-')),
                                            DataCell(
                                              Text(
                                                p['category']?['name'] ??
                                                    'Uncategorized',
                                              ),
                                            ),
                                            DataCell(Text("Rp ${p['price']}")),
                                            DataCell(
                                              Text(
                                                "${p['stock']}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: (p['stock'] ?? 0) > 10
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                            ),

                                            // ACTION BUTTONS
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle,
                                                      color: Colors.green,
                                                    ),
                                                    onPressed: () =>
                                                        showUpdateStockDialog(
                                                          p,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.fact_check,
                                                      color: Colors.blue,
                                                    ),
                                                    onPressed: () =>
                                                        showOpnameDialog(p),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
