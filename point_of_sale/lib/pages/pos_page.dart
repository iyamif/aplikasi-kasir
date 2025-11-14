import 'package:flutter/material.dart';
import 'package:point_of_sale/pages/order_history_page.dart';
import '../services/api_service.dart';

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final api = ApiService();
  List products = [];
  List cart = [];
  bool loading = true;
  final buyerController = TextEditingController();
  final productController = TextEditingController();
  final String cName = TextEditingController().text;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await api.getProducts();
    setState(() {
      products = data;
      loading = false;
    });
  }

  void addToCart(item) {
    if (item['stock'] == 0) return;
    final exist = cart.indexWhere((c) => c['id'] == item['id']);
    if (exist >= 0) {
      cart[exist]['qty'] += 1;
    } else {
      cart.add({
        'id': item['id'],
        'name': item['name'],
        'price': item['price'],
        'qty': 1,
      });
    }
    setState(() {});
    productController.clear();
  }

  void removeFromCart(index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void changeQty(int index, int delta) {
    setState(() {
      cart[index]['qty'] += delta;
      if (cart[index]['qty'] <= 0) cart.removeAt(index);
    });
  }

  double get total {
    double t = 0;
    for (var c in cart) {
      t += (double.parse(c['price'].toString()) * c['qty']);
    }
    return t;
  }

  Future<void> checkout() async {
    if (buyerController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Masukkan nama pembeli")));
      return;
    }

    try {
      final success = await api.createOrder(
        customerId: null,
        customerName: buyerController.text,
        cart: cart,
      );

      if (success) {
        // Update stok lokal
        for (var c in cart) {
          final index = products.indexWhere((p) => p['id'] == c['id']);
          if (index >= 0) {
            products[index]['stock'] -= c['qty'];
          }
        }

        cart.clear();
        buyerController.clear();
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Order berhasil")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal order")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // =====================
      // 🚀 SIDEBAR / DRAWER
      // =====================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),

            ListTile(
              leading: Icon(Icons.history),
              title: Text("Order History"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text("POS"),

        // =====================
        // 🚀 GANTI BACK MENJADI HAMBURGER
        // =====================
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Input Nama Pembeli
                  TextField(
                    controller: buyerController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pembeli',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Autocomplete Produk
                  Autocomplete<Map>(
                    displayStringForOption: (option) => option['name'],
                    optionsBuilder: (TextEditingValue text) {
                      if (text.text.isEmpty) return const Iterable<Map>.empty();
                      return products
                          .where(
                            (p) => p['name'].toLowerCase().contains(
                              text.text.toLowerCase(),
                            ),
                          )
                          .cast<Map>();
                    },
                    fieldViewBuilder: (context, controller, focusNode, _) {
                      productController.text = controller.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Cari Produk',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    onSelected: (item) => addToCart(item),
                  ),

                  const SizedBox(height: 12),

                  // CART
                  if (cart.isNotEmpty)
                    Expanded(
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: Colors.grey.shade200,
                            child: Row(
                              children: const [
                                Expanded(flex: 1, child: Text("No")),
                                Expanded(flex: 4, child: Text("Product")),
                                Expanded(flex: 3, child: Text("Qty")),
                                Expanded(flex: 2, child: Text("Price")),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // List Cart
                          Expanded(
                            child: ListView.builder(
                              itemCount: cart.length,
                              itemBuilder: (context, i) {
                                final c = cart[i];
                                return Dismissible(
                                  key: ValueKey(c['id']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (_) => removeFromCart(i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text("${i + 1}"),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(c['name']),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove,
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    changeQty(i, -1),
                                              ),
                                              Text("${c['qty']}"),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add,
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    changeQty(i, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Rp ${(double.parse(c['price'].toString()) * c['qty']).toStringAsFixed(0)}",
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

                  // TOTAL
                  if (cart.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          "Total: Rp ${total.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: checkout,
                          child: const Text("Order"),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
