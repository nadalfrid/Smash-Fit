import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodService {
  // --- USDA API CONFIG ---
  final String _usdaBaseUrl = "https://api.nal.usda.gov/fdc/v1";
  static const String _usdaApiKey = String.fromEnvironment('USDA_API_KEY');

  // 🌟 Local Cache for Malaysian/Custom Foods
  List<Map<String, dynamic>> _localFoodCache = [];
  bool _isCacheLoaded = false;

  // 🌟 NEW: Fetch and cache the Firestore collection in memory
  Future<void> _ensureCacheLoaded() async {
    if (_isCacheLoaded) return; // Only fetch once per app session

    try {
      final db = FirebaseFirestore.instance;
      // Fetches the collection. Firestore's native offline persistence will cache this automatically.
      final snapshot = await db.collection('natural_foods').get();
      
      _localFoodCache = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Inject the auto-generated Firestore ID into the map
        return data;
      }).toList();

      _isCacheLoaded = true;
    } catch (e) {
      throw Exception("Failed to load local food database: $e");
    }
  }

  // 🌟 NEW: Search the local cache instantly
  Future<List<dynamic>> searchMalaysiaFood(String query) async {
    await _ensureCacheLoaded(); // Ensure data is downloaded first

    final lowerQuery = query.toLowerCase().trim();
    
    // Perform lightning-fast local substring search
    final results = _localFoodCache.where((food) {
      final name = (food['name'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery);
    }).toList();

    return results;
  }

  // USDA Endpoint 1: Search (Unchanged)
  Future<List<dynamic>> searchUSDAFood(String query, int pageNumber) async {
    String formattedQuery = query.trim().replaceAll(' ', '+');
    final url = Uri.parse(
      "$_usdaBaseUrl/foods/search?api_key=$_usdaApiKey"
      "&query=$formattedQuery"
      "&dataType=Foundation,SR%20Legacy"
      "&pageSize=25"
      "&pageNumber=$pageNumber"
    );
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['foods'] ?? [];
    } else {
      throw Exception("USDA API Error");
    }
  }

  // USDA Endpoint 2: Details (Unchanged)
  Future<Map<String, dynamic>> getUSDADetails(String fdcId) async {
    final url = Uri.parse("$_usdaBaseUrl/food/$fdcId?api_key=$_usdaApiKey");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("USDA Details failed");
  }
}