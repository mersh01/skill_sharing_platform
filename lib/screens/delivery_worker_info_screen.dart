import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryWorkerInfoScreen extends StatefulWidget {
  @override
  _DeliveryWorkerInfoScreenState createState() => _DeliveryWorkerInfoScreenState();
}

class _DeliveryWorkerInfoScreenState extends State<DeliveryWorkerInfoScreen> {
  List<Map<String, dynamic>> deliveryWorkerData = [];
  List<Map<String, dynamic>> filteredDeliveryWorkerData = [];
  bool isLoading = true; // Track loading state
  TextEditingController _searchController = TextEditingController(); // Controller for search field

  @override
  void initState() {
    super.initState();
    fetchDeliveryWorkerData();
    _searchController.addListener(_filterDeliveryWorkers); // Add listener to handle search query changes
  }

  // Fetch data from the API
  Future<void> fetchDeliveryWorkerData() async {
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/food_ordering_api/delivery_worker_data.php'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey("error")) {
          print('Error in response: ${data["error"]}');
        } else {
          setState(() {
            deliveryWorkerData = List<Map<String, dynamic>>.from(data);
            filteredDeliveryWorkerData = List.from(deliveryWorkerData); // Initialize filtered list
          });
        }
      } else {
        print('Failed to load delivery worker data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching delivery worker data: $e');
    }
    setState(() {
      isLoading = false; // Stop loading
    });
  }

  // Filter the delivery workers based on the search query
  void _filterDeliveryWorkers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredDeliveryWorkerData = deliveryWorkerData.where((worker) {
        return worker['fullname'].toLowerCase().contains(query) ||
            worker['dw_id'].toString().contains(query);
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
        title: Text('Delivery Worker Info'),
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
          : filteredDeliveryWorkerData.isNotEmpty
          ? ListView.builder(
        itemCount: filteredDeliveryWorkerData.length,
        itemBuilder: (context, index) {
          final worker = filteredDeliveryWorkerData[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(' #${worker['dw_id']} ${worker['fullname']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orders Taken: ${worker['total_orders']}'),
                  Text('Total Earnings: \$${double.tryParse(worker['total_earnings'].toString())?.toStringAsFixed(2) ?? "0.00"}'),
                  Text('Orders taken Today: ${worker['orders_today'] ?? 0}'),
                  Text('Today\'s Earnings: \$${double.tryParse(worker['today_fee'].toString())?.toStringAsFixed(2) ?? "0.00"}'),
                  Text('Orders taken This Week: ${worker['orders_this_week'] ?? 0}'),
                  Text('Weekly Earnings: \$${double.tryParse(worker['week_fee'].toString())?.toStringAsFixed(2) ?? "0.00"}'),
                  Text('Orders taken This Month: ${worker['orders_this_month'] ?? 0}'),
                  Text('Monthly Earnings: \$${double.tryParse(worker['month_fee'].toString())?.toStringAsFixed(2) ?? "0.00"}'),
                  Text('Orders taken This Year: ${worker['orders_this_year'] ?? 0}'),
                  Text('Yearly Earnings: \$${double.tryParse(worker['year_fee'].toString())?.toStringAsFixed(2) ?? "0.00"}'),
                ],
              ),
            ),
          );
        },
      )
          : Center(child: Text('No delivery workers found.')),
    );
  }
}
