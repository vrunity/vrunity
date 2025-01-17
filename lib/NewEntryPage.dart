import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'newentrypreviewpage.dart';

class NewEntryPage extends StatefulWidget {
  @override
  _NewEntryPageState createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  // Controllers for input fields
  final TextEditingController tagNumberController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController makeController = TextEditingController();
  final TextEditingController yearOfMfgController = TextEditingController();
  final TextEditingController hptDateController = TextEditingController();
  final TextEditingController refillingDateController = TextEditingController();
  final TextEditingController fullWeightController = TextEditingController();
  final TextEditingController serialNumberController = TextEditingController();

  // Dropdown data
  List<String> companyNames = [];
  List<String> siteNames = [];
  List<String> siteLocations = [];
  final List<String> typeDropdownValues = [
    "CO2",
    "DCP",
    "FOAM",
    "WATER",
    "CLEAN AGENT",
    "MODULAR CLEAN AGENT",
    "MODULAR ABC",
    "LITHIUM BATTERY",
    "K TYPE",
    "D TYPE"
  ];

  // Selected values
  String? selectedCompanyName;
  String? selectedSiteName;
  String? selectedSiteLocation;
  String? selectedType;
  String userName = ""; // To hold the username from SharedPreferences
  String? tagNumberError;
  bool isTagNumberLoading = false;


