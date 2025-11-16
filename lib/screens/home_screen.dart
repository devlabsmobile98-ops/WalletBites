
import 'package:flutter/material.dart';
import 'package:wallet_bites/services/supabase_service.dart';
import 'package:wallet_bites/screens/order_plans_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  bool _showOrderPlanButton = false;
  late Future<List<Map<String, dynamic>>> _menuItemsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _menuItemsFuture = _supabaseService.getMenuItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _itemAdded(String menuItemId, double price) async {
    // For simplicity, creating a plan for today. You might want to select a date.
    final today = DateTime.now();
    final plan = await _supabaseService.addBudgetPlan(today, 25.00); // Using a default budget
    await _supabaseService.addSelectedItem(plan['id'], menuItemId, 1);

    setState(() {
      _showOrderPlanButton = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[400],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'WALLET BITES',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    '\$25.00',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'December 24, 2024',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'TARGET BUDGET',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],\n              ),\n            ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.yellow[600],
              labelColor: Colors.yellow[600],
              unselectedLabelColor: Colors.white,
              tabs: const [
                Tab(text: 'FOOD'),
                Tab(text: 'DRINK'),
                Tab(text: 'DESSERTS'),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _menuItemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final menuItems = snapshot.data!;
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMenuList(menuItems.where((i) => i['category'] == 'food').toList()),
                      _buildMenuList(menuItems.where((i) => i['category'] == 'drink').toList()),
                      _buildMenuList(menuItems.where((i) => i['category'] == 'desserts').toList()),
                    ],\n                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showOrderPlanButton
          ? FloatingActionButton.extended(\n              onPressed: () {\n                Navigator.push(\n                  context,\n                  MaterialPageRoute(\n                    builder: (context) => const OrderPlansScreen(),\n                  ),\n                );\n              },\n              label: const Text('Order Plan'),\n              icon: const Icon(Icons.shopping_cart),\n              backgroundColor: Colors.yellow[600],\n            )\n          : null,\n    );\n  }\n\n  Widget _buildMenuList(List<Map<String, dynamic>> items) {\n    return ListView.builder(\n      itemCount: items.length,\n      itemBuilder: (context, index) {\n        final item = items[index];\n        return Card(\n          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),\n          shape: RoundedRectangleBorder(\n            borderRadius: BorderRadius.circular(15),\n          ),\n          child: Padding(\n            padding: const EdgeInsets.all(10),\n            child: Row(\n              children: [\n                IconButton(\n                  icon: const Icon(Icons.add_circle, color: Colors.red, size: 40),\n                  onPressed: () => _itemAdded(item['id'], item['price'] as double),\n                ),\n                const SizedBox(width: 10),\n                Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    Text(\n                      item['name']!,\n                      style: const TextStyle(\n                          fontSize: 18, fontWeight: FontWeight.bold),\n                    ),\n                    Text(\n                      '\\$${item['price']}',\n                      style: const TextStyle(fontSize: 16),\n                    ),\n                  ],\n                ),\n                const Spacer(),\n                // You might need a placeholder if the image is null\n                item['image_url'] != null\n                    ? Image.network(item['image_url']!, width: 80, height: 80)\n                    : Container(width: 80, height: 80, color: Colors.grey[200]),\n              ],\n            ),\n          ),\n        );\n      },\n    );\n  }\n}\n