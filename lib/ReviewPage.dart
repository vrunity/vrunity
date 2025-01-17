import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'InspectionScanPage.dart';

class ReviewPage extends StatefulWidget {
  final Map<String, String> data;
  final String remarks;
  final String currentWeightPressure;
  final String tagNumber;
  final String technicianName;
  final String appendUrl;
  final void Function(BuildContext)? onSendSuccess; // Add this line
  ReviewPage({
    required this.data,
    required this.remarks,
    required this.currentWeightPressure,
    required this.tagNumber,
    required this.technicianName,
    required this.appendUrl,
    this.onSendSuccess, // Include this parameter in the constructor
  });

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final List<MapEntry<String, String>> _animatedData = [];
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(Duration(milliseconds: 300), () {
      for (int i = 0; i < widget.data.entries.length; i++) {
        Future.delayed(Duration(milliseconds: 300 * i), () {
          _animatedData.add(widget.data.entries.elementAt(i));
          _listKey.currentState?.insertItem(_animatedData.length - 1);
          if (i == widget.data.entries.length - 1) {
            setState(() {
              _isAnimationComplete = true;
            });
          }
        });
      }
    });
  }

  /// Check internet connectivity
  Future<bool> _isInternetAvailable() async {
    try {
      final response = await http.get(Uri.parse('https://google.com')).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Save data locally with feedback
  Future<void> _saveDataLocally(Map<String, dynamic> data) async {
    // Retrieve company_id using _getCompanyId
    final companyId = await _getCompanyId();

    if (companyId == null || companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Company ID is missing. Cannot save data locally.")),
      );
      return;
    }

    // Add company_id to the data payload
    data["company_id"] = companyId;

    final prefs = await SharedPreferences.getInstance();
    List<String> savedData = prefs.getStringList('offline_data') ?? [];
    savedData.add(jsonEncode(data));
    await prefs.setStringList('offline_data', savedData);

    print("Local Saved Data (${savedData.length} entries):");
    for (var jsonString in savedData) {
      print(jsonDecode(jsonString));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data saved offline successfully.")),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => InspectionScanPage()),
          (route) => false,
    );
  }

  /// Append data to the server
  Future<void> appendData(BuildContext context) async {
    // Retrieve company_id using _getCompanyId
    final companyId = await _getCompanyId();

    if (companyId == null || companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Company ID is missing. Cannot append data.")),
      );
      return;
    }

    // Prepare the payload with company_id
    final payload = {
      ...widget.data,
      "remarks": widget.remarks,
      "current_weight_pressure": widget.currentWeightPressure,
      "tag_number": widget.tagNumber,
      "technician_name": widget.technicianName,
      // "company_id": companyId, // Include company_id
    };

    if (await _isInternetAvailable()) {
      try {
        final response = await http.post(
          Uri.parse(widget.appendUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);

          if (result["status"] == "success") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Data appended successfully!")),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => InspectionScanPage()),
                  (route) => false,
            );
          } else {
            throw Exception(result["message"] ?? "Error appending row.");
          }
        } else {
          throw Exception("HTTP Error: ${response.statusCode}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e. Saving data locally.")),
        );
        await _saveDataLocally(payload);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No internet. Saving data locally.")),
      );
      await _saveDataLocally(payload);
    }
  }

  /// Retrieve company ID from SharedPreferences
  Future<String?> _getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('company_id');
  }

  // Sync offline data safely
  Future<void> syncOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedData = prefs.getStringList('offline_data') ?? [];

    if (savedData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No offline data to sync.")),
        );
      }
      return;
    }

    if (await _isInternetAvailable()) {
      List<String> unsyncedData = [];

      for (String jsonString in savedData) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonString);

          // Ensure company_id is included in the payload
          final companyId = await _getCompanyId();
          if (companyId == null || companyId.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Company ID is missing. Cannot sync data.")),
              );
            }
            return;
          }
          data["company_id"] = companyId;

          // Send data to the server
          final response = await http.post(
            Uri.parse(widget.appendUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(data),
          );

          if (response.statusCode == 200) {
            final result = jsonDecode(response.body);
            if (result["status"] != "success") {
              unsyncedData.add(jsonString); // Keep unsynced data
            }
          } else {
            unsyncedData.add(jsonString); // Keep unsynced data
          }
        } catch (_) {
          unsyncedData.add(jsonString); // Keep unsynced data
        }
      }

      // Update the offline data
      if (unsyncedData.isEmpty) {
        await prefs.remove('offline_data');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("All offline data synced successfully.")),
          );
        }
      } else {
        await prefs.setStringList('offline_data', unsyncedData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Some data could not be synced. Retrying later.")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No network. Unable to sync offline data.")),
        );
      }
    }
  }

  Widget _buildRow(MapEntry<String, String> entry, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            title: Text(
              entry.key,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            subtitle: Text(entry.value, style: TextStyle(color: Colors.black)),
          ),
        ),
      ),
    );
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
                  'Review',
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
        physics: BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tag Number: ${widget.tagNumber}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Technician Name: ${widget.technicianName}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              initialItemCount: _animatedData.length,
              itemBuilder: (context, index, animation) {
                return _buildRow(_animatedData[index], animation);
              },
            ),
            if (_isAnimationComplete) ...[
              SizedBox(height: 20),
              Text(
                "Current Weight Pressure: ${widget.currentWeightPressure}",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                "Remarks: ${widget.remarks}",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 30),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20), // Match button radius
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Transparent for gradient
                          shadowColor: Colors.transparent, // Remove shadow
                          elevation: 5, // Button elevation
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(Icons.edit, color: Colors.white),
                        label: Text(
                          "Edit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 16), // Add space between buttons
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20), // Match button radius
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await appendData(context);
                          await syncOfflineData(); // Sync offline data after append
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Transparent for gradient
                          shadowColor: Colors.transparent, // Remove shadow
                          elevation: 5, // Button elevation
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(Icons.send, color: Colors.white),
                        label: Text(
                          "Send",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],

                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