  bool isLoading = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
    getUserNameFromSharedPreferences();
    fetchUserName();
  }

  Future<void> getUserNameFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "";
    });
  }

  /// Fetch userName from SharedPreferences
  Future<void> fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "Unknown";
    });
    print("Fetched Technician Name: $userName");
  }

  Future<void> fetchDropdownData() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/new_entry.php";

    try {
      // Retrieve the company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      if (companyId == null || companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Company ID is missing. Cannot fetch dropdown data.")),
        );
        return;
      }

      // Send the request with company_id
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"company_id": companyId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success'] == true) {
          setState(() {
            companyNames = List<String>.from(result['data']['company_name']);
            siteNames = List<String>.from(result['data']['site_name']);
            siteLocations = List<String>.from(result['data']['site_location']);
            isLoading = false;
          });
        } else {
          throw Exception(result['message'] ?? "Failed to load dropdown data");
        }
      } else {
        throw Exception("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching dropdown data: $e")),
      );
    }
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
                  'New Entry',
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Company Name Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Company Name",
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelStyle: TextStyle(
                    color: Colors.blue, // Label text color
                    fontSize: 16, // Label font size
                    fontWeight: FontWeight.bold, // Label font weight
                  ),
                  border: OutlineInputBorder(),
                ),
                value: selectedCompanyName,
                onChanged: (value) {
                  setState(() {
                    selectedCompanyName = value;
                  });
                },
                items: companyNames
                    .map((company) => DropdownMenuItem(
                    value: company, child: Text(company)))
                    .toList(),
                validator: (value) => value == null
                    ? "Please select a company name"
                    : null,
              ),
              SizedBox(height: 16),

              // Site Name Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Site Name",
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(),
                ),
                value: selectedSiteName,
                onChanged: selectedCompanyName != null
                    ? (value) {
                  setState(() {
                    selectedSiteName = value;
                  });
                }
                    : null,
                items: siteNames
                    .map((site) => DropdownMenuItem(
                    value: site, child: Text(site)))
                    .toList(),
                validator: (value) => value == null
                    ? "Please select a site name"
                    : null,
                disabledHint: Text("Select company first"),
              ),
              SizedBox(height: 16),

              // Site Location Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Site Location",
                  floatingLabelBehavior: FloatingLabelBehavior.never, // Label always visible
                  border: OutlineInputBorder(),
                ),
                value: selectedSiteLocation,
                onChanged: selectedSiteName != null
                    ? (value) {
                  setState(() {
                    selectedSiteLocation = value;
                  });
                }
                    : null,
                items: siteLocations
                    .map((location) => DropdownMenuItem(
                    value: location, child: Text(location)))
                    .toList(),
                validator: (value) => value == null
                    ? "Please select a site location"
                    : null,
                disabledHint: Text("Select site name first"),
              ),
              SizedBox(height: 16),

              // Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Type",
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(),
                ),
                value: selectedType,
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                  });
                },
                items: typeDropdownValues
                    .map((type) =>
                    DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                validator: (value) =>
                value == null ? "Please select a type" : null,
              ),
              SizedBox(height: 16),

              _buildInputField(
                "Tag Number",

                tagNumberController,
                    (value) {
                  if (value == null || value.length != 10) {
                    return "Tag number must be 10 digits";
                  }
                  return null;
                },
                TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10), // Limit input to 10 characters
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                ],
              ),

              SizedBox(height: 16),
              _buildInputField(
                  "Capacity", capacityController, (value) => value == null || value.isEmpty
                  ? "Capacity is required"
                  : null,
                  TextInputType.text),

              SizedBox(height: 16),
              _buildInputField(
                  "Make",
                  makeController,
                      (value) => value == null || value.isEmpty
                      ? "Make is required"
                      : null,
                  TextInputType.text),
              SizedBox(height: 16),
              _buildInputField(
                "Year of MFG (yyyy-MM-dd)",
                yearOfMfgController,
                _dateValidator,
                TextInputType.datetime,
              ),
              SizedBox(height: 16),
              _buildInputField(
                "HPT Date (yyyy-MM-dd)",
                hptDateController,
                _dateValidator,
                TextInputType.datetime,
              ),
              SizedBox(height: 16),
              _buildInputField(
                "Refilling Date (yyyy-MM-dd)",
                refillingDateController,
                _dateValidator,
                TextInputType.datetime,
              ),

              SizedBox(height: 16),

              // Full Weight (Conditional)
              if (selectedType == "CO2")
                _buildInputField(
                  "Full Weight",
                  fullWeightController,
                      (value) => value == null || value.isEmpty
                      ? "Full Weight is required"
                      : null,
                  TextInputType.number,
                ),
              if (selectedType == "CO2") SizedBox(height: 16),

              _buildInputField(
                "Serial Number",
                serialNumberController,
                    (value) => value == null || value.isEmpty
                    ? "Serial number is required"
                    : null,
                TextInputType.text,
              ),
              SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: ElevatedButton(
                    onPressed: _saveEntry,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: Colors.transparent, // Transparent to show gradient
                      shadowColor: Colors.transparent, // Remove default shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Match Container's border radius
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color for contrast with gradient
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      String? Function(String?)? validator,
      TextInputType inputType, {
        List<TextInputFormatter>? inputFormatters, // Optional input formatters
      }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.black), // Text color set to black
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: validator,
      keyboardType: inputType,
      inputFormatters: inputFormatters, // Apply input formatters
    );
  }


  String? _dateValidator(String? value) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (value == null || !regex.hasMatch(value)) {
      return "Date must be in yyyy-MM-dd format";
    }
    return null;
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fix errors before submitting")),
      );
      return;
    }

    // Gather form data
    Map<String, dynamic> formData = {
      "tag_number": tagNumberController.text.trim(),
      "company_name": selectedCompanyName ?? "",
      "site_name": selectedSiteName ?? "",
      "site_location": selectedSiteLocation ?? "",
      "type": selectedType ?? "",
      "capacity": capacityController.text.trim(),
      "make": makeController.text.trim(),
      "year_of_mfg": yearOfMfgController.text.trim(),
      "hpt_date": hptDateController.text.trim(),
      "refilling_date": refillingDateController.text.trim(),
      "full_weight": selectedType == "CO2" ? fullWeightController.text.trim() : "", // Send full_weight even if empty
      "serial_no": serialNumberController.text.trim(),
      "technician_name": userName,
    };

    // Navigate to the Preview Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewPage(data: formData),
      ),
    );
  }

}
