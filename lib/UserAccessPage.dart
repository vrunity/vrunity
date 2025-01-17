import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class UserAccessPage extends StatefulWidget {
  final String selectedName;
  final Function(String) onUserRejected; // Callback function for user rejection

  UserAccessPage({required this.selectedName, required this.onUserRejected});

  @override
  _UserAccessPageState createState() => _UserAccessPageState();
}

class _UserAccessPageState extends State<UserAccessPage> {
  Map<String, dynamic> userDetails = {};
  bool isLoading = true;

  // Toggle states
  bool isServiceEnabled = false;
  bool isHPTEnabled = false;
  bool isNewEntryEnabled = false;
  bool isCheckinCheckoutEnabled = false; // New toggle state

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/get_user_details.php";

    // Retrieve company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null) {
      _showErrorMessage("Company ID not found. Please log in again.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$apiUrl?user_name=${widget.selectedName}&company_id=$companyId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] == null) {
          setState(() {
            userDetails = data;
            isLoading = false;
          });
        } else {
          _showErrorMessage(data['error']);
        }
      } else {
        _showErrorMessage("Failed to fetch user details.");
      }
    } catch (e) {
      _showErrorMessage("An error occurred. Please check your connection.");
    }
  }


  Future<void> _sendApproval() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/save_approval.php";

    // Retrieve the company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null) {
      _showErrorMessage("Company ID not found. Please log in again.");
      return;
    }

    // Generate approval code based on toggles
    int approvalCode = 0;
    if (isServiceEnabled) approvalCode += 1; // Service toggle gives 1
    if (isHPTEnabled) approvalCode += 2; // HPT toggle gives 2
    if (isNewEntryEnabled) approvalCode += 4; // New Entry toggle gives 4
    if (isCheckinCheckoutEnabled) approvalCode += 16; // Checkin_Checkout toggle gives 16

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'user_name': widget.selectedName,
          'approval_code': approvalCode.toString(),
          'company_id': companyId, // Include company_id in the request
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == null) {
          _showSuccessMessage(data['message'] ?? "Approval updated successfully.");
        } else {
          _showErrorMessage(data['error']);
        }
      } else {
        _showErrorMessage("Failed to send approval data.");
      }
    } catch (e) {
      _showErrorMessage("An error occurred. Please check your connection.");
    }
  }


  Future<void> _rejectUser() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/reject_user.php"; // Replace with your PHP script URL

    // Retrieve the company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null) {
      _showErrorMessage("Company ID not found. Please log in again.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'user_name': widget.selectedName,
          'company_id': companyId, // Include company_id in the request
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == null) {
          _showSuccessMessage(data['message'] ?? "User rejected successfully.");
          widget.onUserRejected(widget.selectedName); // Call the rejection callback
          Navigator.pop(context); // Close the page after rejection
        } else {
          _showErrorMessage(data['error']);
        }
      } else {
        _showErrorMessage("Failed to reject user.");
      }
    } catch (e) {
      _showErrorMessage("An error occurred. Please check your connection.");
    }
  }


  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Rejection"),
        content: Text("Are you sure you want to reject this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectUser();
            },
            child: Text("Reject"),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
                  'User Approval',
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
        //   color: Colors.deepPurpleAccent, // Set a single color (Violet in this case)
        // ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                // User Details
                _buildDetailRow("User Name", userDetails['name'] ?? "N/A"),
                _buildDetailRow("Phone Number", userDetails['phone_number'] ?? "N/A"),
                _buildDetailRow("Company Name", userDetails['company_name'] ?? "N/A"),
                _buildDetailRow("Designation", userDetails['designation'] ?? "N/A"),
                _buildDetailRow("User Type", userDetails['user_type'] ?? "N/A"),
                SizedBox(height: 20),
                // User Authentication Toggles
                _buildAuthenticationToggles(),
                SizedBox(height: 30),
                // Approve and Reject Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Approve Button with Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12), // Match button's border radius
                      ),
                      child: ElevatedButton(
                        onPressed: _sendApproval,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                          backgroundColor: Colors.transparent, // Transparent for gradient
                          shadowColor: Colors.transparent, // Remove shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Match container's border radius
                          ),
                        ),
                        child: Text(
                          "Approve",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white, // Text color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16), // Spacing between buttons
                    // Reject Button with Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12), // Match button's border radius
                      ),
                      child: ElevatedButton(
                        onPressed: _showConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                          backgroundColor: Colors.transparent, // Transparent for gradient
                          shadowColor: Colors.transparent, // Remove shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Match container's border radius
                          ),
                        ),
                        child: Text(
                          "Reject",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white, // Text color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background color
        borderRadius: BorderRadius.circular(8), // Optional rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8.0), // Padding inside the container
      margin: const EdgeInsets.symmetric(vertical: 4.0), // Space between rows
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1), // Adjust label column width
          1: FlexColumnWidth(2), // Adjust value column width
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              Align(
                alignment: Alignment.centerLeft, // Left-align column 1
                child: Text(
                  "$label:",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue, // Black text color for labels
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight, // Right-align column 2
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Black text color for values
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildAuthenticationToggles() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "User Authentication",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          _buildToggle("Service", isServiceEnabled, (value) {
            setState(() {
              isServiceEnabled = value;
            });
          }),
          _buildToggle("HPT", isHPTEnabled, (value) {
            setState(() {
              isHPTEnabled = value;
            });
          }),
          _buildToggle("New Entry", isNewEntryEnabled, (value) {
            setState(() {
              isNewEntryEnabled = value;
            });
          }),
          _buildToggle("Checkin_Checkout", isCheckinCheckoutEnabled, (value) {
            setState(() {
              isCheckinCheckoutEnabled = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.blue,
        ),
      ],
    );
  }
}