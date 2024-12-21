import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // For Google Maps navigation

class ManageRestaurantScreen extends StatefulWidget {
  @override
  _ManageRestaurantScreenState createState() => _ManageRestaurantScreenState();
}

class _ManageRestaurantScreenState extends State<ManageRestaurantScreen> {
  List<dynamic> _restaurants = [];
  List<dynamic> _filteredRestaurants = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    final response = await http.get(Uri.parse('http://10.0.2.2/food_ordering_api/admin_get_restaurants.php'));
    if (response.statusCode == 200) {
      setState(() {
        _restaurants = json.decode(response.body);
        _filteredRestaurants = _restaurants;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRestaurants(String query) {
    setState(() {
      _searchQuery = query;
      _filteredRestaurants = _restaurants.where((restaurant) {
        final nameLower = restaurant['name']?.toLowerCase() ?? '';
        return nameLower.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _confirmDeleteRestaurant(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this restaurant?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteRestaurant(id); // Proceed with deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRestaurant(int id) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/delete_restaurant.php'),
      body: {'id': id.toString()},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['success'])),
        );
        _fetchRestaurants(); // Refresh the restaurant list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete restaurant')),
      );
    }
  }

  void _showAddEditDialog({int? id, String? name, String? location, String? phone}) {
    final TextEditingController _nameController = TextEditingController(text: name);
    final TextEditingController _locationController = TextEditingController(text: location);
    final TextEditingController _phoneController = TextEditingController(text: phone);

    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Restaurant' : 'Add Restaurant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Restaurant Name'),
                ),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isEdit) {
                  _editRestaurant(
                    id!,
                    _nameController.text,
                    _locationController.text,
                    _phoneController.text,
                  );
                } else {
                  _addRestaurant(
                    _nameController.text,
                    _locationController.text,
                    _phoneController.text,
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addRestaurant(String name, String location, String phone) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/add_restaurant.php'),
      body: {
        'name': name,
        'location': location,
        'phone': phone,
      },
    );

    if (response.statusCode == 200) {
      _fetchRestaurants(); // Refresh the restaurant list
    }
  }

  Future<void> _toggleBlockStatus(int id, bool isBlocked) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/toggle_block_restaurant.php'),
      body: {
        'id': id.toString(),
        'is_blocked': isBlocked ? '1' : '0', // Send blocked status
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(responseData['success'] ?? responseData['error'])),
      );
      _fetchRestaurants(); // Refresh the list
    }
  }

  Future<void> _editRestaurant(int id, String name, String location, String phone) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/edit_restaurant.php'),
      body: {
        'id': id.toString(),
        'name': name,
        'location': location,
        'phone': phone,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['success'])),
        );
        _fetchRestaurants(); // Refresh the restaurant list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update restaurant')),
      );
    }
  }

  // Method to navigate to Google Maps
  void _openGoogleMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  // Method to show restaurant details in a dialog
  void _showRestaurantDetails(dynamic restaurant) {
    showDialog(
      context: context,
      builder: (context) {

        // Parse latitude and longitude
        final double? latitude = double.tryParse(restaurant['latitude'] ?? '0');
        final double? longitude = double.tryParse(restaurant['longitude'] ?? '0');

        return AlertDialog(
          title: Text('Restaurant Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${restaurant['name'] ?? 'N/A'}'),
                Text('username: ${restaurant['username'] ?? 'N/A'}'),
                Text('Phone: ${restaurant['phone'] ?? 'N/A'}'),
                Text('address: ${restaurant['address'] ?? 'N/A'}'),
                Text('status: ${restaurant['status'] ?? 'N/A'}'),
                Text('Description: ${restaurant['description'] ?? 'N/A'}'),
                SizedBox(height: 20),
                Text('Location: ${restaurant['location'] ?? 'click'}'),

                if (latitude != null && longitude != null)
                IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: () => _openGoogleMaps(latitude, longitude),
                ),

                // Add any other relevant details you want here
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Restaurants'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by restaurant name...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterRestaurants,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _filteredRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _filteredRestaurants[index];
          final isBlocked = (restaurant['is_blocked'] == '1');

          return Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isBlocked ? Colors.red[100] : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: isBlocked ? Colors.red : Colors.grey),
            ),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Aligns text and icons
                children: [
                  Expanded(
                    child: Text(restaurant['name'] ?? 'No name'),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () => _showRestaurantDetails(restaurant),
                  ),
                  IconButton(
                    icon: Icon(isBlocked ? Icons.lock : Icons.lock_open),
                    onPressed: () {
                      _toggleBlockStatus(
                        int.tryParse(restaurant['id']?.toString() ?? '0') ?? 0,
                        !isBlocked,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      int restaurantId = int.tryParse(restaurant['id']?.toString() ?? '0') ?? 0;
                      _confirmDeleteRestaurant(restaurantId);
                    },
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location: ${restaurant['address'] ?? 'No location'}'),
                  Text('Phone: ${restaurant['phone'] ?? 'No phone'}'),
                ],
              ),
            ),
          );


        },
      ),
    );
  }
}
