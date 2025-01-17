import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'loginpage.dart'; // Import the LoginPage
import 'approvalpendingpage.dart'; // Import the ApprovalPendingPage

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyIdController = TextEditingController(); // Controller for company_id
  String _userType = "Technician"; // Default user type
  bool _isLoading = false;

  Future<void> _signup() async {
    final String name = _nameController.text.trim();
    final String companyName = _companyNameController.text.trim();
    final String designation = _designationController.text.trim();
    final String phoneNumber = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String companyId = _companyIdController.text.trim();
    // Validate inputs
    if (name.isEmpty || name.length > 20 || !RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      _showErrorMessage("Name must be letters only and max 20 characters.");
      return;
    }
    if (companyName.isEmpty || companyName.length > 20) {
      _showErrorMessage("Company Name must be max 20 characters.");
      return;
    }
    if (designation.isEmpty || designation.length > 20 || !RegExp(r'^[a-zA-Z\s]+$').hasMatch(designation)) {
      _showErrorMessage("Designation must be letters only and max 20 characters.");
      return;
    }
    if (phoneNumber.isEmpty || phoneNumber.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      _showErrorMessage("Phone number must be exactly 10 digits.");
      return;
    }
    if (password.isEmpty || password.length != 10) {
      _showErrorMessage("Password must be exactly 10 characters.");
      return;
    }
    if (password != confirmPassword) {
      _showErrorMessage("Passwords do not match.");
      return;
    }
    if (companyId.isEmpty) {
      _showErrorMessage("Company ID is required.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://esheapp.in/esheapp_php/insert_userdata.php"), // Replace with your actual PHP script URL
        body: {
          'request_type': 'signup',
          'name': name,
          'user_type': _userType,
          'company_name': companyName,
          'phone_number': phoneNumber,
          'password': password,
          'designation': designation,
          'company_id': companyId, // Add company_id to the request
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['status'] == 'success') {
          _showSuccessMessage(responseBody['message']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ApprovalPendingPage()),
          );
        } else {
          _showErrorMessage(responseBody['message'] ?? "Unexpected error occurred.");
        }
      } else {
        _showErrorMessage("Something went wrong. Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorMessage("An error occurred. Please check your connection.");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Name",
                  hint: "Enter Name...",
                  controller: _nameController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z\s]+$')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Company Name",
                  hint: "Enter Company Name...",
                  controller: _companyNameController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Designation",
                  hint: "Enter Designation...",
                  controller: _designationController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z\s]+$')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Phone Number",
                  hint: "Enter Phone Number...",
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                SizedBox(height: 16),
                _buildDropdown(label: "User Type", items: ["Technician", "Admin"]),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Password",
                  hint: "Enter Password...",
                  controller: _passwordController,
                  obscureText: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Confirm Password",
                  hint: "Re-enter Password...",
                  controller: _confirmPasswordController,
                  obscureText: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: "Company ID",
                  hint: "Enter Company ID...",
                  controller: _companyIdController,
                  obscureText: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30), // Match button's border radius
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), // Adjust padding for button size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Match container's border radius
                      ),
                      backgroundColor: Colors.transparent, // Transparent for gradient
                      shadowColor: Colors.transparent, // Remove shadow
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color for contrast with gradient
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
                        );
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: Colors.black, // Set text color to black
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDropdown({required String label, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _userType,
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _userType = value!;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
