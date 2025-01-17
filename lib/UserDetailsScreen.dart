import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(UserDataApp());

class UserDataApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserDetailsScreen(),
    );
  }
}

class UserDetailsScreen extends StatefulWidget {
  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final String url = 'https://esheapp.in/esheapp_php/user_profile_page.php'; // Replace with your PHP script URL

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

      // Send POST request with phone_number, password, and company_id
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'phone_number': savedPhone,
          'password': savedPassword,
          'company_id': companyId,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            userDetails = data['data'];
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

  void showError(String message) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Details"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userDetails == null
          ? Center(child: Text("No user details found"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(
                userDetails!['name'][0].toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            title: Text(userDetails!['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User Type: ${userDetails!['user_type']}"),
                Text("Company: ${userDetails!['company_name']}"),
                Text("Phone: ${userDetails!['phone_number']}"),
                Text("Designation: ${userDetails!['designation']}"),
                Text("Company ID: ${userDetails!['company_id']}"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
