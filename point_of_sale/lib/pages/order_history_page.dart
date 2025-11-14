import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final api = ApiService();
  bool loading = true;
  List orders = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await api.getOrdersHistory(); // <-- API kamu
    setState(() {
      orders = data;
      loading = false;
    });
  }

  // ===========================
  // SHOW ORDER DETAIL (BOTTOM SHEET)
  // ===========================
  void showOrderDetail(order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final items = order['items'] ?? [];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Text(
                "Order #${order['id']}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                // order['customer'] ?? "Customer: -",
                "Nama Pelanggan : ${order['customer']}",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 10),

              // Items
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    title: Text(item['product_name']),
                    subtitle: Text("Qty: ${item['qty']}"),
                    trailing: Text(
                      "Rp ${item['price']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),

              const Divider(),

              // Total
              Text(
                "Total: Rp ${order['total_price']}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ===========================
  // BUILD UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order History")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("Belum ada riwayat order"))
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final order = orders[i];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text("Order #${order['id']}"),
                      subtitle: Text(order['created_at']),
                      trailing: Text(
                        "Rp ${order['total_price']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      // TAP → SHOW DETAIL
                      onTap: () => showOrderDetail(order),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
