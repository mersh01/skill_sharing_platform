import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class ManageDeliveryWorkersScreen extends StatefulWidget {
  @override
  _ManageDeliveryWorkersScreenState createState() => _ManageDeliveryWorkersScreenState();
}

class _ManageDeliveryWorkersScreenState extends State<ManageDeliveryWorkersScreen> {
  List<dynamic> _workers = [];
  List<dynamic> _filteredWorkers = []; // To hold filtered workers
  bool _isLoading = true;
  String _searchQuery = ''; // To hold search query

  @override
  void initState() {
    super.initState();
    _fetchDeliveryWorkers();
  }

  Future<void> _fetchDeliveryWorkers() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2/food_ordering_api/get_delivery_workers.php'));
    if (response.statusCode == 200) {
      setState(() {
        _workers = json.decode(response.body);
        _filteredWorkers = _workers; // Initially, filtered workers are all workers
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to filter workers based on search query
  void _filterWorkers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredWorkers = _workers
          .where((worker) =>
      worker['username'] != null &&
          worker['username'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _deleteWorker(int id) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/delete_delivery_worker.php'),
      body: {'id': id.toString()},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['success'] ?? responseData['error'])),
      );
      _fetchDeliveryWorkers();
    }
  }

  void _showAddEditDialog(
      {int? id, String? username, String? fullname, String? email, String? phone, String? address}) {
    final TextEditingController _usernameController = TextEditingController(
        text: username);
    final TextEditingController _fullnameController = TextEditingController(
        text: fullname);
    final TextEditingController _emailController = TextEditingController(
        text: email);
    final TextEditingController _phoneController = TextEditingController(
        text: phone);
    final TextEditingController _addressController = TextEditingController(
        text: address);

    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Delivery Worker' : 'Add Delivery Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _fullnameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isEdit) {
                  _editWorker(
                      id!, _usernameController.text, _fullnameController.text,
                      _emailController.text, _phoneController.text,
                      _addressController.text);
                } else {
                  _addWorker(_usernameController.text, _fullnameController.text,
                      _emailController.text, _phoneController.text,
                      _addressController.text);
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

  Future<void> _addWorker(String username, String fullname, String email,
      String phone, String address) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/add_delivery_worker.php'),
      body: {
        'username': username,
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'address': address,
        'password': 'default_password' // Default password
      },
    );

    if (response.statusCode == 200) {
      _fetchDeliveryWorkers();
    }
  }

  Future<void> _editWorker(int id, String username, String fullname,
      String email, String phone, String address) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/edit_delivery_worker.php'),
      body: {
        'id': id.toString(),
        'username': username,
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'address': address,
      },
    );

    if (response.statusCode == 200) {
      _fetchDeliveryWorkers();
    }
  }

  Future<void> _toggleBlockStatus(int id, bool isBlocked) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/toggle_block_worker.php'),
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
      _fetchDeliveryWorkers(); // Refresh the list
    }
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this delivery worker?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteWorker(id); // Proceed with deletion
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Function to open Google Maps
  void _openGoogleMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  // Function to show delivery worker details
  void _showWorkerDetailsDialog(Map<String, dynamic> worker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final double? latitude = double.tryParse(worker['latitude'] ?? '0');
        final double? longitude = double.tryParse(worker['longitude'] ?? '0');

        return AlertDialog(
          title: Text(worker['fullname']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: ${worker['username']}'),
                Text('Email: ${worker['email']}'),
                Text('Phone: ${worker['phone']}'),
                Text('Address: ${worker['address']}'),
                Text('status: ${worker['status']}'),
                Text('Registiration Date: ${worker['created_at']}'),
                SizedBox(height: 20),
                Text('Location: ${worker['location'] ?? 'click'}'),
                if (latitude != null && longitude != null)
                  IconButton(
                    icon: Icon(Icons.location_on),
                    onPressed: () => _openGoogleMaps(latitude, longitude),
                  ),
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
        title: Text('Manage Delivery Workers'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by username...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterWorkers, // Call filter function on input change
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
        itemCount: _filteredWorkers.length, // Use the filtered list
        itemBuilder: (context, index) {
          final worker = _filteredWorkers[index];
          final isBlocked = (worker['is_blocked'] == '1');

          return Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isBlocked ? Colors.red[100] : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: isBlocked ? Colors.red : Colors.grey),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Add some padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align everything to the start
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Keep full name and icons apart
                    children: [
                      Expanded(
                        child: Text(
                          worker['fullname'],
                          style: TextStyle(fontWeight: FontWeight.bold), // Make the full name bold
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.info_outline), // Detail icon
                            onPressed: () {
                              _showWorkerDetailsDialog(worker); // Show details
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showAddEditDialog(
                                id: int.tryParse(worker['id'].toString()) ?? 0,
                                username: worker['username'],
                                fullname: worker['fullname'],
                                email: worker['email'],
                                phone: worker['phone'],
                                address: worker['address'],
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(isBlocked ? Icons.lock : Icons.lock_open),
                            onPressed: () {
                              _toggleBlockStatus(
                                int.tryParse(worker['id']?.toString() ?? '0') ?? 0,
                                !isBlocked,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _showDeleteConfirmationDialog(
                                int.tryParse(worker['id']?.toString() ?? '0') ?? 0,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0), // Add space between title and subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username: ${worker['username']}'),
                      Text('Phone: ${worker['phone']}'),
                      Text('Address: ${worker['address']}'),
                    ],
                  ),
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}
