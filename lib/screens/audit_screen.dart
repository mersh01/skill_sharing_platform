import 'restaurant_info_screen.dart';
import 'shop_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'delivery_worker_info_screen.dart';

class AuditScreen extends StatefulWidget {
  @override
  _AuditScreenState createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  int totalOrdersToday = 0;
  int totalOrdersThisWeek = 0;
  int totalOrdersThisMonth = 0;
  int totalOrdersThisYear = 0;

  double totalEarningsToday = 0.0;
  double totalEarningsThisWeek = 0.0;
  double totalEarningsThisMonth = 0.0;
  double totalEarningsThisYear = 0.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAuditData();
  }

  Future<void> fetchAuditData() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/food_ordering_api/audit_data.php'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalOrdersToday = data['totalOrdersToday'] ?? 0;
          totalOrdersThisWeek = data['totalOrdersThisWeek'] ?? 0;
          totalOrdersThisMonth = data['totalOrdersThisMonth'] ?? 0;
          totalOrdersThisYear = data['totalOrdersThisYear'] ?? 0;

          totalEarningsToday = (data['totalEarningsToday']?.toDouble() ?? 0.0);
          totalEarningsThisWeek = (data['totalEarningsThisWeek']?.toDouble() ?? 0.0);
          totalEarningsThisMonth = (data['totalEarningsThisMonth']?.toDouble() ?? 0.0);
          totalEarningsThisYear = (data['totalEarningsThisYear']?.toDouble() ?? 0.0);
          isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load audit data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching audit data: $e');
      _showErrorSnackBar('Error fetching audit data. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit Screen'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildOverviewGrid(),
              SizedBox(height: 20),
              _buildButtonRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildElevatedButton('Delivery Worker Info', DeliveryWorkerInfoScreen()),
        _buildElevatedButton('Restaurant Info', RestaurantInfoScreen()),
        _buildElevatedButton('Shop Info', ShopInfoScreen()),
      ],
    );
  }

  Widget _buildElevatedButton(String text, Widget page) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOverviewGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildOverviewCard('Total Orders Today', totalOrdersToday.toDouble(), Colors.blue),
        _buildEarningsCard('Total Earnings Today', totalEarningsToday, Colors.green),
        _buildOverviewCard('Total Orders This Week', totalOrdersThisWeek.toDouble(), Colors.blue),
        _buildEarningsCard('Total Earnings This Week', totalEarningsThisWeek, Colors.green),
        _buildOverviewCard('Total Orders This Month', totalOrdersThisMonth.toDouble(), Colors.blue),
        _buildEarningsCard('Total Earnings This Month', totalEarningsThisMonth, Colors.green),
        _buildOverviewCard('Total Orders This Year', totalOrdersThisYear.toDouble(), Colors.blue),
        _buildEarningsCard('Total Earnings This Year', totalEarningsThisYear, Colors.green),
      ],
    );
  }

  Widget _buildOverviewCard(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(String title, double totalEarnings, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            '\$${totalEarnings.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

}
