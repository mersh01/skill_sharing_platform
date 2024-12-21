import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // For Google Maps navigation

class ManageShopScreen extends StatefulWidget {
  @override
  _ManageShopScreenState createState() => _ManageShopScreenState();
}

class _ManageShopScreenState extends State<ManageShopScreen> {
  List<dynamic> _shops = [];
  List<dynamic> _filteredShops = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _editShop(int id, String name, String location, String phone) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/edit_shop.php'),
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
        _fetchShops(); // Refresh the restaurant list
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

  Future<void> _addShop(String name, String location, String phone) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/add_shops.php'),
      body: {
        'name': name,
        'location': location,
        'phone': phone,
      },
    );

    if (response.statusCode == 200) {
      _fetchShops(); // Refresh the restaurant list
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
                  _editShop(
                    id!,
                    _nameController.text,
                    _locationController.text,
                    _phoneController.text,
                  );
                } else {
                  _addShop(
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

  Future<void> _fetchShops() async {
    final response = await http.get(Uri.parse('http://10.0.2.2/food_ordering_api/admin_get_shops.php'));
    if (response.statusCode == 200) {
      setState(() {
        _shops = json.decode(response.body);
        // Ensure the isBlocked status is correctly set in the local state
        _filteredShops = _shops.map((shop) {
          // Add isBlocked field if not present
          shop['isBlocked'] = shop['isBlocked'] ?? '0';
          return shop;
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _filterShops(String query) {
    setState(() {
      _searchQuery = query;
      _filteredShops = _shops.where((shop) {
        final nameLower = shop['name']?.toLowerCase() ?? '';
        return nameLower.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _confirmDeleteShop(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this shop?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteShop(id);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteShop(int id) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/delete_shop.php'),
      body: {'id': id.toString()},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['success'] ?? responseData['error'])),
      );
      _fetchShops();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete shop')),
      );
    }
  }

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunch(url.toString())) {
      await launch(url.toString());
    } else {
      throw 'Could not launch $url';
    }
  }


  void _showShopDetails(dynamic shop) {
    showDialog(
      context: context,
      builder: (context) {

        // Parse latitude and longitude
        final double? latitude = double.tryParse(shop['latitude'] ?? '0');
        final double? longitude = double.tryParse(shop['longitude'] ?? '0');

        return AlertDialog(
          title: Text('Shop Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${shop['name'] ?? 'N/A'}'),
                Text('username: ${shop['username'] ?? 'N/A'}'),
                Text('Phone: ${shop['phone'] ?? 'N/A'}'),
                Text('address: ${shop['address'] ?? 'N/A'}'),
                Text('status: ${shop['status'] ?? 'N/A'}'),
                Text('Description: ${shop['description'] ?? 'N/A'}'),
                SizedBox(height: 20),
                Text('Location: ${shop['location'] ?? 'click'}'),

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
  Future<void> _toggleBlockStatus(int id, bool isBlocked) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/toggle_block_shop.php'),
      body: {
        'id': id.toString(),
        'is_blocked': isBlocked ? '1' : '0', // Send blocked status
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['success'] ?? responseData['error'])),
      );

      // Update the local state to reflect the new block status
      setState(() {
        // Find the shop and update its block status
        final shopIndex = _filteredShops.indexWhere((shop) => shop['id'] == id.toString());
        if (shopIndex != -1) {
          _filteredShops[shopIndex]['isBlocked'] = isBlocked ? '1' : '0'; // Update the block status
        }
      });

      // Optionally, fetch shops again if you want to ensure consistency
      // _fetchShops();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Shops'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by shop name...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterShops,
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
        itemCount: _filteredShops.length,
        itemBuilder: (context, index) {
          final shop = _filteredShops[index];
          final isBlocked = shop['isBlocked'] == '1';

          return Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isBlocked ? Colors.red[100] : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: isBlocked ? Colors.red : Colors.grey),
            ),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(shop['name'] ?? 'No name'),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () => _showShopDetails(shop),
                  ),
                  IconButton(
                    icon: Icon(isBlocked ? Icons.lock : Icons.lock_open),
                    onPressed: () {
                      _toggleBlockStatus(int.parse(shop['id']), !isBlocked);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _confirmDeleteShop(int.parse(shop['id']));
                    },
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location: ${shop['location'] ?? 'No location'}'),
                  Text('Phone: ${shop['phone'] ?? 'No phone'}'),
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}
