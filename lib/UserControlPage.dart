import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'useraccesspage.dart'; // Import the User Access Page
import 'package:shared_preferences/shared_preferences.dart';
class UserControlPage extends StatefulWidget {
  @override
  _UserControlPageState createState() => _UserControlPageState();
}

class _UserControlPageState extends State<UserControlPage> {
  String? _selectedAdmin = "Select Admin";
  String? _selectedUser = "Select Technician";
  String? _selectedPending = "Select Pending";

  List<String> adminList = ["Select Admin"];
  List<String> userList = ["Select Technician"];
  List<String> pendingList = ["Select Pending"];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }
  Future<void> _fetchDropdownData() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/approval_list.php";

    // Retrieve company_id from SharedPreferences
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
          'request_type': 'get_user_admin_lists',
          'company_id': companyId, // Include company_id in the request
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          adminList = ["Select Admin", ...List<String>.from(data['adminList'] ?? [])];
          userList = ["Select Technician", ...List<String>.from(data['userList'] ?? [])];
          pendingList = ["Select Pending", ...List<String>.from(data['pendingList'] ?? [])];
          _isLoading = false;
        });
      } else {
        _showErrorMessage("Failed to fetch dropdown data.");
      }
    } catch (e) {
      _showErrorMessage("An error occurred. Please check your connection.");
    }
  }


  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleApproval() {
    String selectedName = _selectedAdmin != "Select Admin"
        ? _selectedAdmin!
        : _selectedUser != "Select Technician"
        ? _selectedUser!
        : _selectedPending != "Select Pending"
        ? _selectedPending!
        : "";

    if (selectedName.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserAccessPage(
            selectedName: selectedName,
            onUserRejected: _removeUserFromDropdown,
           // onUserApproved: _removeUserFromDropdown,
          ),
        ),
      );
    } else {
      _showErrorMessage("Please select a value from any dropdown before proceeding.");
    }
  }

  void _removeUserFromDropdown(String userName) {
    setState(() {
      adminList.remove(userName);
      userList.remove(userName);
      pendingList.remove(userName);
      if (_selectedAdmin == userName) _selectedAdmin = "Select Admin";
      if (_selectedUser == userName) _selectedUser = "Select Technician";
      if (_selectedPending == userName) _selectedPending = "Select Pending";
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
                  'User Control',
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                SizedBox(height: 40),
                // Admin List Dropdown
                _buildScrollableDropdown("Admin list", adminList, _selectedAdmin, (value) {
                  setState(() {
                    _selectedAdmin = value;
                    _selectedUser = "Select Technician";
                    _selectedPending = "Select Pending";
                  });
                }),
                SizedBox(height: 20),
                // User List Dropdown
                _buildScrollableDropdown("User list", userList, _selectedUser, (value) {
                  setState(() {
                    _selectedUser = value;
                    _selectedAdmin = "Select Admin";
                    _selectedPending = "Select Pending";
                  });
                }),
                SizedBox(height: 20),
                // Pending List Dropdown
                _buildScrollableDropdown("Pending", pendingList, _selectedPending, (value) {
                  setState(() {
                    _selectedPending = value;
                    _selectedAdmin = "Select Admin";
                    _selectedUser = "Select Technician";
                  });
                }),
                SizedBox(height: 40),
                // Approval Button
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
                    onPressed: _handleApproval,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                      backgroundColor: Colors.transparent, // Transparent to show gradient
                      shadowColor: Colors.transparent, // Remove default shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Match button radius
                      ),
                    ),
                    child: Text(
                      "Approval",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // Text color for contrast
                        fontWeight: FontWeight.bold, // Bold text for emphasis
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

  Widget _buildScrollableDropdown(
      String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(item),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true, // Allows dropdown to use the full width
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}
