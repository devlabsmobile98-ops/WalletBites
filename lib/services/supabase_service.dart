
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch menu items
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final response = await _client.from('menu_items').select();
    return (response as List).map((item) => item as Map<String, dynamic>).toList();
  }

  // Fetch budget plans for the current user
  Future<List<Map<String, dynamic>>> getBudgetPlans() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client.from('budget_plans').select().eq('user_id', userId);
    return (response as List).map((plan) => plan as Map<String, dynamic>).toList();
  }

  // Fetch selected menu items for a specific plan
  Future<List<Map<String, dynamic>>> getSelectedMenuItems(String planId) async {
    final response = await _client.from('selected_menu_items').select('*, menu_items(*)').eq('plan_id', planId);
    return (response as List).map((item) => item as Map<String, dynamic>).toList();
  }

  // Add a new budget plan
  Future<Map<String, dynamic>> addBudgetPlan(DateTime date, double targetCost) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client.from('budget_plans').insert({
      'user_id': userId,
      'date': date.toIso8601String(),
      'target_cost': targetCost,
    }).select();
    return (response as List).first as Map<String, dynamic>;
  }

  // Add an item to a budget plan
  Future<void> addSelectedItem(String planId, String menuItemId, int quantity) async {
    await _client.from('selected_menu_items').insert({
      'plan_id': planId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
    });
  }

  // ... other methods for updating and deleting ...
}
