import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';

const kGoogleApiKey = 'AIzaSyCSmMgHxJoU6_RHZf9MHZQxgWPrvV1ChLc'; // Add your Google API key here

class CreateOrderScreen extends StatefulWidget {
  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _customerName = '';
  String _customerPhone = '';
  String _selectedType = '';
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _locations = [];
  int _selectedItemId = -1;
  int _selectedLocationId = -1;
  int _quantity = 1;
  String _price = '';
  bool _isLoading = false;
  LatLng _selectedLocation = LatLng(0.0, 0.0);
  LatLng _restaurantLocation = LatLng(0.0, 0.0);  // Restaurant/Shop location
  late GoogleMapController mapController;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  bool _isMapControllerInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  // Initialize the Google Maps service
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  Future<LatLng> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _fetchMenuItems() async {
    if (_selectedType.isEmpty || _selectedLocationId == -1) return;

    setState(() {
      _isLoading = true;
    });

    final apiUrl = _selectedType == 'Shop'
        ? 'http://10.0.2.2/food_ordering_api/get_shop_items.php?restaurant_id=$_selectedLocationId'
        : 'http://10.0.2.2/food_ordering_api/get_menu_items.php?restaurant_id=$_selectedLocationId';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _menuItems = data.map((item) {
            return (item as Map<String, dynamic>)..['id'] = int.tryParse(item['id'].toString()) ?? -1;
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load menu items');
      }
    } catch (e) {
      print('Error fetching menu items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLocations() async {
    if (_selectedType.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final apiUrl = _selectedType == 'Shop'
        ? 'http://10.0.2.2/food_ordering_api/get_shopss.php'
        : 'http://10.0.2.2/food_ordering_api/get_restaurantss.php';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _locations = data.map((item) {
            return (item as Map<String, dynamic>)..['id'] = int.tryParse(item['id'].toString()) ?? -1;
          }).toList();
          _isLoading = false;
          if (_locations.isNotEmpty) {
            _restaurantLocation = LatLng(
              double.tryParse(_locations[0]['latitude'].toString()) ?? 0.0,
              double.tryParse(_locations[0]['longitude'].toString()) ?? 0.0,
            );
          }
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      print('Error fetching locations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPlace() async {
    if (_searchController.text.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Search places using the Places API
      PlacesSearchResponse response = await _places.searchByText(_searchController.text);

      Navigator.pop(context);

      if (response.status != "OK" || response.results.isEmpty) {
        final errorMessage = response.status != "OK"
            ? "Places API error: ${response.status}"
            : "No places found";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        return;
      }

      // Show the list of search results
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListView.builder(
            itemCount: response.results.length,
            itemBuilder: (context, index) {
              var place = response.results[index];
              return ListTile(
                title: Text(place.name),
                subtitle: Text(place.formattedAddress ?? ''),
                onTap: () {
                  // Move camera to the selected place
                  LatLng searchedLocation = LatLng(
                    place.geometry!.location.lat,
                    place.geometry!.location.lng,
                  );

                  mapController.animateCamera(CameraUpdate.newLatLng(searchedLocation));
                  setState(() {
                    _selectedLocation = searchedLocation;
                  });

                  Navigator.pop(context);
                },
              );
            },
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      print('Error searching place: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching place')));
    }
  }



  Future<void> _createOrder() async {
    if (_formKey.currentState!.validate() && _selectedItemId != -1 && _selectedLocationId != -1) {
      setState(() {
        _isLoading = true;
      });

      String latitude = _restaurantLocation.latitude.toString();
      String longitude = _restaurantLocation.longitude.toString();

      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2/food_ordering_api/create_order.php'),
          body: {
            'type': _selectedType,
            'customer_name': _customerName,
            'customer_phone': _customerPhone,
            'price': _price,
            'item_id': _selectedItemId.toString(),
            'quantity': _quantity.toString(),
            'shop_or_restaurant_id': _selectedLocationId.toString(),
            'latitude': _selectedLocation.latitude.toString(),
            'longitude': _selectedLocation.longitude.toString(),
            'restlatitude': latitude,
            'restlongitude': longitude,
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order created successfully')));
        } else {
          throw Exception('Failed to create order');
        }
      } catch (e) {
        print('Error creating order: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating order')));
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openFullScreenMap() async {
    LatLng initialLocation = await _getCurrentLocation(); // Get current location

    // Open the full-screen map and allow the user to select a new location
    LatLng? newLocation = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        LatLng selectedLocation = initialLocation;
        Set<Marker> localMarkers = {
          Marker(
            markerId: MarkerId('initial_marker'),
            position: initialLocation,
            infoWindow: InfoWindow(title: 'Selected Location'),
          ),
        };

        GoogleMapController? mapController;

        void _moveCamera(LatLng target) {
          if (mapController != null) {
            mapController!.animateCamera(CameraUpdate.newLatLng(target));
          }
        }

        return Scaffold(

          appBar: AppBar(
            title: Text('Select Location'),
            backgroundColor: Colors.deepOrange,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for a place',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () async {
                        await _searchPlace(); // Trigger search on button press
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialLocation,
                        zoom: 14.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                      },
                      markers: localMarkers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.satellite,
                      onCameraMove: (position) {
                        // Optionally track the camera position
                      },
                      onTap: (LatLng position) {
                        setModalState(() {
                          // Clear previous markers and add the new one
                          localMarkers = {
                            Marker(
                              markerId: MarkerId('tapped_marker'),
                              position: position,
                              infoWindow: InfoWindow(title: 'Selected Location'),
                            ),
                          };
                          selectedLocation = position; // Update selected location
                          _moveCamera(position); // Move camera to tapped location
                        });
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selectedLocation); // Directly pass selected location back
                },
                child: Text('Done'),
              ),
            ],
          ),
        );
      },
    );

  // Once the modal is closed and a new location is selected, update _selectedLocation
    if (newLocation != null) {
      setState(() {
        _selectedLocation = newLocation; // Update _selectedLocation with the chosen location
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Order'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Customer Name'),
                  onChanged: (value) => _customerName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the customer\'s name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Customer Phone'),
                  onChanged: (value) => _customerPhone = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the customer\'s phone number';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedType.isNotEmpty ? _selectedType : null,
                  decoration: InputDecoration(labelText: 'Select Type (Shop/Restaurant)'),
                  items: ['Shop', 'restaurant'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      _selectedLocationId = -1;
                      _selectedItemId = -1;
                      _menuItems.clear();
                      _fetchLocations();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a location type';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<int>(
                  value: _selectedLocationId != -1 ? _selectedLocationId : null,
                  decoration: InputDecoration(labelText: 'Select Location'),
                  items: _locations.map((location) {
                    return DropdownMenuItem<int>(
                      value: location['id'],
                      child: Text(location['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocationId = value!;
                      _selectedItemId = -1;
                      _menuItems.clear();
                      _fetchMenuItems();
                    });
                  },
                  validator: (value) {
                    if (value == null || value == -1) {
                      return 'Please select a location';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<int>(
                  value: _selectedItemId != -1 ? _selectedItemId : null,
                  decoration: InputDecoration(labelText: 'Select Menu Item'),
                  items: _menuItems.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text('${item['name']}  ${item['price']}'),
                      onTap: () {
                        setState(() {
                          _price = item['price'].toString(); // Update price here
                        });
                      },
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItemId = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value == -1) {
                      return 'Please select a menu item';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty && int.tryParse(value) != null) {
                      setState(() {
                        _quantity = int.parse(value);
                      });
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: _openFullScreenMap,
                  child: Text('Open Map and Select Location'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createOrder,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Create Order'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
