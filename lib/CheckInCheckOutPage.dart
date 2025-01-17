import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckInCheckoutPage extends StatefulWidget {
  @override
  _CheckInCheckoutPageState createState() => _CheckInCheckoutPageState();
}

class _CheckInCheckoutPageState extends State<CheckInCheckoutPage> {
  final TextEditingController tagNumberController = TextEditingController();
  Map<String, dynamic>? fetchedData;
  bool isCheckIn = true;
  String technicianName = "";
  String? selectedReason;
  String CompanyId = ''; // Default or fetched from a dropdown
  final List<String> reasons = ["Maintenance", "HPT", "Refilling"];

// Animation-related variables
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<MapEntry<String, String>> _animatedData = [];
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }
  Future<String?> _getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('company_id');
  }


  Future<void> fetchUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        technicianName = prefs.getString("user_name") ?? "Unknown";
      });
      print("Fetched Technician Name: $technicianName");
    } catch (e) {
      print("Error fetching username from SharedPreferences: $e");
    }
  }

  Future<void> fetchTagDetails(String companyId, String tagNumber) async {
    try {
      final response = await http.post(
        Uri.parse('https://esheapp.in/esheapp_php/checkin_checkout.php'),
        body: {
          'action': 'fetch',
          'company_id': companyId,
          'tag_number': tagNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          showError(data['error']);
        } else {
          setState(() {
            fetchedData = data;
          });
          // Filter and animate the fetched data
          final filteredData = getFilteredData(data);
          _resetAndAnimateTable(filteredData);
        }
      } else {
        showError("Failed to fetch data. Server responded with ${response.statusCode}");
      }
    } catch (e) {
      showError("An error occurred: $e");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Map<String, String> getFilteredData(Map<String, dynamic> data) {
    const requiredHeaders = [
      'company_name',
      'site_name',
      'serial_no',
      'type',
      'capacity',
      'year_of_mfg',
      'site_location',
      'checkin',
      'checkout',
      'checkout_reason'
    ];

    // Filter and convert to Map<String, String>
    return Map.fromEntries(
      data.entries
          .where((entry) => requiredHeaders.contains(entry.key))
          .map((entry) => MapEntry(entry.key, entry.value?.toString() ?? "N/A")),
    );
  }

  Future<void> uploadData(String companyId) async {
    if (fetchedData == null) {
      showError("No data to upload.");
      return;
    }

    final currentCheckinCheckout = fetchedData!['checkin_checkout'];

    if (isCheckIn && currentCheckinCheckout == 0) {
      showError("Already checked in.");
      return;
    }

    if (!isCheckIn && currentCheckinCheckout == 1) {
      showError("Already checked out.");
      return;
    }

    if (!isCheckIn && (selectedReason == null || selectedReason!.isEmpty)) {
      showError("Please provide a reason for Check-Out.");
      return;
    }

    final currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    fetchedData!['checkin_checkout'] = isCheckIn ? 0 : 1;
    fetchedData!['checkin'] = isCheckIn ? currentDate : fetchedData!['checkin'];
    fetchedData!['checkout'] = isCheckIn ? fetchedData!['checkout'] : currentDate;
    fetchedData!['date_time'] = currentDateTime;
    fetchedData!['technician_name'] = technicianName;

    if (!isCheckIn) {
      fetchedData!['checkout_reason'] = selectedReason;
    }

    final mergedData = {...fetchedData!};

    try {
      final response = await http.post(
        Uri.parse('https://esheapp.in/esheapp_php/checkin_checkout.php'),
        body: {
          'action': 'insert',
          'company_id': companyId,
          'modified_data': jsonEncode(mergedData),
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['error'] != null) {
          showError(result['error']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['success'] ?? "Data uploaded successfully")),
          );

          resetPage();

          print("Upload successful: ${result['success']}");
        }
      } else {
        showError("Failed to upload data. Server responded with ${response.statusCode}");
      }
    } catch (e) {
      showError("An error occurred: $e");
    }
  }

  void resetPage() {
    setState(() {
      tagNumberController.clear(); // Clear the tag number input field
      fetchedData = null; // Reset fetched data
      _animatedData.clear(); // Clear animated list data
      isCheckIn = true; // Reset toggle to default (Check-In)
      selectedReason = null; // Reset reason dropdown
      _isAnimationComplete = false; // Reset animation state
    });
  }

  void _resetAndAnimateTable(Map<String, String> data) {
    // Clear existing data and reset UI
    setState(() {
      _animatedData.clear();
      _isAnimationComplete = false;
    });

    // Delay before animating the new data
    Future.delayed(Duration(milliseconds: 300), () {
      final dataEntries = data.entries.toList();
      for (int i = 0; i < dataEntries.length; i++) {
        Future.delayed(Duration(milliseconds: 300 * i), () {
          if (mounted && i < dataEntries.length) {
            setState(() {
              _animatedData.add(dataEntries[i]);
              if (_listKey.currentState != null) {
                _listKey.currentState!.insertItem(_animatedData.length - 1);
              }
              if (i == dataEntries.length - 1) {
                _isAnimationComplete = true;
              }
            });
          }
        });
      }
    });
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
                    'CheckIn-CheckOut',
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
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       Color(0xFF4A00E0), // Start color
        //       Color(0xFF8E2DE2), // End color
        //     ],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  style: TextStyle(
                    color: Colors.black, // Set the text color to black
                  ),
                  controller: tagNumberController,
                  decoration: InputDecoration(
                    labelText: "Tag Number",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Minimize space usage vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // Align children to the center horizontally
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30), // Match button radius
                        ),
                        child:  ElevatedButton(
                          onPressed: () async {
                            final companyId = await _getCompanyId();
                            if (companyId != null) {
                              fetchTagDetails(companyId, tagNumberController.text);
                            } else {
                              showError("No company ID found. Please set it first.");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16), // Spacing between button and text
                      // Text(
                      //   "Details:",
                      //   style: TextStyle(
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 16,
                      //     color: Colors.white, // Text color
                      //   ),
                      //   textAlign: TextAlign.center, // Align text in the center
                      // ),
                    ],
                  ),
                ),

                AnimatedList(
                  key: _listKey,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  initialItemCount: _animatedData.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= _animatedData.length) {
                      return SizedBox.shrink();
                    }
                    final entry = _animatedData[index];
                    return SizeTransition(
                      sizeFactor: animation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Background color
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5), // Shadow color
                                spreadRadius: 2, // Spread radius
                                blurRadius: 4, // Blur radius
                                offset: Offset(0, 2), // Shadow position (x, y)
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Text(
                                  "${entry.key}: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text(entry.value),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Background color
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey, width: 1),// Optional: Add rounded corners
                          ),
                          child: RadioListTile(
                            title: Text(
                              "Check-In",
                              style: TextStyle(color: Colors.black), // Text color
                            ),
                            value: true,
                            groupValue: isCheckIn,
                            onChanged: (value) {
                              setState(() {
                                isCheckIn = value as bool;
                                selectedReason = null;
                              });
                            },
                            activeColor: Colors.red, // Radio button active color
                          ),
                        ),
                        SizedBox(height: 16), // Add padding between the buttons
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Background color
                            borderRadius: BorderRadius.circular(8), // Optional: Rounded corners
                            border: Border.all(color: Colors.grey, width: 1), // Optional: Border styling
                          ),
                          child: RadioListTile(
                            title: Text(
                              "Check-Out",
                              style: TextStyle(
                                color: Colors.black, // Text color based on selection
                              ),
                            ),
                            value: false,
                            groupValue: isCheckIn,
                            onChanged: (value) {
                              setState(() {
                                isCheckIn = value as bool;
                              });
                            },
                            activeColor: Colors.red, // Color of the selected radio button
                          ),
                        ),
                      ],
                    ),


                    if (!isCheckIn)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0), // Add top padding
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Reason for Check-Out",
                            border: OutlineInputBorder(),
                          ),
                          value: selectedReason,
                          items: reasons.map((reason) {
                            return DropdownMenuItem(
                              value: reason,
                              child: Text(reason),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value;
                            });
                          },
                        ),
                      ),

                  ],
                ),
                SizedBox(height: 16),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                    child:  ElevatedButton(
                      onPressed: () async {
                        final companyId = await _getCompanyId();
                        if (companyId != null) {
                          uploadData(companyId);
                        } else {
                          showError("No company ID found. Please set it first.");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        "Upload",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
}
