import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch menu items for display
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final response = await _client.from('menu_items').select();
    return (response as List).map((item) => item as Map<String, dynamic>).toList();
  }

  // Fetch all budget plans for user
  Future<List<Map<String, dynamic>>> getBudgetPlans() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('budget_plans')
        .select()
        .eq('user_id', userId)
        .order('date');

    return (response as List).map((plan) => plan as Map<String, dynamic>).toList();
  }

  // Fetch budget plans for a specific date
  Future<List<Map<String, dynamic>>> getPlansForDate(DateTime date) async {
    final userId = _client.auth.currentUser!.id;
    final dateStr = date.toIso8601String().substring(0, 10);

    final response = await _client
        .from('budget_plans')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('plan_number', ascending: true);

    return (response as List).map((plan) => plan as Map<String, dynamic>).toList();
  }

  // Display selected menu items for a specific plan
  Future<List<Map<String, dynamic>>> getSelectedMenuItems(String planId) async {
    final response = await _client
        .from('selected_menu_items')
        .select('*, menu_items(*)')
        .eq('plan_id', planId);

    return (response as List).map((item) => item as Map<String, dynamic>).toList();
  }

  // Add new order plan for a date with plan number auto-assigned
  Future<Map<String, dynamic>> addBudgetPlan(DateTime date, double targetCost) async {
    final userId = _client.auth.currentUser!.id;
    final dateStr = date.toIso8601String().substring(0, 10);

    // Count existing plans for this date
    final existing = await _client
        .from('budget_plans')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr);

    final nextPlanNumber = existing.length + 1;

    final response = await _client
        .from('budget_plans')
        .insert({
      'user_id': userId,
      'date': dateStr,
      'target_cost': targetCost,
      'plan_number': nextPlanNumber,
    })
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  // Add a menu item to a plan
  Future<void> addSelectedItem(String planId, String menuItemId, int quantity) async {
    await _client.from('selected_menu_items').insert({
      'plan_id': planId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
    });
  }

  // Delete a menu item from a plan
  Future<void> deleteSelectedMenuItem(String id) async {
    await _client.from('selected_menu_items').delete().eq('id', id);
  }

  // Update an existing menu item
  Future<void> updateMenuItem(String id, String name, double price) async {
    await _client
        .from('menu_items')
        .update({'name': name, 'price': price}).eq('id', id);
  }

  // Delete a menu item
  Future<void> deleteMenuItem(String id) async {
    await _client.from('menu_items').delete().eq('id', id);
  }
}
