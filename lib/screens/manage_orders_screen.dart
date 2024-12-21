import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Add this for date formatting

class ManageOrdersScreen extends StatefulWidget {
  @override
  _ManageOrdersScreenState createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  List<dynamic> _workers = []; // Store workers here
  bool _isLoading = true;
  bool _isWorkersLoading = true; // Track workers loading status
  String _searchTerm = '';

  // Controller for the status field
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchWorkers();
  }

  @override
  void dispose() {
    _statusController.dispose(); // Dispose of the controller when done
    super.dispose();
  }

  // Fetch orders from API
  Future<void> _fetchOrders() async {
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2/food_ordering_api/admin_get_orders.php'));

      // Debug: Log the raw response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Log the raw body

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check if 'success' exists in the response
        if (responseData['success'] == true) {
          setState(() {
            _orders = responseData['orders']; // Access the 'orders' key
            _filteredOrders = _orders;
            _isLoading = false;
          });
        } else {
          // Log the error message from the response if 'success' is false
          throw Exception('Failed to load orders: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load orders: ${response.reasonPhrase}');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load orders: $error');
    }
  }



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchWorkers() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/food_ordering_api/admin_get_delivery_workers.php'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(responseData); // Debug: Print the response data

        if (responseData['success'] == true) {
          setState(() {
            _workers = responseData['workers'];
            _isWorkersLoading = false;
          });
        }
      }
    } catch (error) {
      setState(() {
        _isWorkersLoading = false;
      });
    }
  }

  // Helper function to format dates for grouping
  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    if (date.isAfter(today)) {
      return 'Today';
    } else if (date.isAfter(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }

  // Group orders by date
  Map<String, List<dynamic>> _groupOrdersByDate() {
    Map<String, List<dynamic>> groupedOrders = {};

    for (var order in _filteredOrders) {
      // Parse the order date from the created_at field
      final orderDate = DateTime.parse(order['created_at']);
      final dateGroup = _getDateGroup(orderDate);

      if (!groupedOrders.containsKey(dateGroup)) {
        groupedOrders[dateGroup] = [];
      }

      groupedOrders[dateGroup]!.add(order);
    }

    return groupedOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders'),
      ),
      body: _isLoading || _isWorkersLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by Order ID or Customer Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _filterOrders(value);
                });
              },
            ),
          ),
          // Orders list grouped by date
          Expanded(
            child: ListView(
              children: _buildGroupedOrdersList(),
            ),
          ),
        ],
      ),
    );
  }

  // Build the grouped orders list
  List<Widget> _buildGroupedOrdersList() {
    final groupedOrders = _groupOrdersByDate();
    List<Widget> orderWidgets = [];
    groupedOrders.forEach((dateGroup, orders) {
      orderWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          dateGroup,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ));

      orders.forEach((order) {
        orderWidgets.add(
          Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey),
            ),
            child: ListTile(
              title: Text('Order #${order['id']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${order['username']}'),
                  Text('Status: ${order['status']}'),
                  Text('Total: \$${order['total_price']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () {
                      _showOrderDetailsDialog(order); // Show order details in dialog
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      int orderId = int.tryParse(order['id']?.toString() ?? '0') ?? 0;
                      String? currentWorkerId = order['dw_id']?.toString(); // Ensure null safety
                      _showUpdateStatusDialog(orderId, order['status'], currentWorkerId);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      int orderId = int.tryParse(order['id']?.toString() ?? '0') ?? 0;
                      _confirmDeleteOrder(orderId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      });
    });

    return orderWidgets;
  }

  // Confirm deletion of an order
  void _confirmDeleteOrder(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this order?'),
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
                _deleteOrder(id); // Proceed with deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Delete order from the database
  Future<void> _deleteOrder(int id) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/delete_order.php'),
      body: {'order_id': id.toString()}, // Ensure 'order_id' matches PHP script
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Check if the response contains a 'success' message and handle accordingly
      if (responseData['success'] != null && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Order deleted successfully')),
        );
        _fetchOrders(); // Refresh the orders list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to delete order')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order. Server error.')),
      );
    }
  }

  void _showOrderDetailsDialog(dynamic order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Order #${order['id']} Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order['username']}', style: TextStyle(fontSize: 16)),
                Text('Status: ${order['status']}', style: TextStyle(fontSize: 16)),
                Text('Total Price: \$${order['total_price']}', style: TextStyle(fontSize: 16)),
                Text('Delivery Fee: \$${order['delivery_fee']}', style: TextStyle(fontSize: 16)),
                Text('Delivery Worker: ${order['delivery_worker']}', style: TextStyle(fontSize: 16)),
                if (order['restaurant_name'] != null)
                  Text('Restaurant: ${order['restaurant_name']}', style: TextStyle(fontSize: 16)),
                // Only show shop name if it exists
                if (order['shop_name'] != null)
                  Text('Shop: ${order['shop_name']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                for (var item in order['items'])
                  Text('${item['item_name']} (Qty: ${item['quantity']})', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text('Created At: ${DateFormat.yMMMd().format(DateTime.parse(order['created_at']))}', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }


  // Show update status dialog
  void _showUpdateStatusDialog(int id, String currentStatus, String? currentWorkerId) {
    String _selectedStatus = currentStatus;
    String? _selectedWorker;

    List<dynamic> availableWorkers = _workers;

    // Set the current worker only if it matches an available worker
    if (currentWorkerId != null && availableWorkers.any((worker) => worker['id'].toString() == currentWorkerId)) {
      _selectedWorker = currentWorkerId; // Set the current worker if it exists
    }

    // Debugging info
    print('Current Status: $currentStatus');
    print('Current Worker ID: $currentWorkerId');
    print('Available Workers: ${availableWorkers.map((w) => w['fullname']).toList()}');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Order Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current Status: $currentStatus'),
                  SizedBox(height: 10),
                  Text('Current Delivery Worker: ${_selectedWorker != null ? availableWorkers.firstWhere((worker) => worker['id'].toString() == _selectedWorker)['fullname'] : 'None'}'),
                  SizedBox(height: 10),

                  // Status Dropdown
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: <String>['pending', 'taken', 'Delivered']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue!;
                        // Reset worker if status is pending
                        if (_selectedStatus == 'pending') {
                          _selectedWorker = null; // Reset worker for 'Pending'
                        }
                      });
                    },
                  ),

                  if (_selectedStatus == 'taken' || _selectedStatus == 'Delivered') ...[
                    SizedBox(height: 10),
                    availableWorkers.isNotEmpty
                        ? DropdownButton<String>(
                      hint: Text('Select Worker'),
                      value: _selectedWorker,
                      items: availableWorkers.map<DropdownMenuItem<String>>((dynamic worker) {
                        return DropdownMenuItem<String>(
                          value: worker['id'].toString(),
                          child: Text(worker['fullname']),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedWorker = newValue;
                        });
                      },
                    )
                        : Text('No workers available'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if ((_selectedStatus == 'taken' || _selectedStatus == 'Delivered') && _selectedWorker == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a delivery worker')),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    String? workerToPass = (_selectedStatus == 'pending') ? "NULL" : _selectedWorker;
                    _updateOrderStatus(id, _selectedStatus, workerToPass);
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // Update order status and delivery worker
  Future<void> _updateOrderStatus(int orderId, String status, String? workerId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/food_ordering_api/update_order_status.php'),
      body: {
        'order_id': orderId.toString(),
        'status': status,
        'delivery_worker_id': workerId ?? '', // Use empty string if no worker selected
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated successfully')),
        );
        _fetchOrders(); // Refresh the orders list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order: ${responseData['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order. Server error.')),
      );
    }
  }

  // Filter orders based on search term
  void _filterOrders(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
      _filteredOrders = _orders.where((order) {
        return order['id'].toString().contains(searchTerm) ||
            order['username'].toString().toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    });
  }
}
