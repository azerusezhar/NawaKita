import 'package:supabase_flutter/supabase_flutter.dart';

class DestinationsService {
  DestinationsService._();
  static final DestinationsService instance = DestinationsService._();
  
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get popular destinations (highest rated, limited count)
  Future<List<Map<String, dynamic>>> getPopularDestinations({int limit = 6}) async {
    final response = await _supabase
        .from('destinations')
        .select('*, categories(name)')
        .order('rating', ascending: false)
        .order('rating_count', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all destinations with optional filtering
  Future<List<Map<String, dynamic>>> getAllDestinations({
    int? categoryId,
    String? searchQuery,
    int? limit,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('destinations')
        .select('*, categories(name)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
    }

    var orderedQuery = query.order('rating', ascending: false);

    if (limit != null) {
      orderedQuery = orderedQuery.limit(limit);
    }

    if (offset > 0) {
      orderedQuery = orderedQuery.range(offset, offset + (limit ?? 20) - 1);
    }

    final response = await orderedQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get destination by ID
  Future<Map<String, dynamic>?> getDestinationById(int id) async {
    final response = await _supabase
        .from('destinations')
        .select('*, categories(name)')
        .eq('id', id)
        .maybeSingle();
    
    return response;
  }

  /// Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select('*')
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }
}
