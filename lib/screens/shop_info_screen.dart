import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ShopInfoScreen extends StatefulWidget {
  @override
  _ShopInfoScreenState createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  List<Map<String, dynamic>> shopData = [];
  List<Map<String, dynamic>> filteredShopData = [];
  bool isLoading = true; // Track loading state
  TextEditingController _searchController = TextEditingController(); // Controller for search field

  @override
  void initState() {
    super.initState();
    fetchShops();
    _searchController.addListener(_filterShops); // Add listener to handle search query changes
  }

  // Fetch shop data from the API
  Future<void> fetchShops() async {
    final String apiUrl = 'http://10.0.2.2/food_ordering_api/shop_data.php'; // Change to your API endpoint

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> data =
        List<Map<String, dynamic>>.from(json.decode(response.body));

        setState(() {
          shopData = data;
          filteredShopData = List.from(shopData); // Initialize filtered list
          isLoading = false; // Stop loading once data is fetched
        });
      } else {
        throw Exception('Failed to load shop details');
      }
    } catch (e) {
      print('Error fetching shop data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filter the shops based on the search query
  void _filterShops() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredShopData = shopData.where((shop) {
        return shop['name']
            .toString()
            .toLowerCase()
            .contains(query) ||
            shop['shop_id']
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
        title: Text('Shops'),
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
          : filteredShopData.isNotEmpty
          ? ListView.builder(
        itemCount: filteredShopData.length,
        itemBuilder: (context, index) {
          final shop = filteredShopData[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('#${shop['shop_id']}  ${shop['name'] ?? 'Unnamed Shop'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Orders: ${shop['total_orders'] ?? 0}'),
                  Text('Total Earnings: \$${_parseDouble(shop['total_earnings']).toStringAsFixed(2)}'),
                  Text('Orders Today: ${shop['orders_today'] ?? 0}'),
                  Text('Earnings Today: \$${_parseDouble(shop['earnings_today']).toStringAsFixed(2)}'),
                  Text('Orders This Week: ${shop['orders_this_week'] ?? 0}'),
                  Text('Earnings This Week: \$${_parseDouble(shop['earnings_this_week']).toStringAsFixed(2)}'),
                  Text('Orders This Month: ${shop['orders_this_month'] ?? 0}'),
                  Text('Earnings This Month: \$${_parseDouble(shop['earnings_this_month']).toStringAsFixed(2)}'),
                  Text('Orders This Year: ${shop['orders_this_year'] ?? 0}'),
                  Text('Earnings This Year: \$${_parseDouble(shop['earnings_this_year']).toStringAsFixed(2)}'),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                // Navigate to ShopInfoScreen if needed
              },
            ),
          );
        },
      )
          : Center(child: Text('No shops found.')),
    );
  }

  // Helper method to parse values as double
  double _parseDouble(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
