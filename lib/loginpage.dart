import 'package:eshefireapp/signuppage.dart';
import 'DashbordAdminpage.dart';
import 'DashboardPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Add this package in pubspec.yaml
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkActivationAndLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLicense(context); // Check license before showing login
    });
  }
  Future<void> _checkActivationAndLogin() async {
    final savedLicenseKey = await getSavedLicenseKey();
    final expiryDate = await getLicenseExpiryDate();

    if (savedLicenseKey == null || expiryDate == null || expiryDate.isBefore(DateTime.now())) {
      // Redirect to license popup if the key is missing or expired
      await showLicensePopup(context);
    } else {
      // If the license key is valid, proceed to auto-login or offline login
      await _checkAutoLogin();
    }
  }
  Future<void> saveLicenseKey(String key, DateTime expiryDate) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('license_key', key);
    await prefs.setString('license_expiry_date', expiryDate.toIso8601String());
  }

  Future<String?> getSavedLicenseKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('license_key');
  }

  Future<DateTime?> getLicenseExpiryDate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString('license_expiry_date');
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }

  Future<bool> validateLicenseKey(String licenseKey) async {
    try {
      final response = await http.post(
        Uri.parse("https://api.keygen.sh/v1/accounts/f95abdca-27c1-4475-a8e2-a95101cc537c/licenses/actions/validate-key"),
        headers: {
          'Authorization': 'activ-5f12aa43e0b588eef24fdf8d909029c8v3',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "meta": {
            "key": licenseKey,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meta']['valid'] == true) {
          print("License is valid.");
          final expiryDate = DateTime.parse(data['data']['attributes']['expiry']);
          await saveLicenseKey(licenseKey, expiryDate);
          return true;
        } else {
          print("License is invalid or expired.");
          return false;
        }
      } else {
        print("Failed to validate license: ${response.body}");
        return false;
      }
    } catch (e) {
      print("License validation failed: $e");
      return false;
    }
  }
  Future<void> logoutAndClearLicense(BuildContext context) async {
    // Access SharedPreferences to clear saved license data
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('license_key'); // Remove saved license key
    await prefs.remove('license_expiry_date'); // Remove expiry date
    print("License data cleared.");

    // Navigate back to license popup or login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Adjust as needed
    );

    // Optionally, show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logged out successfully!")),
    );
  }

  Future<void> showLicensePopup(BuildContext context) async {
    final TextEditingController licenseController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal without entering a key
      builder: (context) {
        return AlertDialog(
          title: Text("Enter License Key"),
          content: TextField(
            controller: licenseController,
            style: TextStyle(color: Colors.black), // Set text color to black
            decoration: InputDecoration(
              labelText: "License Key",
              labelStyle: TextStyle(color: Colors.grey), // Optional: Label color
              border: OutlineInputBorder(), // Add border for better UI
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final key = licenseController.text.trim();
                if (key.isNotEmpty) {
                  final isValid = await validateLicenseKey(key);
                  if (isValid) {
                    Navigator.of(context).pop(); // Close popup on success
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("License validated successfully!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Invalid license key.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a license key.")),
                  );
                }
              },
              child: Text("Validate"),
            ),
          ],
        );
      },
    );
  }


  Future<void> checkLicense(BuildContext context) async {
    final savedLicenseKey = await getSavedLicenseKey();
    final expiryDate = await getLicenseExpiryDate();

    if (savedLicenseKey == null || expiryDate == null || expiryDate.isBefore(DateTime.now())) {
      print("License expired or not found. Showing license popup...");
      await showLicensePopup(context);
    } else {
      print("License valid. Proceeding to app...");
    }
  }
  Future<void> handleLicenseExpiry(BuildContext context) async {
    final expiryDate = await getLicenseExpiryDate();
    if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear saved license data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Redirect to license input
      );
      showLicensePopup(context); // Prompt for a new key
    }
  }
  void decodeLicenseKey(String key) {
    final parts = key.split('.');
    if (parts.length == 3) {
      final payload = utf8.decode(base64.decode(base64.normalize(parts[1])));
      print("License Payload: $payload");
    } else {
      print("Invalid license key format.");
    }
  }


  /// Function to check network connectivity
  Future<bool> _isNetworkAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      print("Network available: $connectivityResult");
      return true;
    } else {
      print("No network connection.");
      return false;
    }
  }

  Future<void> _checkAutoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedPhone = prefs.getString('phone_number');
    final String? savedPassword = prefs.getString('password');
    final String? userType = prefs.getString('user_type');

    print("Checking auto-login...");
    print("Saved phone: $savedPhone, Saved password: $savedPassword, User type: $userType");

    if (savedPhone != null && savedPassword != null) {
      print("Attempting auto-login...");
      bool networkAvailable = await _isNetworkAvailable();
      if (networkAvailable) {
        try {
          // Try online login first
          await _autoLogin(savedPhone, savedPassword);
        } catch (e) {
          print("Online auto-login failed: $e. Falling back to offline login.");
          _offlineLogin(savedPhone, savedPassword);
        }
      } else {
        print("Network not available. Attempting offline login...");
        _offlineLogin(savedPhone, savedPassword);
      }
    } else {
      print("No saved credentials found.");
    }
  }

  Future<void> _autoLogin(String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse("https://sglehs.com/esheapp_php/login.php"),
        body: {
          'phone_number': phoneNumber,
          'password': password,
          'request_type': 'login',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print("Auto-login response: $responseData");

        if (responseData['login_status'] == "login_success") {
          if (responseData['isApproved']) {
            await _saveToPreferences(
              phoneNumber: phoneNumber,
              password: password,
              userType: responseData['userType'],
              userName: responseData['userName'],
              approvalType: responseData['approvalType'],
              companyId: '',
            );
            _navigateToDashboard(responseData['userType']);
          } else {
            _showErrorMessage("You are not eligible to log in. Please ask for approval.");
          }
        } else {
          print("Server-side error during auto-login: ${responseData['message']}");
        }
      } else {
        print("HTTP error during auto-login: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error during auto-login: $e");
      throw e; // Propagate exception for offline fallback
    }
  }

  Future<void> _offlineLogin(String phoneNumber, String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedPhone = prefs.getString('phone_number');
    final String? savedPassword = prefs.getString('password');
    final String? userType = prefs.getString('user_type');

    print("Offline login attempt with $phoneNumber and $password");
    print("Saved credentials: phone=$savedPhone, password=$savedPassword, userType=$userType");

    if (savedPhone == phoneNumber && savedPassword == password) {
      print("Offline login successful. Redirecting to dashboard. User type: $userType");
      _navigateToDashboard(userType!);
    } else {
      print("Offline login failed. Credentials do not match.");
      _showErrorMessage("Offline login failed. Please check your credentials.");
    }
  }

  Future<void> _login() async {
    final String phoneNumber = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String companyId = _companyIdController.text.trim();

    if (phoneNumber.isEmpty || phoneNumber.length != 10) {
      _showErrorMessage("Please enter a valid 10-digit phone number.");
      return;
    }
    if (password.isEmpty) {
      _showErrorMessage("Please enter your password.");
      return;
    }
    if (companyId.isEmpty) {
      _showErrorMessage("Please enter your company ID.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://esheapp.in/esheapp_php/login.php"),
        body: {
          'phone_number': phoneNumber,
          'password': password,
          'company_id': companyId,
          'request_type': 'login',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print("Login response: $responseData");

        if (responseData['login_status'] == "login_success") {
          if (responseData['isApproved']) {
            await _saveToPreferences(
              phoneNumber: phoneNumber,
              password: password,
              userType: responseData['userType'],
              userName: responseData['userName'],
              approvalType: responseData['approvalType'],
              companyId: companyId, // Save company_id locally
            );
            _navigateToDashboard(responseData['userType']);
          } else {
            _showErrorMessage("You are not eligible to log in. Please ask for approval.");
          }
        } else {
          _showErrorMessage(responseData['message']);
        }
      } else {
        _showErrorMessage("Something went wrong. Please try again later.");
      }
    } catch (e) {
      print("Login failed with exception: $e");
      _showErrorMessage("An error occurred. Please check your connection.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToPreferences({
    required String phoneNumber,
    required String password,
    required String userType,
    required String userName,
    required dynamic approvalType,
    required String companyId,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phoneNumber);
    await prefs.setString('password', password);
    await prefs.setString('user_type', userType);
    await prefs.setString('user_name', userName);
    await prefs.setString('approval_type', approvalType.toString());
    await prefs.setString('company_id', companyId); // Save company_id locally
    print("Saved to SharedPreferences: companyId=$companyId, phone=$phoneNumber");
  }

  void _navigateToDashboard(String userType) {
    if (userType == "Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashbordAdminpage()),
      );
    } else if (userType == "Technician") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    } else {
      _showErrorMessage("Unknown user type.");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resizing of UI when keyboard is open
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space sections evenly
        children: [
          // Section 1: Company Name
          Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  "E-SHE Fire",
                  style: TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color is overridden by ShaderMask
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black26,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Section 2: Login/Signup Section
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Enter your Credentials for login",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 32),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: TextStyle(
                        color: Colors.black, // Set the text color to black
                      ),
                      decoration: InputDecoration(
                        labelText: "Enter Mobile Number",
                        labelStyle: TextStyle(
                          color: Colors.grey, // Optional: Set label text color
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(
                        color: Colors.black, // Set the text color to black
                      ),
                      decoration: InputDecoration(
                        labelText: "Enter Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _companyIdController,
                      obscureText: true,
                      style: TextStyle(
                        color: Colors.black, // Set the text color to black
                      ),
                      decoration: InputDecoration(
                        labelText:  "Company ID",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
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
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(150, 50), // Set width and height
                          padding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 60.0), // Adjust padding for size
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Match container's border radius
                          ),
                          backgroundColor: Colors.transparent, // Transparent for gradient
                          shadowColor: Colors.transparent, // Remove shadow
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color for contrast with gradient
                          ),
                        ),
                      ),

                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await logoutAndClearLicense(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red for logout button
                      ),
                      child: Text("Logout"),
                    ),

                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don’t have an Account?"),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignupPage()),
                            );
                          },
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Section 3: Footer
          Column(
            children: [
              Text(
                "© Copy Right. All rights reserved",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "Powered by: LEE SAFEZONE, C/O SEED FOR SAFETY.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "For Support & Complaints: support@esheapp.in",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "Website: www.esheapp.in",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
