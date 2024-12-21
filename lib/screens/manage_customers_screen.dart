import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


class ManageCustomersScreen extends StatefulWidget {
  @override
  _ManageCustomersScreenState createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  List<dynamic> _customers = [];
  List<dynamic> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2/food_ordering_api/get_customers.php'));
    if (response.statusCode == 200) {
      setState(() {
        _customers = json.decode(response.body);
        _filteredCustomers = _customers;  // Initially, filtered customers is the same as the full list
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter customers by the search query
  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCustomers = _customers
          .where((customer) => customer['username'] != null &&
          customer['username'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Confirmation dialog before deleting a customer
  void _confirmDeleteCustomer(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this customer?'),
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
                _deleteCustomer(id); // Proceed with deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/delete_customer.php'),
      body: {'id': id.toString()},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['success'])),
        );
        _fetchCustomers(); // Refresh the customer list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete customer')),
      );
    }
  }

  void _showAddEditDialog({int? id, String? username, String? fullname, String? email, String? address, String? phone, int? age}) {
    final TextEditingController _usernameController = TextEditingController(text: username);
    final TextEditingController _fullnameController = TextEditingController(text: fullname);
    final TextEditingController _emailController = TextEditingController(text: email);
    final TextEditingController _addressController = TextEditingController(text: address);
    final TextEditingController _phoneController = TextEditingController(text: phone);
    final TextEditingController _ageController = TextEditingController(text: age != null ? age.toString() : '');

    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
          content: SingleChildScrollView(
            child: Column(
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
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isEdit) {
                  _editCustomer(
                    id!,
                    _usernameController.text,
                    _fullnameController.text,
                    _emailController.text,
                    _addressController.text,
                    _phoneController.text,
                    int.tryParse(_ageController.text) ?? 0, // Ensure safe parsing
                  );
                } else {
                  _addCustomer(
                    _usernameController.text,
                    _fullnameController.text,
                    _emailController.text,
                    _addressController.text,
                    _phoneController.text,
                    int.tryParse(_ageController.text) ?? 0, // Ensure safe parsing
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

  Future<void> _addCustomer(String username, String fullname, String email, String address, String phone, int age) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/add_customer.php'),
      body: {
        'username': username,
        'fullname': fullname,
        'email': email,
        'address': address,
        'phone': phone,
        'age': age.toString(),
        'password': '1111' // Default password
      },
    );

    if (response.statusCode == 200) {
      _fetchCustomers(); // Refresh the customer list
    }
  }

  Future<void> _toggleBlockStatus(int id, bool isBlocked) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/toggle_block_customer.php'),
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
      _fetchCustomers(); // Refresh the list
    }
  }

  Future<void> _editCustomer(int id, String username, String fullname, String email, String address, String phone, int age) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/edit_customer.php'),
      body: {
        'id': id.toString(),
        'username': username,
        'fullname': fullname,
        'email': email,
        'address': address,
        'phone': phone,
        'age': age.toString(),
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['success'])),
        );
        _fetchCustomers(); // Refresh the customer list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update customer')),
      );
    }
  }

  // Show customer details in a dialog
  // Show customer details in a dialog

  void _showCustomerDetailDialog(Map<String, dynamic> customer) {
    double latitude = double.tryParse(customer['latitude'].toString()) ?? 0.0;
    double longitude = double.tryParse(customer['longitude'].toString()) ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${customer['fullname'] ?? 'N/A'}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add your customer detail fields here
                Text('Username: ${customer['username'] ?? 'N/A'}'),
                Text('Email: ${customer['email'] ?? 'N/A'}'),
                Text('Address: ${customer['address'] ?? 'N/A'}'),
                Text('Phone: ${customer['phone'] ?? 'N/A'}'),
                Text('Age: ${customer['age']?.toString() ?? 'N/A'}'),
                SizedBox(height: 20),
                Text('Location:'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.location_on),
                      onPressed: () async {
                        final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                    ),
                  ],
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
        title: Text('Manage Customers'),
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
              onChanged: (query) {
                _filterCustomers(query);  // Call filter function when typing
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _filteredCustomers.length,  // Use the filtered list here
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          final isBlocked = (customer['is_blocked'] == '1');
          return Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isBlocked ? Colors.red[100] : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: isBlocked ? Colors.red : Colors.grey),
            ),
            child:  ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align name and icons
                    children: [
                      Expanded(
                        child: Text(
                          customer['fullname'] ?? 'No full name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              int customerId = int.tryParse(customer['id']?.toString() ?? '0') ?? 0;
                              _showAddEditDialog(
                                id: customerId,
                                username: customer['username'],
                                fullname: customer['fullname'],
                                email: customer['email'],
                                address: customer['address'],
                                phone: customer['phone'],
                                age: int.tryParse(customer['age']?.toString() ?? '0') ?? 0,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(isBlocked ? Icons.lock : Icons.lock_open),
                            onPressed: () {
                              _toggleBlockStatus(
                                int.tryParse(customer['id']?.toString() ?? '0') ?? 0,
                                !isBlocked,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              int customerId = int.tryParse(customer['id']?.toString() ?? '0') ?? 0;
                              _confirmDeleteCustomer(customerId);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              _showCustomerDetailDialog(customer);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 5), // Add some spacing
                  Text(
                    'Phone: ${customer['phone']?.isNotEmpty ?? false ? customer['phone'] : 'No phone'}',
                  ),
                  Text(
                    'Age: ${customer['age'] != 0 ? customer['age'].toString() : 'No age'}',
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
