import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final api = ApiService();
  List products = [];
  List filteredProducts = [];
  List categories = [];
  Set<int> selectedIds = {};
  bool loading = true;
  final searchCtrl = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
  String sortField = 'name';
  bool ascending = true;
  String filterStock = 'all';

  int? selectedCategoryId; // untuk dialog

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchProducts();
  }

  Future<void> fetchCategories() async {
    final res = await api.getCategories();
    print(res);
    setState(() {
      categories = res ?? [];
    });
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    final res = await api.getProducts();
    setState(() {
      products = res ?? [];
      applySortFilter();
      loading = false;
    });
  }

  void applySortFilter() {
    List temp = [...products];

    // Filter stock
    temp = temp.where((p) {
      final stock = int.tryParse(p['stock'].toString()) ?? 0;
      if (filterStock == 'low') return stock > 0 && stock < 5;
      if (filterStock == 'out') return stock == 0;
      return true;
    }).toList();

    // Sort
    temp.sort((a, b) {
      dynamic valA = a[sortField];
      dynamic valB = b[sortField];
      if (valA is String)
        return ascending ? valA.compareTo(valB) : valB.compareTo(valA);
      if (valA is num)
        return ascending ? (valA - valB).toInt() : (valB - valA).toInt();
      return 0;
    });

    // Search
    final query = searchCtrl.text.toLowerCase();
    if (query.isNotEmpty) {
      temp = temp
          .where((p) => (p['name'] ?? '').toLowerCase().contains(query))
          .toList();
    }

    setState(() => filteredProducts = temp);
  }

  void onSearch(String query) => applySortFilter();

  void showProductDialog({Map? product}) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final priceCtrl = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    final stockCtrl = TextEditingController(
      text: product?['stock']?.toString() ?? '',
    );

    selectedCategoryId = product?['category_id'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (contextDialog, setStateDialog) => AlertDialog(
          title: Text(product != null ? 'Edit Produk' : 'Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setStateDialog(() {
                    selectedCategoryId = val;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty ||
                    priceCtrl.text.isEmpty ||
                    stockCtrl.text.isEmpty ||
                    selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nama, harga, stock, dan kategori wajib diisi',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final data = {
                  'name': nameCtrl.text,
                  // 'description': descCtrl.text,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'category_id': selectedCategoryId,
                };

                if (product != null) {
                  await api.updateProduct(product['id'], data);
                } else {
                  await api.createProduct(data);
                }

                Navigator.pop(context);
                fetchProducts();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await api.deleteProduct(id);
              Navigator.pop(context);
              fetchProducts();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void deleteSelected() async {
    for (var id in selectedIds) await api.deleteProduct(id);
    selectedIds.clear();
    fetchProducts();
  }

  Color stockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }

  Widget buildProductCard(Map product) {
    final stock = int.tryParse(product['stock'].toString()) ?? 0;
    final price = double.tryParse(product['price'].toString()) ?? 0;
    final selected = selectedIds.contains(product['id']);
    final category = product['category']?['name'] ?? 'Other';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: Colors.grey.shade300,
      child: InkWell(
        onTap: () => showProductDialog(product: product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true)
                          selectedIds.add(product['id']);
                        else
                          selectedIds.remove(product['id']);
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                product['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                currencyFormat.format(price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor(stock),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stock: $stock',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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

  void showSortFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sort & Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sort By:'),
            DropdownButton<String>(
              value: sortField,
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Name')),
                DropdownMenuItem(value: 'price', child: Text('Price')),
                DropdownMenuItem(value: 'stock', child: Text('Stock')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => sortField = val);
                  applySortFilter();
                  Navigator.pop(context);
                  showSortFilterDialog();
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(ascending ? 'Ascending' : 'Descending'),
              value: ascending,
              onChanged: (val) {
                setState(() => ascending = val);
                applySortFilter();
                Navigator.pop(context);
                showSortFilterDialog();
              },
            ),
            const SizedBox(height: 8),
            const Text('Stock Filter:'),
            DropdownButton<String>(
              value: filterStock,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'low', child: Text('Low Stock (<5)')),
                DropdownMenuItem(value: 'out', child: Text('Out of Stock')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => filterStock = val);
                  applySortFilter();
                  Navigator.pop(context);
                  showSortFilterDialog();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: showSortFilterDialog,
          ),
          if (selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: deleteSelected,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchProducts,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (_, index) =>
                    buildProductCard(filteredProducts[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProductDialog(),
        label: const Text('Tambah Produk'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
