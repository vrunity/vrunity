import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DatabaseHelper.dart';
import 'ExtinguisherForm.dart';
import 'Form2Page.dart';
import 'Form3Page.dart';
import 'Form5Page.dart';
import 'SpareTagWarningPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspection Scan Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InspectionScanPage(),
    );
  }
}

class InspectionScanPage extends StatefulWidget {
  @override
  _InspectionScanPageState createState() => _InspectionScanPageState();
}

class _InspectionScanPageState extends State<InspectionScanPage> {
  final TextEditingController _tagController = TextEditingController();
  String? _statusMessage;
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _syncServerData();
  }

  Future<String?> _getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('company_id');
  }

  Future<void> _syncServerData() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      print("Network Available: Syncing with Server...");
      try {
        // Get company_id using _getCompanyId
        final companyId = await _getCompanyId();

        if (companyId == null || companyId.isEmpty) {
          print("Company ID is missing. Cannot sync data.");
          return;
        }

        // Send HTTP POST request with company_id
        final response = await http.post(
          Uri.parse('https://esheapp.in/esheapp_php/server_sqllite_sync.php'),
          body: {
            'company_id': companyId,
            'action': 'fetch_data',
          },
        );

        if (response.statusCode == 200) {
          final rawResponse = response.body;
          print("Raw Response: $rawResponse");

          try {
            // Split concatenated JSON and process each part
            final parts = rawResponse.split('}{');
            final fixedParts = parts.map((part) {
              if (!part.startsWith('{')) part = '{' + part;
              if (!part.endsWith('}')) part = part + '}';
              return part;
            }).toList();

            for (final jsonString in fixedParts) {
              final result = json.decode(jsonString);
              print("Decoded JSON: $result");

              // Check the status and process data
              if (result['status'] == 'success' && result['data'] != null) {
                final List tags = result['data'];
                print("Server Response: $tags");

                await dbHelper.clearDatabase(); // Clear old data before sync
                for (var tag in tags) {
                  await dbHelper.insertTagData(
                    tagNumber: tag['tag_number'] ?? '',
                    type: tag['type'] ?? '',
                    capacity: double.tryParse(tag['capacity']?.toString() ?? '0.0') ?? 0.0,
                    companyName: tag['company_name'] ?? 'N/A',
                    siteName: tag['site_name'] ?? 'N/A',
                    siteLocation: tag['site_location'] ?? 'N/A',
                    checkinCheckout: tag['checkin_checkout'] ?? 0,
                    serialNo: tag['serial_no'] ?? 'N/A',
                    yearOfMfg: tag['year_of_mfg'] ?? 'N/A',
                    remarks: tag['remarks'] ?? 'N/A',
                  );
                }
                print("Sync successful: ${tags.length} records updated.");
              } else {
                print("Server Error: ${result['message'] ?? 'Unknown error'}");
              }
            }
          } catch (e) {
            print("Error processing server response: $e");
          }
        } else {
          print("HTTP Error: Status Code ${response.statusCode}");
        }
      } catch (e) {
        print("Error syncing with server: $e");
      }
    } else {
      print("No network connection: Using offline data.");
    }
  }
  Future<void> _submitTag(String tagNumber) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none && await _isInternetAvailable();

    print("Network Check: ${isOnline ? "Online" : "Offline"}");

    if (!isOnline) {
      // Offline mode: Query SQLite
      final data = await dbHelper.getTagData(tagNumber);
      if (data != null) {
        print("Offline Data: $data");
        _openFormBasedOnTypeAndCapacity(
          data['type'] ?? '',
          double.tryParse(data['capacity']?.toString() ?? '0.0') ?? 0.0,
          checkinCheckout: data['checkin_checkout'] ?? 0,
          tagFound: true,
        );
      } else {
        _openFormBasedOnTypeAndCapacity('', 0.0, checkinCheckout: 0, tagFound: false);
      }
    } else {
      // Online mode: Validate with PHP backend
      await _validateWithServer(tagNumber);
    }
  }


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

  Future<void> _validateWithServer(String tagNumber) async {
    try {
      // Retrieve company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      if (companyId == null || companyId.isEmpty) {
        setState(() {
          _statusMessage = 'Company ID is missing. Cannot validate.';
        });
        return;
      }

      // Send HTTP POST request with tagNumber and company_id
      final response = await http.post(
        Uri.parse('https://esheapp.in/esheapp_php/inspection_form.php'),
        body: {
          'tag_number': tagNumber,
          'company_id': companyId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final debugRecord = responseData['debug_record'];
          _openFormBasedOnTypeAndCapacity(
            debugRecord['type'] ?? '',
            double.tryParse(debugRecord['capacity']?.toString() ?? '0.0') ?? 0.0,
            checkinCheckout: debugRecord['checkin_checkout'] ?? 0,
            tagFound: true,
          );

          // Save the record to local database
          await dbHelper.insertTagData(
            tagNumber: tagNumber,
            type: debugRecord['type'] ?? '',
            capacity: double.tryParse(debugRecord['capacity']?.toString() ?? '0.0') ?? 0.0,
            companyName: debugRecord['company_name'] ?? '',
            siteName: debugRecord['site_name'] ?? '',
            siteLocation: debugRecord['site_location'] ?? '',
            checkinCheckout: debugRecord['checkin_checkout'] ?? 0,
            serialNo: debugRecord['serial_no'] ?? '',
            yearOfMfg: debugRecord['year_of_mfg'] ?? '',
            remarks: debugRecord['remarks'] ?? '',
          );
          setState(() {
            _statusMessage = 'Validation successful. Form opened.';
          });
        } else {
          _openFormBasedOnTypeAndCapacity('', 0.0, checkinCheckout: 0, tagFound: false);
          setState(() {
            _statusMessage = responseData['message'] ?? 'Tag not found.';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _openFormBasedOnTypeAndCapacity(String type, double capacity,
      {int? checkinCheckout, bool tagFound = true}) {
    if (!tagFound) {
      // Navigate to SpareTagWarningPage if the tag is not found
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpareTagWarningPage(tagNumber: _tagController.text.trim()),
        ),
      );
      return;
    }

    String form;

    if (checkinCheckout == 1) {
      form = 'form4';
    } else if (type.toUpperCase() == 'CO2') {
      form = 'form2';
    } else if (type.toUpperCase() == 'MODULAR CLEAN AGENT' ||
        type.toUpperCase() == 'MODULAR ABC') {
      form = 'form5';
    } else if (capacity > 0 && capacity <= 9) {
      form = 'form1';
    } else if (capacity > 9) {
      form = 'form3';
    } else {
      setState(() {
        _statusMessage = 'Invalid data: Unable to determine form.';
      });
      return;
    }

    _openForm(form, tagNumber: _tagController.text.trim());
  }

  void _openForm(String form, {String? tagNumber}) {
    _tagController.clear();

    if (form == 'form1') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ExtinguisherFormPage(
                  tagNumber: tagNumber ?? ''), // Pass tagNumber
        ),
      );
    } else if (form == 'form2') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Form2Page(tagNumber: tagNumber ?? ''),
        ),
      );
    } else if (form == 'form3') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Form3Page(tagNumber: tagNumber ?? ''),
        ),
      );
    }
    else if (form == 'form5') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Form5Page(tagNumber: tagNumber ?? ''),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0), // Adjusted AppBar height
        child: Container(
          margin: EdgeInsets.only(bottom: 0.0), // Add bottom margin
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20.0), // Rounded bottom corners
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back), // Back button icon
                  color: Colors.white, // Updated icon color for better contrast
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to the previous screen
                  },
                ),
                title: Text(
                  'Inspection Scan',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // Updated title text color for better contrast
                    fontWeight: FontWeight.bold, // Bold text for emphasis
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent, // Transparent to show gradient
                elevation: 0.0, // Subtle shadow effect
                shadowColor: Colors.black.withOpacity(0.25), // Shadow color with slight opacity
                iconTheme: IconThemeData(
                  color: Colors.white, // Updated icon color for better contrast
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    color: Colors.white, // Updated notification icon color for better contrast
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
      ),
      body: Container(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Field
                TextField(
                  controller: _tagController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  onChanged: (value) {
                    if (value.length == 10 &&
                        RegExp(r'^\d{10}$').hasMatch(value)) {
                      _submitTag(value);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter 10-digit RFID Tag Number',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white, // Adjusted for visibility
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  style: TextStyle(color: Colors.black),
                ),

                // Error Message
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Instructions Card
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Instructions",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInstruction(
                            "Read or Enter RFID Number:",
                            "Tap the text box to scan with the RFID Reader or manually enter a 10-digit RFID number.",
                          ),
                          _buildInstruction(
                            "Attach RFID Reader:",
                            "Connect the RFID Reader to your mobile device.",
                          ),
                          _buildInstruction(
                            "Position Reader:",
                            "Check the LED indicator, then hold the reader over the RFID Tag on the fire extinguisher.",
                          ),
                          _buildInstruction(
                            "Automatic Detection:",
                            "If the RFID number is detected, you will be taken to the next page.",
                          ),
                          _buildInstruction(
                            "Manual Entry Option:",
                            "If the LED does not light up, or if your mobile device is not supported, enter the 10-digit RFID number manually.",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


// Helper method to build each instruction
  Widget _buildInstruction(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$title ",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: description,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
