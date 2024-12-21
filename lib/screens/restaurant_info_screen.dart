import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RestaurantInfoScreen extends StatefulWidget {
  @override
  _RestaurantInfoScreenState createState() => _RestaurantInfoScreenState();
}

class _RestaurantInfoScreenState extends State<RestaurantInfoScreen> {
  List<Map<String, dynamic>> restaurantData = [];
  List<Map<String, dynamic>> filteredRestaurantData = [];
  bool isLoading = true; // Track loading state
  TextEditingController _searchController = TextEditingController(); // Controller for search field

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
    _searchController.addListener(_filterRestaurants); // Add listener to handle search query changes
  }

  // Fetch restaurant data from the API
  Future<void> fetchRestaurants() async {
    final String apiUrl = 'http://10.0.2.2/food_ordering_api/restaurant_data.php'; // Change to your API endpoint

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> data =
        List<Map<String, dynamic>>.from(json.decode(response.body));

        setState(() {
          restaurantData = data;
          filteredRestaurantData = List.from(restaurantData); // Initialize filtered list
          isLoading = false; // Stop loading once data is fetched
        });
      } else {
        throw Exception('Failed to load restaurant details');
      }
    } catch (e) {
      print('Error fetching restaurant data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filter the restaurants based on the search query
  void _filterRestaurants() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredRestaurantData = restaurantData.where((restaurant) {
        return restaurant['name']
            .toString()
            .toLowerCase()
            .contains(query) ||
            restaurant['restaurant_id']
                .toString()
                .contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Clean up the controller when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurants'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0), // Search bar height
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name or ID...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner until data loads
          : filteredRestaurantData.isNotEmpty
          ? ListView.builder(
        itemCount: filteredRestaurantData.length,
        itemBuilder: (context, index) {
          final restaurant = filteredRestaurantData[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('#${restaurant['restaurant_id']}  ${restaurant['name'] ?? 'Unnamed Restaurant'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Orders: ${restaurant['total_orders'] ?? 0}'),
                  Text('Total Earnings: \$${_parseDouble(restaurant['total_earnings']).toStringAsFixed(2)}'),
                  Text('Orders Today: ${restaurant['orders_today'] ?? 0}'),
                  Text('Earnings Today: \$${_parseDouble(restaurant['earnings_today']).toStringAsFixed(2)}'),
                  Text('Orders This Week: ${restaurant['orders_this_week'] ?? 0}'),
                  Text('Earnings This Week: \$${_parseDouble(restaurant['earnings_this_week']).toStringAsFixed(2)}'),
                  Text('Orders This Month: ${restaurant['orders_this_month'] ?? 0}'),
                  Text('Earnings This Month: \$${_parseDouble(restaurant['earnings_this_month']).toStringAsFixed(2)}'),
                  Text('Orders This Year: ${restaurant['orders_this_year'] ?? 0}'),
                  Text('Earnings This Year: \$${_parseDouble(restaurant['earnings_this_year']).toStringAsFixed(2)}'),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                // Navigate to RestaurantInfoScreen if needed
              },
            ),
          );
        },
      )
          : Center(child: Text('No restaurants found.')),
    );
  }

  // Helper method to parse values as double
  double _parseDouble(dynamic value) {
    // Check if the value is null or empty, and return 0.0 if true
    if (value == null || value.toString().isEmpty) {
      return 0.0;
    }
    // Attempt to parse the value to double
    return double.tryParse(value.toString()) ?? 0.0; // Default to 0.0 if parsing fails
  }
}
