import 'package:flutter/material.dart';
import 'audit_screen.dart';
import 'create_order_screen.dart';
import 'manage_customers_screen.dart';
import 'manage_delivery_workers_screen.dart';
import 'manage_restaurant_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_shop_screen.dart';


class AdminHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildDashboardCard(
              context,
              icon: Icons.people,
              title: 'Manage Customers',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageCustomersScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.delivery_dining,
              title: 'Manage Delivery Workers',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageDeliveryWorkersScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.restaurant,
              title: 'Manage Restaurants',
              color: Colors.deepOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageRestaurantScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.shop,
              title: 'Manage Shops',
              color: Colors.deepOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageShopScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.shopping_cart,
              title: 'Manage Orders',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageOrdersScreen()),
                );
              },
            ),
            // Add this card in your GridView children
            _buildDashboardCard(
              context,
              icon: Icons.assessment, // Changed to a valid icon
              title: 'View Audit',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuditScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.add_shopping_cart,
              title: 'Create Order for Customer',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateOrderScreen()),
                );
              },
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 4.0,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
