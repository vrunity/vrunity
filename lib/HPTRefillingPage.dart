import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HPTRefillingPage extends StatefulWidget {
  @override
  _HPTRefillingPageState createState() => _HPTRefillingPageState();
}

class _HPTRefillingPageState extends State<HPTRefillingPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController tagNumberController = TextEditingController();
  final TextEditingController currentWeightController = TextEditingController();
  bool isRefillingSelected = false;
  bool isHPTSelected = false;
  Map<String, dynamic>? extinguisherData;
  String userName = ""; // Technician's name from SharedPreferences

  late AnimationController _controller;
  List<MapEntry<String, dynamic>> _animatedData = [];
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    fetchUserName();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "";
    });
  }
  Future<void> fetchExtinguisherDetails(String tagNumber) async {
    const String url = 'https://esheapp.in/esheapp_php/HPT_Refilling_page_details.php';

    try {
      // Retrieve company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      if (companyId == null || companyId.isEmpty) {
        showMessage('Company ID is missing. Cannot fetch details.');
        return;
      }

      // Prepare the request payload
      final Map<String, dynamic> payload = {
        'tag_number': tagNumber,
        'company_id': companyId,
      };

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      // Handle the response
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          // Update the UI with fetched data
          setState(() {
            extinguisherData = data['data'];
            _animatedData.clear(); // Clear previous data
            _listKey = GlobalKey<AnimatedListState>(); // Reset key
            _startAnimation();
          });

          // Show success message
          showMessage('Details loaded successfully.');
        } else {
          // Show server-provided error message
          showMessage(data['message'] ?? 'Failed to fetch details.');
        }
      } else {
        // Handle HTTP error
        showMessage('Failed to fetch details: HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Handle unexpected errors
      showMessage('Error: $e');
    }
  }

  void _startAnimation() {
    Future.delayed(Duration(milliseconds: 300), () {
      final entries = extinguisherData?.entries.toList() ?? [];
      for (int i = 0; i < entries.length; i++) {
        Future.delayed(Duration(milliseconds: 300 * i), () {
          setState(() {
            _animatedData.add(entries[i]);
          });
          _listKey.currentState?.insertItem(_animatedData.length - 1);
        });
      }
    });
  }

  Future<void> updateExtinguisherDetails() async {
    if (extinguisherData == null) {
      showMessage('Please fetch extinguisher details first.');
      return;
    }

    if (currentWeightController.text.isEmpty) {
      showMessage('Please fill the current weight/pressure field.');
      return;
    }

    if (!isRefillingSelected && !isHPTSelected) {
      showMessage('Please select either Refilling or HPT before uploading.');
      return;
    }

    const String url = 'https://esheapp.in/esheapp_php/hpt_refilling_settings.php';

    // Fetch `company_id` from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? companyId = prefs.getString('company_id');

    if (companyId == null || companyId.isEmpty) {
      showMessage('Company ID is missing. Cannot proceed.');
      return;
    }

    final String? hptDate = isHPTSelected ? DateTime.now().toIso8601String().split("T")[0] : null;
    final String? refillingDate = isRefillingSelected || isHPTSelected
        ? DateTime.now().toIso8601String().split("T")[0]
        : null;

    final uploadDetails = {
      'tag_number': tagNumberController.text,
      'current_weight_pressure': currentWeightController.text,
      'refilling_date': refillingDate ?? "",
      'hpt_date': hptDate ?? "",
      'technician_name': userName,
      'company_id': companyId, // Add company_id to the payload
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        body: uploadDetails,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showMessage(data['message'] ?? 'Details uploaded successfully.');
      } else {
        showMessage('Failed to update details. Try again.');
      }
    } catch (e) {
      showMessage('Error: $e');
    }
  }


  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  'HPT and Refilling',
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              style: const TextStyle(
                color: Colors.black,
              ),
              controller: tagNumberController,
              decoration: const InputDecoration(
                labelText: 'Enter 10-digit Tag Number',
                border: OutlineInputBorder(),
              ),
              maxLength: 10,
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                if (value.length == 10) {
                  fetchExtinguisherDetails(value);
                } else {
                  showMessage('Please enter a valid 10-digit tag number.');
                }
              },
            ),
            const SizedBox(height: 20),
            extinguisherData != null
                ? Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    color: Colors.white,
                  ),
                  height: 300.0,
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: _animatedData.length,
                    itemBuilder: (context, index, animation) {
                      final entry = _animatedData[index];
                      return SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(0.0, 0.5),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOut)),
                        ),
                        child: ListTile(
                          title: Text(entry.key),
                          subtitle: Text(entry.value.toString()),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black, // Title text color
                  ),
                  controller: currentWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Current Weight / Current Pressure',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // White background color
                    borderRadius: BorderRadius.circular(12), // Optional: Add rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5), // Add shadow for depth
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16), // Add padding inside the container
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Refilling'),
                        leading: Radio<bool>(
                          value: true,
                          groupValue: isRefillingSelected,
                          activeColor: Colors.red, // Set selected color to red
                          onChanged: (value) {
                            setState(() {
                              isRefillingSelected = value!;
                              isHPTSelected = !value;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('HPT'),
                        leading: Radio<bool>(
                          value: true,
                          groupValue: isHPTSelected,
                          activeColor: Colors.red, // Set selected color to red
                          onChanged: (value) {
                            setState(() {
                              isHPTSelected = value!;
                              isRefillingSelected = !value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20), // Match button radius
                  ),
                  child: ElevatedButton(
                    onPressed: updateExtinguisherDetails,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                      backgroundColor: Colors.transparent, // Transparent for gradient
                      shadowColor: Colors.transparent, // Remove shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Match button radius
                      ),
                    ),
                    child: Text(
                      "Update",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color for contrast with gradient
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}