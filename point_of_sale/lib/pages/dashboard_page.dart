import 'package:flutter/material.dart';
import 'package:point_of_sale/pages/inventory_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:point_of_sale/pages/pos_page.dart';
import 'package:point_of_sale/pages/login_page.dart';
import 'package:point_of_sale/services/api_service.dart';
import 'package:point_of_sale/pages/product_page.dart' as product;
import 'package:point_of_sale/pages/supplier_page.dart' as supplier;

class DashboardPage extends StatelessWidget {
  final dynamic user;
  const DashboardPage({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    final api = ApiService();
    final prefs = await SharedPreferences.getInstance();

    try {
      final token = prefs.getString('token');
      if (token != null) {
        await api.logout(token);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    await prefs.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    final items = [
      _DashboardItem(
        title: "Products",
        icon: Icons.inventory_2_rounded,
        color: Colors.blueAccent,
        description: "Manage product list, price & stock",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const product.ProductPage()),
        ),
      ),
      _DashboardItem(
        title: "POS",
        icon: Icons.point_of_sale_rounded,
        color: Colors.green,
        description: "Create transactions easily",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const POSPage()),
        ),
      ),
      _DashboardItem(
        title: "Suppliers",
        icon: Icons.people_alt_rounded,
        color: Colors.orangeAccent,
        description: "Manage suppliers and purchases",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const supplier.SupplierPage()),
        ),
      ),
      _DashboardItem(
        title: "Inventory",
        icon: Icons.store_rounded,
        color: Colors.purpleAccent,
        description: "Monitor stock and movement",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InventoryPage()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: isWide ? 1.3 : 1,
          ),
          itemBuilder: (_, index) => items[index],
        ),
      ),
    );
  }
}

class _DashboardItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  State<_DashboardItem> createState() => _DashboardItemState();
}

class _DashboardItemState extends State<_DashboardItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isHovered ? widget.color.withOpacity(0.3) : Colors.black12,
              blurRadius: isHovered ? 10 : 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isHovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.icon,
                    size: size.width > 600 ? 60 : 45,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: size.width > 600 ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width > 600 ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
