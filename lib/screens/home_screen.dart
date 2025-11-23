// Import Material for Design and Screens for Navigation
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_bites/screens/login_screen.dart';
import 'package:wallet_bites/screens/order_plans_screen.dart';
import 'package:wallet_bites/services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Create State for Home Screen for Saving
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Logic Controller for Home Screen
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Tab Controller for UI
  final SupabaseService _supabaseService = SupabaseService(); // Instantiate Supabase

  late Future<List<Map<String, dynamic>>> _menuItemsFuture; // Loading Menu Items in Rendering

  DateTime _activeDate = DateTime.now(); // Currently Selected Date for Order Plan
  final TextEditingController _budgetController =
  TextEditingController(text: '00.00');

  double _targetBudget = 00.00; // Target Budget for Order Plan
  double _currentTotal = 00.00; // Total Cost

  String? _planId;

  @override
  void initState() {
    // Initialize State And Load Initial Data
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _menuItemsFuture = _supabaseService.getMenuItems();

    _loadPlanForDate(_activeDate);

    _budgetController.addListener(() async {
      final budget = double.tryParse(_budgetController.text);
      if (budget != null) {
        _targetBudget = budget;

        if (_planId != null) {
          await Supabase.instance.client
              .from('budget_plans')
              .update({'target_cost': _targetBudget}).eq('id', _planId!);
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Dispose Controllers And Clean Up
    _tabController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadPlanForDate(DateTime date) async {
    // Load Budget Plan And Selected Items For Given Date
    final dateStr = date.toIso8601String().substring(0, 10);
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final allPlans = await Supabase.instance.client
        .from('budget_plans')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('plan_number');

    if (allPlans.isNotEmpty) {
      final plan = allPlans.first;

      _planId = plan['id'];
      _targetBudget = (plan['target_cost'] as num).toDouble();
      _budgetController.text =
      _targetBudget == 0
          ? "00.00"
          : _targetBudget.toStringAsFixed(2);

      final items = await _supabaseService.getSelectedMenuItems(_planId!);
      _currentTotal = items.fold(
          00.00,
              (sum, item) =>
          sum + (item['menu_items']['price'] as num).toDouble());
    } else {
      _planId = null;
      _currentTotal = 0;
      _targetBudget = 00.00;
      _budgetController.text = "00.00";
    }

    setState(() {});
  }

  void _itemAdded(String menuItemId, double price) async {
    // Add Item To Current Plan And Update Total Cost
    if (_currentTotal + price > _targetBudget) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Budget Exceeded'),
          content: Text('This item exceeds your target budget.'),
        ),
      );
      return;
    }

    if (_planId == null) {
      final newPlan =
      await _supabaseService.addBudgetPlan(_activeDate, _targetBudget);
      _planId = newPlan['id'];
    }

    await _supabaseService.addSelectedItem(_planId!, menuItemId, 1);

    final items = await _supabaseService.getSelectedMenuItems(_planId!);
    _currentTotal = items.fold(
        0.0,
            (sum, item) =>
        sum + (item['menu_items']['price'] as num).toDouble());

    setState(() {});
  }

  void _showEditMenuItemDialog(Map<String, dynamic> item) {
    // Show Dialog To Edit Existing Menu Item
    final nameCtrl = TextEditingController(text: item['name']);
    final priceCtrl = TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Save"),
            onPressed: () async {
              await Supabase.instance.client
                  .from('menu_items')
                  .update({
                'name': nameCtrl.text,
                'price': double.parse(priceCtrl.text)
              })
                  .eq('id', item['id']);

              Navigator.pop(context);

              setState(() {
                _menuItemsFuture = _supabaseService.getMenuItems();
              });
            },
          ),
        ],
      ),
    );
  }

  void _deleteMenuItem(String id) async {
    // Delete Menu Item From Database
    await Supabase.instance.client.from('menu_items').delete().eq('id', id);
    setState(() {
      _menuItemsFuture = _supabaseService.getMenuItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build Main Home Screen UI
    return Scaffold(
      backgroundColor: Colors.red[400],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildBudgetCard(),
            const SizedBox(height: 20),
            _buildTabs(),
            Expanded(child: _buildMenuTabs()),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final selectedDate = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const OrderPlansScreen()));

          if (selectedDate != null) {
            _activeDate = selectedDate;
            await _loadPlanForDate(selectedDate);
          }
        },
        label: const Text("Order Plan",
            style: TextStyle(fontFamily: "HowdyBun", fontSize: 20)),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: Colors.yellow[600],
      ),
    );
  }

  Widget _buildHeader() {
    // Build Header With Title And Logout Button
    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                "WALLET BITES",
                style: TextStyle(
                  fontSize: 30
                  ,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'HowdyBun',
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 3,
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard() {
    // Build Budget Input Card And Add Plan Button
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          TextField(
            controller: _budgetController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                fontFamily: 'HowdyBun'),
            decoration: const InputDecoration(prefixText: '\$', border: InputBorder.none),
          ),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Budget: ",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'HowdyBun',
                    color: Colors.green)),
            Text(_formattedDate(_activeDate),
                style: const TextStyle(
                    fontSize: 18, fontFamily: 'HowdyBun'))
          ]),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final newPlan = await _supabaseService.addBudgetPlan(
                _activeDate,
                00.00,
              );

              setState(() {
                _planId = newPlan['id'];

                _targetBudget = 00.00;
                _budgetController.text = "00.00";
                _currentTotal = 00.00;
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 12)),
            child: const Text("ADD PLAN",
                style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'HowdyBun',
                    color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    // Build Category Tabs (Food, Drink, Dessert)
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.yellow[600],
      labelColor: Colors.yellow[600],
      unselectedLabelColor: Colors.white,
      labelStyle: const TextStyle(fontFamily: 'HowdyBun', fontSize: 17),
      tabs: const [
        Tab(text: 'FOOD'),
        Tab(text: 'DRINK'),
        Tab(text: 'DESSERT'),
      ],
    );
  }

  Widget _buildMenuTabs() {
    // Build Tab Views For Menu Categories
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _menuItemsFuture,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final menuItems = snapshot.data!;
        return TabBarView(controller: _tabController, children: [
          _buildMenuList(menuItems.where((i) => i['category'] == 'food').toList()),
          _buildMenuList(menuItems.where((i) => i['category'] == 'drink').toList()),
          _buildMenuList(menuItems.where((i) => i['category'] == 'dessert').toList()),
        ]);
      },
    );
  }

  Widget _buildMenuList(List<Map<String, dynamic>> items) {
    // Build Scrollable List Of Menu Items
    return ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: Colors.red, size: 40),
                    onPressed: () => _itemAdded(
                        item['id'], (item['price'] as num).toDouble()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'],
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'HowdyBun')),
                          Text("\$${item['price']}",
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'HowdyBun',
                                  color: Colors.redAccent)),
                        ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 30),
                    onPressed: () => _showEditMenuItemDialog(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                    onPressed: () => _deleteMenuItem(item['id']),
                  )
                ],
              ),
            ),
          );
        });
  }

  String _formattedDate(DateTime date) {
    // Format Date Into Readable String
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _monthName(int m) {
    // Convert Month Number To Month Name
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[m - 1];
  }
}
