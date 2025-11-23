// Import Material for Design and Screens for Navigation
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wallet_bites/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderPlansScreen extends StatefulWidget {
  const OrderPlansScreen({super.key});

  // Create State for Order Plans for Saving
  @override
  State<OrderPlansScreen> createState() => _OrderPlansScreenState();
}

class _OrderPlansScreenState extends State<OrderPlansScreen> {
  // Service For Communicating With Supabase
  final SupabaseService _supabaseService = SupabaseService();

  // Future That Loads All Budget Plans
  late Future<List<Map<String, dynamic>>> _budgetPlansFuture;

  // Cached List Of All Budget Plans
  List<Map<String, dynamic>> _budgetPlans = [];

  // Currently Selected Calendar Day And Focused Month
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Currently Selected Plan And Its Items
  Map<String, dynamic>? _selectedPlan;

  // Stores All Plans Associated With The Selected Date
  List<Map<String, dynamic>> _plansForSelectedDate = [];

  @override
  void initState() {
    super.initState();
    // Loads Plans When Screen First Opens
    _loadBudgetPlans();
  }

  // Fetches All Budget Plans From Database
  void _loadBudgetPlans() {
    _budgetPlansFuture = _supabaseService.getBudgetPlans();
    _budgetPlansFuture.then((plans) {
      setState(() {
        _budgetPlans = plans;
        _loadPlanForSelectedDate();
      });
    });
  }

  // Loads Plan(s) For The Currently Selected Calendar Date
  void _loadPlanForSelectedDate() async {
    final selectedDateStr =
        "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";

    // Filters All Plans That Match The Selected Date
    _plansForSelectedDate =
        _budgetPlans.where((p) => p['date'] == selectedDateStr).toList()
          ..sort((a, b) => (a['plan_number'] as int).compareTo(b['plan_number']));

    // Automatically Loads The First Plan For This Date
    final plan = _plansForSelectedDate.isNotEmpty ? _plansForSelectedDate.first : null;

    if (plan != null) {
      // Fetches Menu Items Included In This Plan
      final items = await _supabaseService.getSelectedMenuItems(plan['id']);
      setState(() {
        _selectedPlan = {'plan': plan, 'items': items};
      });
    } else {
      // Clears UI If No Plan Exists
      setState(() {
        _selectedPlan = null;
      });
    }
  }

  // Dialog For Allowing User To Switch Between Multiple Plans For The Same Date
  void _showSwitchPlanDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            "Select Plan",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          // List Of Available Plans For That Day
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _plansForSelectedDate.map((plan) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tap To Switch To This Plan
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);

                        // Loads Menu Items For The Selected Plan
                        final items = await _supabaseService
                            .getSelectedMenuItems(plan['id']);

