
import 'package:flutter/material.dart';
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
    _budgetPlansFuture = _supabaseService.getBudgetPlans();
    _budgetPlansFuture.then((plans) {
      setState(() {
        _budgetPlans = plans;
        _loadPlanForSelectedDate();
      });
    });
  }

  void _loadPlanForSelectedDate() async {
    final selectedDateStr = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
    final plan = _budgetPlans.firstWhere((p) => p['date'] == selectedDateStr, orElse: () => null);
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
        title: const Text('MY ORDER PLANS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CalendarDatePicker(
                initialDate: _focusedDay,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onDateChanged: (day) {
                  setState(() {
                    _selectedDay = day;
                    _loadPlanForSelectedDate();
                  });
                },
                // You can add markers for dates with plans here
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              ),
              child: const Text('ADD MORE FOOD'),
            ),
            const SizedBox(height: 20),
            _buildOrderDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (_selectedPlan == null) {
      return Container();
    }

    final items = _selectedPlan!['items'] as List<Map<String, dynamic>>;
    final planDate = DateTime.parse(_selectedPlan!['plan']['date']);

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ORDERS FOR ${planDate.month}/${planDate.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index]['menu_items'];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${item['price']}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
