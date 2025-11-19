import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wallet_bites/services/supabase_service.dart';

class OrderPlansScreen extends StatefulWidget {
  const OrderPlansScreen({super.key});

  @override
  State<OrderPlansScreen> createState() => _OrderPlansScreenState();
}

class _OrderPlansScreenState extends State<OrderPlansScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  late Future<List<Map<String, dynamic>>> _budgetPlansFuture;
  List<Map<String, dynamic>> _budgetPlans = [];

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  Map<String, dynamic>? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadBudgetPlans();
  }

  void _loadBudgetPlans() {
    _budgetPlansFuture = _supabaseService.getBudgetPlans();
    _budgetPlansFuture.then((plans) {
      setState(() {
        _budgetPlans = plans;
        _loadPlanForSelectedDate();
      });
    });
  }

  void _loadPlanForSelectedDate() async {
    final selectedDateStr =
        "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";

    final plans = _budgetPlans.where((p) => p['date'] == selectedDateStr);
    final plan = plans.isNotEmpty ? plans.first : null;

    if (plan != null) {
      final items = await _supabaseService.getSelectedMenuItems(plan['id']);
      setState(() {
        _selectedPlan = {'plan': plan, 'items': items};
      });
    } else {
      setState(() {
        _selectedPlan = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[400],
      appBar: AppBar(
        backgroundColor: Colors.yellow[600],
        title: const Text('Dates & Order Plans',
            style: TextStyle(fontFamily: 'HowdyBun', fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            _buildCalendar(),

            const SizedBox(height: 20),

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
                    fontFamily: 'HowdyBun', color: Colors.white, fontSize: 20),
              ),
            ),

            const SizedBox(height: 20),

            _buildOrderDetails(),
          ],
        ),
      ),
    );
  }

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
        selectedDayPredicate: (day) =>
        day.year == _selectedDay.year &&
            day.month == _selectedDay.month &&
            day.day == _selectedDay.day,
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
          defaultTextStyle:
          const TextStyle(fontFamily: 'HowdyBun', fontSize: 16),
          weekendTextStyle: const TextStyle(
              fontFamily: 'HowdyBun', fontSize: 16, color: Colors.red),
          todayTextStyle: const TextStyle(
              fontFamily: 'HowdyBun',
              fontWeight: FontWeight.bold,
              fontSize: 16),
          selectedTextStyle:
          const TextStyle(fontFamily: 'HowdyBun', fontSize: 16, color: Colors.white),
        ),
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

  Widget _buildOrderDetails() {
    if (_selectedPlan == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text('No plan for this date.',
              style: TextStyle(fontFamily: 'HowdyBun', fontSize: 18)),
        ),
      );
    }

    final items = _selectedPlan!['items'] as List<Map<String, dynamic>>;
    final planDate = DateTime.parse(_selectedPlan!['plan']['date']);
    final targetBudget = _selectedPlan!['plan']['target_cost'];

    final totalCost = items.fold(
      0.0,
          (sum, item) => sum + (item['menu_items']['price'] as num).toDouble(),
    );

    return Column(
      children: [
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

        /// UPDATED LIST WITH DELETE BUTTON
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final selectedItem = items[index];
            final item = selectedItem['menu_items'];
            final selectedItemId = selectedItem['id'];

            return Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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

                    if (item['name'] == 'Fries')
                      Image.asset(
                        'lib/assets/images/fries.png',
                        width: 80,
                        height: 80,
                      ),

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

        Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.brown,
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
