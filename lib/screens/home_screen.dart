import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_bites/screens/login_screen.dart';
import 'package:wallet_bites/screens/order_plans_screen.dart';
import 'package:wallet_bites/services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();

  late Future<List<Map<String, dynamic>>> _menuItemsFuture;

  DateTime _activeDate = DateTime.now(); // ← NEW: track current date
  final TextEditingController _budgetController =
  TextEditingController(text: '25.00');

  double _targetBudget = 25.00;
  double _currentTotal = 0.0;

  String? _planId;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _menuItemsFuture = _supabaseService.getMenuItems();

    _loadPlanForDate(_activeDate);

    // When user edits the budget
    _budgetController.addListener(() async {
      final budget = double.tryParse(_budgetController.text);
      if (budget != null) {
        _targetBudget = budget;

        if (_planId != null) {
          await Supabase.instance.client
              .from('budget_plans')
              .update({'target_cost': _targetBudget})
              .eq('id', _planId!);
        }

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // ======================================================
  // Load plan for ANY date (today, or selected from calendar)
  // ======================================================
  Future<void> _loadPlanForDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final plan = await Supabase.instance.client
        .from('budget_plans')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();

    if (plan != null) {
      // Existing plan
      _planId = plan['id'];
      _targetBudget = (plan['target_cost'] as num).toDouble();
      _budgetController.text = _targetBudget.toStringAsFixed(2);

      final items = await _supabaseService.getSelectedMenuItems(_planId!);
      double total = 0;
      for (var item in items) {
        total += (item['menu_items']['price'] as num).toDouble();
      }
      _currentTotal = total;
    } else {
      // No plan → reset everything for new date
      _planId = null;
      _currentTotal = 0;
      _targetBudget = 00.00;
      _budgetController.text = "00.00";
    }

    setState(() {});
  }

  // ======================================================
  // ADD ITEM LOGIC
  // ======================================================
  void _itemAdded(String menuItemId, double price) async {
    if (_currentTotal + price > _targetBudget) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Budget Exceeded'),
          content: const Text('The item cannot be added. The total cost exceeds the budget.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
      return;
    }

    // If no plan exists for this date, create it
    if (_planId == null) {
      final plan = await _supabaseService.addBudgetPlan(
        _activeDate,
        _targetBudget,
      );
      _planId = plan['id'];
    }

    await _supabaseService.addSelectedItem(_planId!, menuItemId, 1);

    // Refresh totals
    final items = await _supabaseService.getSelectedMenuItems(_planId!);

    double total = 0;
    for (var item in items) {
      total += (item['menu_items']['price'] as num).toDouble();
    }

    setState(() {
      _currentTotal = total;
    });
  }

  // ======================================================
  // BUILD UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[400],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // HEADER
            _buildHeader(),

            const SizedBox(height: 20),

            // BUDGET CARD
            _buildBudgetCard(),

            const SizedBox(height: 20),

            // TABS
            _buildTabs(),

            // MENU LISTS
            Expanded(child: _buildMenuTabs()),
          ],
        ),
      ),

      // ORDER PLAN BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final selectedDate = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrderPlansScreen(),
            ),
          );

          if (selectedDate is DateTime) {
            _activeDate = selectedDate;
            await _loadPlanForDate(selectedDate);
          }
        },
        label: const Text('Order Plan',
            style: TextStyle(fontFamily: 'HowdyBun', fontSize: 20)),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: Colors.yellow[600],
      ),
    );
  }

  // ======================================================
  // SMALL UI BUILDERS
  // ======================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'WALLET BITES',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'HowdyBun',
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const LoginPage(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          TextField(
            controller: _budgetController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              fontFamily: 'HowdyBun',
            ),
            decoration: const InputDecoration(
              prefixText: '\$',
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Budget: ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'HowdyBun',
                  color: Colors.green,
                ),
              ),

              Text(
                _formattedDate(_activeDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'HowdyBun',
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.yellow[600],
      labelColor: Colors.yellow[600],
      unselectedLabelColor: Colors.white,
      labelStyle:
      const TextStyle(fontFamily: 'HowdyBun', fontSize: 17),
      tabs: const [
        Tab(text: 'FOOD'),
        Tab(text: 'DRINK'),
        Tab(text: 'DESSERT'),
      ],
    );
  }

  Widget _buildMenuTabs() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _menuItemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}'));
        }

        final menuItems = snapshot.data!;
        return TabBarView(
          controller: _tabController,
          children: [
            _buildMenuList(
                menuItems.where((i) => i['category'] == 'food').toList()),
            _buildMenuList(
                menuItems.where((i) => i['category'] == 'drink').toList()),
            _buildMenuList(menuItems
                .where((i) => i['category'] == 'dessert')
                .toList()),
          ],
        );
      },
    );
  }

  Widget _buildMenuList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Colors.red, size: 40),
                  onPressed: () => _itemAdded(
                      item['id'], (item['price'] as num).toDouble()),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']!,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'HowdyBun'),
                    ),
                    Text(
                      '\$${item['price']}',
                      style: const TextStyle(
                        fontSize: 22,   // ⬅ bigger
                        fontWeight: FontWeight.bold,
                        fontFamily: 'HowdyBun',
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                item['name'] == 'Fries'
                    ? Image.asset('lib/assets/images/fries.png',
                    width: 80, height: 80)
                    : (item['image_url'] != null
                    ? Image.network(item['image_url']!,
                    width: 80, height: 80)
                    : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  // ======================================================
  // DATE FORMATTER
  // ======================================================
  String _formattedDate(DateTime date) {
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _monthName(int m) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[m - 1];
  }
}