                        setState(() {
                          _selectedPlan = {'plan': plan, 'items': items};
                        });
                      },
                      child: Text(
                        "Plan ${plan['plan_number']}",
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),

                    // Button For Deleting The Plan Entirely
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Deletes Plan Record
                        await Supabase.instance.client
                            .from('budget_plans')
                            .delete()
                            .eq('id', plan['id']);

                        // Deletes All Related Menu Items
                        await Supabase.instance.client
                            .from('selected_menu_items')
                            .delete()
                            .eq('plan_id', plan['id']);

                        Navigator.pop(context);

                        // Reloads Plan List After Deletion
                        _loadBudgetPlans();
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[400],

      // AppBar For Navigation And Screen Title
      appBar: AppBar(
        backgroundColor: Colors.yellow[600],
        title: const Text('Dates & Order Plans',
            style: TextStyle(fontFamily: 'HowdyBun', fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Scrollable Body Containing Calendar, Buttons, And Order Details
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            _buildCalendar(),

            const SizedBox(height: 20),

            // Button For Adding More Items To The Current Date's Plan
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedDay);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              ),
              child: const Text(
                'ADD MORE FOOD',
                style: TextStyle(
                    fontFamily: 'HowdyBun',
                    color: Colors.white,
                    fontSize: 20),
              ),
            ),

            const SizedBox(height: 10),

            // Button For Switching Between Plans For The Same Date
            ElevatedButton(
              onPressed: _showSwitchPlanDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              ),
              child: const Text(
                '   SWITCH PLAN   ',
                style: TextStyle(
                    fontFamily: 'HowdyBun',
                    color: Colors.white,
                    fontSize: 20),
              ),
            ),

            const SizedBox(height: 20),

            // Displays The Selected Plan’s Items And Totals
            _buildOrderDetails(),
          ],
        ),
      ),
    );
  }

  // Builds The Date Selection Calendar With Event Indicators
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,

        // Determines Which Day Appears Selected Visually
        selectedDayPredicate: (day) =>
            day.year == _selectedDay.year &&
            day.month == _selectedDay.month &&
            day.day == _selectedDay.day,

        // Adds Red Dot When A Plan Exists On A Given Date
        eventLoader: (day) {
          final dateStr =
              "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
          final hasPlan = _budgetPlans.any((p) => p['date'] == dateStr);
          return hasPlan ? ['PLAN_EXISTS'] : [];
        },

        calendarStyle: CalendarStyle(
          markerSize: 12.0,
          markerDecoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          markersAlignment: Alignment.bottomCenter,
          markersMaxCount: 1,

          // Text Style Customizations For Calendar Days
          defaultTextStyle:
              const TextStyle(fontFamily: 'HowdyBun', fontSize: 16),
          weekendTextStyle: const TextStyle(
              fontFamily: 'HowdyBun', fontSize: 16, color: Colors.red),
          todayTextStyle: const TextStyle(
              fontFamily: 'HowdyBun',
              fontWeight: FontWeight.bold,
              fontSize: 16),
          selectedTextStyle: const TextStyle(
              fontFamily: 'HowdyBun', fontSize: 16, color: Colors.white),
        ),

        // When User Taps A Date, Load The Plans For That Date
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadPlanForSelectedDate();
        },

        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontFamily: 'HowdyBun', fontSize: 20),
        ),
      ),
    );
  }

  // Builds The Panel Showing Plan Items And Total Cost
  Widget _buildOrderDetails() {
    if (_selectedPlan == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),

        // Message For Days Without A Plan
        child: const Center(
          child: Text('No plan for this date.',
              style: TextStyle(fontFamily: 'HowdyBun', fontSize: 18)),
        ),
      );
    }

    // Extracts Data Needed For Display
    final items = _selectedPlan!['items'] as List<Map<String, dynamic>>;
    final planDate = DateTime.parse(_selectedPlan!['plan']['date']);
    final targetBudget = _selectedPlan!['plan']['target_cost'];

    // Computes The Cost Sum Of All Selected Menu Items
    final totalCost = items.fold(
      0.0,
      (sum, item) => sum + (item['menu_items']['price'] as num).toDouble(),
    );

    return Column(
      children: [
        // Displays Date And Target Budget
        Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.yellow[600],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DATE: ${planDate.month}/${planDate.day}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'HowdyBun',
                    fontSize: 20),
              ),
              Text(
                'TARGET: \$$targetBudget',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'HowdyBun',
                    fontSize: 20),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // List Of Items In The Selected Plan
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final selectedItem = items[index];
            final item = selectedItem['menu_items'];
            final selectedItemId = selectedItem['id'];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Displays Item Name And Price
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
                                  fontSize: 16, fontFamily: 'HowdyBun')),
                        ],
                      ),
                    ),

                    // Shows Fries Image For Matching Items
                    if (item['name'] == 'Fries')
                      Image.asset(
                        'lib/assets/images/fries.png',
                        width: 80,
                        height: 80,
                      ),

                    // Button To Delete This Plan Item
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red, size: 32),
                      onPressed: () async {
                        await _supabaseService
                            .deleteSelectedMenuItem(selectedItemId);
                        _loadPlanForSelectedDate();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Displays Total Cost For The Plan
        Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TOTAL: \$${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'HowdyBun',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        const SizedBox(height: 20),
      ],
    );
  }
}
