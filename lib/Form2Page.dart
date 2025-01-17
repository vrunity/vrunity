import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ReviewPage.dart';
import 'DatabaseHelper.dart';
class Form2Page extends StatefulWidget {
  final String tagNumber;

  Form2Page({required this.tagNumber}); // Updated constructor name

  @override
  _Form2PageState createState() => _Form2PageState(); // Updated state class name
}

class _Form2PageState extends State<Form2Page> {
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController currentWeightPressureController = TextEditingController();
  String userName = ""; // To hold the userName from SharedPreferences
  final DatabaseHelper dbHelper = DatabaseHelper();
  Map<String, String> toggles = {
    "hose": "",
    "horn_l_bend": "",
    "valve": "",
    "obstruction_or_visibility": "",
    "op_stickers": "",
    "body_condition_or_corrosion": "",
    "pin_lock": "",
    "handle_wheelset": "",
    "location": "",
  };

  final String fetchUrl = "https://esheapp.in/esheapp_php/fetch_recent_row.php";
  final String appendUrl = "https://esheapp.in/esheapp_php/append_new_row.php";
  final String popupUrl = "https://esheapp.in/esheapp_php/form_seven_details.php";

  @override
  void initState() {
    super.initState();
    fetchRecentData();
    fetchUserName(); // Fetch userName from SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchAndShowPopup(context);
    });
  }
  Future<void> fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    print("SharedPreferences contents: ${prefs.getKeys()}"); // Debug all keys

    setState(() {
      userName = prefs.getString("user_name") ?? "Unknown";
    });

    print("Fetched userName from SharedPreferences: $userName");
  }

  Future<void> fetchAndShowPopup(BuildContext context) async {
    print("Initial tag_number: '${widget.tagNumber}'");

    final trimmedTagNumber = widget.tagNumber.trim();
    print("Trimmed tag_number: '$trimmedTagNumber'");

    if (trimmedTagNumber.isEmpty) {
      print("Error: Tag Number is missing or invalid.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tag Number is missing or invalid.")),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Check internet availability
      bool isOnline = await _isInternetAvailable();
      if (isOnline) {
        print("Network available. Fetching data online...");
        await _fetchOnlineData(context, trimmedTagNumber);
      } else {
        print("No network connection. Fetching data offline...");
        await _fetchOfflineData(context, trimmedTagNumber);
      }
    } catch (e) {
      Navigator.pop(context);
      print("Error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _fetchOnlineData(BuildContext context, String tagNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      if (companyId == null || companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Company ID is missing. Cannot fetch data.")),
        );
        return;
      }

      final payload = {
        "tag_number": tagNumber,
        "company_id": companyId,
      };

      print("Request payload: ${jsonEncode(payload)}");

      final response = await http.post(
        Uri.parse("https://esheapp.in/esheapp_php/form_seven_details.php"),
        headers: {"Content-Type": "application/json"}, // Ensure JSON content type
        body: jsonEncode(payload), // Send payload as JSON
      );

      Navigator.pop(context); // Close loading dialog

      print("Response received with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("Response body: $result");

        if (result["success"]) {
          final data = result["data"];
          print("Online data: $data");

          _showPopup(context, data, isOnline: true);

          await DatabaseHelper().insertTagData(
            tagNumber: tagNumber,
            type: data['type'] ?? '',
            capacity: double.tryParse(data['capacity']?.toString() ?? '0.0') ?? 0.0,
            checkinCheckout: data['checkin_checkout'] ?? 0,
            companyName: data['company_name'] ?? '',
            siteName: data['site_name'] ?? '',
            siteLocation: data['site_location'] ?? '',
            serialNo: data['serial_no'] ?? '',
            yearOfMfg: data['year_of_mfg'] ?? '',
            remarks: data['remarks'] ?? '',
          );
        } else {
          print("Tag number not found. Message: ${result["message"]}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result["message"] ?? "Tag number not found.")),
          );
        }
      } else {
        throw Exception("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print("Error occurred while fetching online details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching online details: $e")),
      );
    }
  }

  /// Fetch data offline
  Future<void> _fetchOfflineData(BuildContext context, String tagNumber) async {
    try {
      final localData = await dbHelper.getTagData(tagNumber);

      Navigator.pop(context); // Close loading dialog

      if (localData != null) {
        print("Offline data (sanitized): $localData");

        // Show popup with offline data
        _showPopup(context, localData, isOnline: false);
      } else {
        print("No offline data found for Tag Number: $tagNumber");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No offline data found for the given Tag Number.")),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print("Error occurred while fetching offline details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching offline details: $e")),
      );
    }
  }


  /// Show popup with fetched data
  void _showPopup(BuildContext context, Map<String, dynamic> data, {required bool isOnline}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueAccent, size: 28),
              SizedBox(width: 8),
              Text(
                isOnline ? "Tag Details (Online)" : "Tag Details (Offline)",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columnWidths: {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    _buildTableRow("Company Name", data['company_name'] ?? "N/A"),
                    _buildTableRow("Site Name", data['site_name'] ?? "N/A"),
                    _buildTableRow("Serial No", data['serial_no'] ?? "N/A"),
                    _buildTableRow("Type", data['type'] ?? "N/A"),
                    _buildTableRow("Capacity", data['capacity']?.toString() ?? "N/A"),
                    _buildTableRow("Year of Mfg", data['year_of_mfg'] ?? "N/A"),
                    _buildTableRow("Site Location", data['site_location'] ?? "N/A"),
                    _buildTableRow("Remarks", data['remarks'] ?? "N/A"),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                "OK",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Helper to build table rows
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value.isNotEmpty ? value : "N/A"),
        ),
      ],
    );
  }

  /// Check internet connectivity
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

  Future<void> fetchRecentData() async {
    try {
      // Retrieve the company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      if (companyId == null || companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Company ID is missing. Cannot fetch data.")),
        );
        return;
      }

      // Send HTTP POST request with company ID and tag number
      final response = await http.post(
        Uri.parse(fetchUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tag_number": widget.tagNumber,
          "company_id": companyId,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result["status"] == "success") {
          setState(() {
            // Update toggle values
            toggles.forEach((key, value) {
              toggles[key] = result[key] ?? "";
            });

            // Update other fields
            remarksController.text = result["remarks"] ?? "";
            currentWeightPressureController.text = result["current_weight_pressure"] ?? "";
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Data loaded successfully.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result["message"] ?? "No data found.")),
          );
        }
      } else {
        throw Exception("Failed to fetch data: HTTP ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  Future<void> appendRow() async {
    if (!_validateForm()) {
      return;
    }

    // Retrieve the company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null || companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Company ID is missing. Cannot append data.")),
      );
      return;
    }

    // Prepare the data payload
    final data = {
      "hose": toggles["hose"] ?? "",
      "horn_l_bend": toggles["horn_l_bend"] ?? "",
      "valve": toggles["valve"] ?? "",
      "obstruction_or_visibility": toggles["obstruction_or_visibility"] ?? "",
      "op_stickers": toggles["op_stickers"] ?? "",
      "body_condition_or_corrosion": toggles["body_condition_or_corrosion"] ?? "",
      "pin_lock": toggles["pin_lock"] ?? "",
      "handle_wheelset": toggles["handle_wheelset"] ?? "",
      "location": toggles["location"] ?? "",
      "remarks": remarksController.text.trim(),
      "current_weight_pressure": currentWeightPressureController.text.trim(),
      "tag_number": widget.tagNumber,
      "technician_name": userName,
      "company_id": companyId, // Include company_id for server-side matching
    };

    try {
      // Navigate to the ReviewPage
      final shouldAppend = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewPage(
            data: data,
            remarks: remarksController.text.trim(),
            currentWeightPressure: currentWeightPressureController.text.trim(),
            tagNumber: widget.tagNumber,
            technicianName: userName,
            appendUrl: "https://esheapp.in/esheapp_php/append_new_row.php", // Append URL
          ),
        ),
      );

      // Handle result from the ReviewPage
      if (shouldAppend == true) {
        // Reset form on successful append
        _resetForm();
        Navigator.pop(context); // Go back to the previous page
      } else if (shouldAppend == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Edit mode enabled. Please review and save again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  bool _validateForm() {
    for (var entry in toggles.entries) {
      if (entry.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a value for ${entry.key}")),
        );
        return false;
      }
    }

    if (remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Remarks cannot be empty")),
      );
      return false;
    }

    if (currentWeightPressureController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Current weight pressure cannot be empty")),
      );
      return false;
    }

    return true;
  }

  void _resetForm() {
    setState(() {
      toggles.updateAll((key, value) => "");
      remarksController.clear();
      currentWeightPressureController.clear();
    });
  }

  Widget buildToggle(String header) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              header,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // Set header color to white
                ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      toggles[header] = "OK";
                    });
                  },
                  child: Icon(
                    Icons.check_circle,
                    color: toggles[header] == "OK" ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                ),
                SizedBox(width: 50),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      toggles[header] = "Not OK";
                    });
                  },
                  child: Icon(
                    Icons.cancel,
                    color: toggles[header] == "Not OK" ? Colors.red : Colors.grey,
                    size: 32,
                  ),
                ),
              ],
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
                  'Form',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 150),
            Text(
              "Tag Number: ${widget.tagNumber}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            ...toggles.keys.map((key) {
              return buildToggle(key);
            }).toList(),
            SizedBox(height: 20),
            TextField(
            style: TextStyle(
            color: Colors.black,
            ),
              controller: currentWeightPressureController,
              decoration: InputDecoration(
                labelText: "Current Weight Pressure",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              style: TextStyle(
                color: Colors.black,
              ),
              controller: remarksController,
              decoration: InputDecoration(
                labelText: "Remarks",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12), // Match button's border radius
                ),
                child: ElevatedButton(
                  onPressed: appendRow,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Adjust padding for size
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Match border radius
                    ),
                    backgroundColor: Colors.transparent, // Transparent to show gradient
                    shadowColor: Colors.transparent, // Remove shadow for a clean look
                  ),
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 18, // Larger font size for better visibility
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Text color for contrast with gradient
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
