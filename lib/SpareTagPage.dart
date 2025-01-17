import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'InspectionScanPage.dart';
import 'DatabaseHelper.dart';
import 'dart:async';
//import 'dart:convert';
class SpareTagPage extends StatefulWidget {
  final String tagNumber;

  SpareTagPage({required this.tagNumber});

  @override
  _SpareTagPageState createState() => _SpareTagPageState();
}

class _SpareTagPageState extends State<SpareTagPage> {
  final TextEditingController _serialNumberController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  Timer? _connectionCheckTimer;
  // Add DatabaseHelper instance
  final DatabaseHelper dbHelper = DatabaseHelper();

  List<MapEntry<String, String>> _animatedData = [];
  Map<String, String> _details = {};
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _statusMessage;
  String userName = "";

  @override
  void initState() {
    super.initState();
    fetchUserName();
    //_startConnectionCheckTimer(); // Start periodic internet checks
  }
  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    super.dispose();
  }
  /// Fetch userName from SharedPreferences
  Future<void> fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "Unknown";
    });
    print("Fetched Technician Name: $userName");
  }
  /// Check if internet is available
  Future<bool> _isInternetAvailable() async {
    try {
      final result = await http.get(Uri.parse('https://google.com')).timeout(
        Duration(seconds: 2),
      );
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
/*  /// Save data locally in JSON format
  Future<void> _saveDataLocally(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve existing data or initialize an empty list
    List<String> localData = prefs.getStringList('offline_data') ?? [];

    // Convert the new data to JSON string
    final newDataJson = jsonEncode(data);

    // Check if the data already exists (prevent duplicates)
    if (localData.contains(newDataJson)) {
      print("Duplicate data found, skipping save: $data");
      return;
    }


    // Add the new data to the list
    localData.add(newDataJson);

    // Save the updated list back to SharedPreferences
    await prefs.setStringList('offline_data', localData);

    print("Data saved locally: $data");
    print("Current offline data count: ${localData.length}");
  }*/

  /// Search serial number and fetch details
  Future<void> _searchSerialNumber() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _details.clear();
      _animatedData.clear();
    });

    // Retrieve the company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null) {
      setState(() {
        _statusMessage = "Error: Company ID not found. Please log in again.";
        _isLoading = false;
      });
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none && await _isInternetAvailable();

    print("Connectivity Status: ${isOnline ? 'Online' : 'Offline'}");

    if (!isOnline) {
      print("Fetching data offline from SQLite...");
      final localData = await dbHelper.getDetailsBySerial(_serialNumberController.text.trim());
      if (localData != null) {
        print("Offline Data Found: $localData");
        setState(() {
          _details = {
            "Company Name": localData['company_name'] ?? 'N/A',
            "Site Name": localData['site_name'] ?? 'N/A',
            "Serial No": localData['serial_no'] ?? 'N/A',
            "Type": localData['type'] ?? 'N/A',
            "Capacity": localData['capacity']?.toString() ?? '0.0',
            "Year Of MFG": localData['year_of_mfg'] ?? 'N/A',
            "Location": localData['site_location'] ?? 'N/A',
          };
          _startAnimation();
          _statusMessage = "Data fetched from local database.";
        });
      } else {
        print("No offline data found for serial number: ${_serialNumberController.text.trim()}");
        setState(() {
          _statusMessage = "No data found offline.";
        });
      }
    } else {
      print("Fetching data online from server...");
      try {
        final response = await http.post(
          Uri.parse('https://esheapp.in/esheapp_php/spare_tag.php'),
          body: {
            'action': 'check_serial',
            'serial_no': _serialNumberController.text.trim(),
            'company_id': companyId, // Add company_id to the request
          },
        );

        if (response.statusCode == 200) {
          final responseBody = response.body;
          if (responseBody.startsWith("Error")) {
            print("Error from server: $responseBody");
            setState(() {
              _statusMessage = responseBody;
            });
          } else {
            print("Online Data Found: $responseBody");
            final details = responseBody.split('|');
            setState(() {
              _details = {
                "Company Name": details[0],
                "Site Name": details[1],
                "Serial No": details[2],
                "Type": details[3],
                "Capacity": details[4],
                "Year Of MFG": details[5],
                "Location": details[6],
              };
            });
            _startAnimation();
            // Save fetched data to local SQLite
            await dbHelper.insertTagData(
              tagNumber: details[2],
              type: details[3],
              capacity: double.tryParse(details[4]) ?? 0.0,
              companyName: details[0],
              siteName: details[1],
              siteLocation: details[6],
              serialNo: details[2],
              yearOfMfg: details[5],
              remarks: "Synced from server",
              checkinCheckout: 0,
            );
          }
        } else {
          print("Failed to fetch data from server: Status Code ${response.statusCode}");
          setState(() {
            _statusMessage = "Error: Failed to fetch data from server.";
          });
        }
      } catch (e) {
        print("Error during server fetch: $e");
        setState(() {
          _statusMessage = "Error: $e";
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }


  /// Update tag number and handle offline save
  Future<void> _updateTagNumber() async {
    if (_serialNumberController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = "Error: Serial number is required for updating.";
      });
      return;
    }

    // Retrieve the company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null) {
      setState(() {
        _statusMessage = "Error: Company ID not found. Please log in again.";
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _statusMessage = null;
    });

    final data = {
      'action': 'update_tag_number',
      'serial_no': _serialNumberController.text.trim(),
      'new_tag_number': widget.tagNumber,
      'technician_name': userName, // Use fetched userName here
      'company_id': companyId, // Add company_id to the request
    };

    final isOnline = await _isInternetAvailable();

    if (isOnline) {
      // Attempt online update
      try {
        final response = await http.post(
          Uri.parse('https://esheapp.in/esheapp_php/spare_tag.php'),
          body: data,
        );

        if (response.statusCode == 200) {
          // Show success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tag number updated successfully!"),
              duration: Duration(seconds: 3),
            ),
          );

          setState(() {
            _statusMessage = "Update successful.";
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionScanPage(), // Replace with your actual page
            ),
          );
          print("Data uploaded successfully: $data");
        } else {
          // Show error SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update: Server error."),
              duration: Duration(seconds: 3),
            ),
          );

          setState(() {
            _statusMessage = "Failed to update: Server error.";
          });
          print("Server error: ${response.statusCode}");
        }
      } catch (e) {
        // Show error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: $e"),
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _statusMessage = "Failed to update: $e";
        });
        print("Error: $e");
      }
    } else {
      // Show offline error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No network connection. Unable to update tag number."),
          duration: Duration(seconds: 3),
        ),
      );
      print("No network. Unable to update tag number.");
    }

    setState(() {
      _isUpdating = false;
    });
  }


  /// Start animation to display fetched data
  void _startAnimation() {
    for (int i = 0; i < _details.entries.length; i++) {
      Future.delayed(Duration(milliseconds: 300 * i), () {
        _animatedData.add(_details.entries.elementAt(i));
        _listKey.currentState?.insertItem(_animatedData.length - 1);
      });
    }
  }

  /// Build animated list of fetched data
  Widget _buildAnimatedList() {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      initialItemCount: _animatedData.length,
      itemBuilder: (context, index, animation) {
        if (index < _animatedData.length) {
          final entry = _animatedData[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Card(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  /// Build button with optional loading indicator
  Widget _buildButton(String label, IconData icon, VoidCallback? onPressed, bool isLoading) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Set background color to blue
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.0,
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white), // Icon color set to white
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white, // Text color set to white
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body behind the AppBar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0), // Adjusted AppBar height
        child: Container(
          margin: EdgeInsets.only(bottom: 0.0), // Add bottom margin
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20.0), // Rounded bottom corners
            ),
            child: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back), // Back button icon
                color: Colors.blue, // Icon color
                onPressed: () {
                  Navigator.pop(context); // Navigate back to the previous screen
                },
              ),
              title: Text(
                'Form',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue, // Title text color
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white, // Pure white background
              elevation: 0.0, // Subtle shadow effect
              shadowColor: Colors.black.withOpacity(0.25), // Shadow color with slight opacity
              iconTheme: IconThemeData(
                color: Colors.blue, // Icon color
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    // Notification action
                    print("Notification Icon Clicked");
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 100), // Offset for AppBar height
            SizedBox(height: 80),
            Text(
              "Technician: $userName",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color
                borderRadius: BorderRadius.circular(12), // Border radius
              ),
              padding: EdgeInsets.all(8.0), // Optional padding for better spacing
              child: Text(
                "Current Tag Number: ${widget.tagNumber}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(3, 3),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextFormField(
                controller: _serialNumberController,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: "Enter Serial No.",
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.black87),
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildButton(
              "Search",
              Icons.search,
              _isLoading ? null : _searchSerialNumber,
              _isLoading, // Pass isLoading state
            ),
            SizedBox(height: 20),
            _buildAnimatedList(),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _statusMessage!.startsWith("Success")
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildButton(
                    "Back",
                    Icons.arrow_back,
                        () => Navigator.pop(context),
                    false, // No loading for Back button
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildButton(
                    "Update",
                    Icons.update,
                    _isUpdating ? null : _updateTagNumber,
                    _isUpdating, // Pass isUpdating state
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}