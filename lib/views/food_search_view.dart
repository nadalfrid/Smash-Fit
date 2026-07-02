import 'package:flutter/material.dart';
import 'dart:async';
import '../controllers/diet_controller.dart';
import 'food_details_view.dart';

// Define the two sections
enum SearchSection { malaysia, ingredients }

class FoodSearchView extends StatefulWidget {
  final String mealId;
  final DietController controller;
  final DateTime? specificTargetDate;
  const FoodSearchView({
    super.key, 
    required this.mealId, 
    required this.controller,
    this.specificTargetDate, // 🌟 NEW
  });

  @override
  State<FoodSearchView> createState() => _FoodSearchViewState();
}

class _FoodSearchViewState extends State<FoodSearchView> {
  Timer? _debounce;
  SearchSection _currentSection = SearchSection.malaysia;
  final TextEditingController _searchController = TextEditingController();

  // Unified search trigger based on active section
  void _triggerSearch(String query) {
    if (query.isEmpty) {
      // Clear results in controller if query is empty
      return; 
    }

    if (_currentSection == SearchSection.malaysia) {
      widget.controller.searchMalaysia(query);
    } else {
      widget.controller.searchUSDA(query);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _triggerSearch(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Search ${widget.mealId}"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          return Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: _currentSection == SearchSection.malaysia 
                        ? "Search Malaysian food..." 
                        : "Search Ingredients (USDA API)...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 2. Section Selector (Toggle Bar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<SearchSection>(
                  segments: const [
                    ButtonSegment(
                      value: SearchSection.malaysia,
                      label: Text("Malaysian"),
                      icon: Icon(Icons.restaurant_menu),
                    ),
                    ButtonSegment(
                      value: SearchSection.ingredients,
                      label: Text("Ingredients"),
                      icon: Icon(Icons.apple),
                    ),
                  ],
                  selected: {_currentSection},
                  onSelectionChanged: (Set<SearchSection> newSelection) {
                    setState(() {
                      _currentSection = newSelection.first;
                    });
                    // Re-trigger search immediately when switching tabs if text exists
                    if (_searchController.text.isNotEmpty) {
                      _triggerSearch(_searchController.text);
                    }
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.teal,
                    selectedForegroundColor: Colors.white,
                    side: BorderSide(color: Colors.teal.shade100),
                  ),
                ),
              ),

              // Loading Indicator
              if (widget.controller.isSearchLoading)
                const LinearProgressIndicator(color: Colors.teal),
              
              // 3. Results List
              Expanded(
                child: widget.controller.searchResults.isEmpty && !widget.controller.isSearchLoading
                    ? Center(
                        child: Text(
                          _currentSection == SearchSection.malaysia 
                              ? "Search for Nasi Lemak, Satay..." 
                              : "Search for Chicken, Broccoli...", 
                          style: const TextStyle(color: Colors.grey)
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.controller.searchResults.length,
                        itemBuilder: (context, index) {
                          final item = widget.controller.searchResults[index];
                          
                          // Normalize display values
                          final String name = item['name'] ?? 'Unknown';
                          final String calories = "${item['calories']?.toInt() ?? 0} kcal";
                          final String serving = item['source'] == "USDA" 
                              ? "per 100 ${item['unit']}" 
                              : "${item['serving']}";

                          return ListTile(
                            title: Text(name),
                            subtitle: Text("$calories | $serving"),
                            trailing: const Icon(Icons.add_circle_outline, color: Colors.teal),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FoodDetailsView(
                                    mealId: widget.mealId,
                                    ingredientData: Map<String, dynamic>.from(item),
                                    controller: widget.controller,
                                    specificTargetDate: widget.specificTargetDate, // 🌟 NEW: Pass it down the chain
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}