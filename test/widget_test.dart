import 'package:flutter/material.dart';

void main() {
  runApp(CompanyIDApp());
}

class CompanyIDApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Company ID Registration',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CompanyIDScreen(),
    );
  }
}

class CompanyIDScreen extends StatefulWidget {
  @override
  _CompanyIDScreenState createState() => _CompanyIDScreenState();
}

class _CompanyIDScreenState extends State<CompanyIDScreen> {
  final TextEditingController _companyIDController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _uniqueIDController = TextEditingController();

  final List<String> _existingCompanyIDs = ['12345', '67890', 'ABCDE'];

  bool _isRegistering = false;

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _companyIDController.clear();
      _companyNameController.clear();
      _uniqueIDController.clear();
    });
  }

  void _login() {
    final companyID = _companyIDController.text;

    if (companyID.isEmpty) {
      _showMessage("Please enter your Company ID");
      return;
    }

    if (_existingCompanyIDs.contains(companyID)) {
      _showMessage("Welcome back! You are now logged in.");
    } else {
      _showMessage("Company ID not found. Please create a new ID.");
    }

    _companyIDController.clear();
  }

  void _registerCompany() {
    final companyName = _companyNameController.text;
    final enteredID = _uniqueIDController.text;

    if (companyName.isEmpty) {
      _showMessage("Please enter a valid Company Name");
      return;
    }

    final newID = enteredID.isNotEmpty ? enteredID : _generateCompanyID(companyName);

    if (_existingCompanyIDs.contains(newID)) {
      _showMessage("This Unique ID is already registered. Please try another.");
      return;
    }

    setState(() {
      _existingCompanyIDs.add(newID);
    });

    _showMessage("Company ID '$newID' created successfully for '$companyName'!", onClose: () {
      _toggleMode(); // Switch back to login mode after successful registration
    });
  }

  String _generateCompanyID(String companyName) {
    return companyName.hashCode.toString().substring(0, 5).toUpperCase();
  }

  void _showMessage(String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onClose != null) onClose();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? "Register New Company" : "Company ID Management"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRegistering) ...[
              // Login View
              Text(
                "Enter Company ID",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _companyIDController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Company ID",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text("Login"),
              ),
              TextButton(
                onPressed: _toggleMode,
                child: Text("Create New ID"),
              ),
            ] else ...[
              // Registration View
              Text(
                "Enter Company Name",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _companyNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Company Name",
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Enter Your Unique ID (Optional)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _uniqueIDController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Unique ID",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerCompany,
                child: Text("Register"),
              ),
              TextButton(
                onPressed: _toggleMode,
                child: Text("Back to Login"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
