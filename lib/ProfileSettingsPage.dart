import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsPage extends StatefulWidget {
  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController userTypeController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final String url = 'https://esheapp.in/esheapp_php/profile_settings_Fetchdetails.php'; // Replace with your PHP script URL

    try {
      // Retrieve credentials from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? savedPhone = prefs.getString('phone_number');
      final String? savedPassword = prefs.getString('password');
      final String? companyId = prefs.getString('company_id');

      if (savedPhone == null || savedPassword == null || companyId == null) {
        showError("Missing saved credentials.");
        return;
      }

      // Send POST request to fetch user details
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'phone_number': savedPhone,
          'password': savedPassword,
          'company_id': companyId,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      // Print server response
      print("Server Response (fetchUserDetails): ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            userDetails = data['data'];
            nameController.text = userDetails!['name'];
            userTypeController.text = userDetails!['user_type'];
            companyNameController.text = userDetails!['company_name'];
            designationController.text = userDetails!['designation'];
            isLoading = false;
          });
        } else {
          showError(data['message']);
        }
      } else {
        showError("Failed to load user details.");
      }
    } catch (error) {
      showError(error.toString());
    }
  }


  Future<void> saveUpdatedDetails() async {
    final String url = 'https://esheapp.in/esheapp_php/update_settings_user_details.php'; // Replace with your PHP script URL

    try {
      // Retrieve company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? companyId = prefs.getString('company_id');

      if (companyId == null) {
        showError("Missing company ID.");
        return;
      }

      // Send POST request to update user details
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'phone_number': userDetails!['phone_number'],
          'company_id': companyId,
          'name': nameController.text,
          'user_type': userTypeController.text,
          'company_name': companyNameController.text,
          'designation': designationController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      // Print server response
      print("Server Response (saveUpdatedDetails): ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User details updated successfully!')),
          );
          fetchUserDetails(); // Refresh user details
        } else {
          showError(data['message']);
        }
      } else {
        showError("Failed to update user details.");
      }
    } catch (error) {
      showError(error.toString());
    }
  }


  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEditableField('Name', nameController),
            _buildEditableField('User Type', userTypeController),
            _buildEditableField('Company Name', companyNameController),
            _buildEditableField('Designation', designationController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveUpdatedDetails,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: Colors.black), // Text color is black
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(color: Colors.grey), // Label text color
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Focus the text field for editing
              },
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
