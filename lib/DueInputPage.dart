import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class DueInputPage extends StatefulWidget {
  @override
  _DueInputPageState createState() => _DueInputPageState();
}

class _DueInputPageState extends State<DueInputPage> {
  String? selectedCompany;
  String? selectedSite;
  String? selectedPeriod;
  String? selectedRefillingValue;
  String? selectedCo2Extinguisher;
  String? selectedOtherExtinguisher;

  List<String> companyNames = [];
  List<String> siteNames = [];
  final List<String> periods = ["30 days", "60 days", "90 days", "180 days"];
  final List<String> refillingValues = ["10%", "12%", "15%", "20%"];
  final List<String> co2Extinguishers = ["1", "2", "3", "4", "5"];
  final List<String> otherExtinguishers = ["1", "2", "3"];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/due_fetch_data.php";

    try {
      // Retrieve company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      if (companyId == null) {
        showError("Company ID not found. Please log in again.");
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"company_id": companyId}, // Send company_id in the request
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey("error")) {
          showError(data["error"]);
        } else {
          setState(() {
            companyNames = List<String>.from(data["company_names"] ?? []);
            siteNames = List<String>.from(data["site_names"] ?? []);
            isLoading = false;
          });
        }
      } else {
        showError("Failed to fetch dropdown data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showError("An error occurred. Please check your connection: $e");
    }
  }


  Future<void> fetchExistingSettings() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/due_fetch_existing.php";

    if (selectedCompany == null || selectedSite == null) {
      showError("Please select a company and site.");
      return;
    }

    // Retrieve company ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null) {
      showError("Company ID not found. Please log in again.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "company_id": companyId,
          "company_name": selectedCompany!,
          "site_name": selectedSite!,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data["status"] == "success" && data["type"] == "old_inputs") {
          final inputs = data["data"];
          showPopupWithDetails(inputs);
        } else {
          showError(data["message"] ?? "Error fetching old inputs.");
        }
      } else {
        showError("Server error. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showError("An error occurred. Please check your connection.");
    }
  }


  void showPopupWithDetails(Map<String, dynamic> inputs) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Existing Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Company: $selectedCompany"),
              Text("Site: $selectedSite"),
              Text("Period: ${inputs["period"]}"),
              Text("Refilling Percentage: ${inputs["refilling_percentage"]}%"),
              Text("CO2 Extinguishers Due: ${inputs["co2_extinguisher_due"]}"),
              Text("Other Extinguishers Due: ${inputs["other_extinguisher_due"]}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveDueData() async {
    const String apiUrl = "https://esheapp.in/esheapp_php/due_update_data.php";

    if (selectedCompany == null ||
        selectedSite == null ||
        selectedPeriod == null ||
        selectedRefillingValue == null ||
        selectedCo2Extinguisher == null ||
        selectedOtherExtinguisher == null) {
      showError("Please fill in all required fields.");
      return;
    }

    // Retrieve company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id');

    if (companyId == null) {
      showError("Company ID not found. Please log in again.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "company_id": companyId, // Include company_id in the request
          "company_name": selectedCompany!,
          "site_name": selectedSite!,
          "period": selectedPeriod!,
          "refilling_percentage": selectedRefillingValue!,
          "co2_extinguisher_due": selectedCo2Extinguisher!,
          "other_extinguisher_due": selectedOtherExtinguisher!,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody["message"] == "Data updated successfully") {
          showSuccess("Data saved successfully!");
        } else {
          showError("Failed to save data: ${responseBody["error"] ?? "Unknown error"}");
        }
      } else {
        showError("Server error. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showError("An error occurred. Please check your connection.");
    }
  }


  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
                  'Due Settings',
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Icon(Icons.settings, size: 80, color: Colors.white),
            SizedBox(height: 20),
            buildDropdownWithLabel("Select Company *", companyNames, selectedCompany, (value) {
              setState(() {
                selectedCompany = value;
                fetchExistingSettings();
              });
            }),
            SizedBox(height: 20),
            buildDropdownWithLabel("Select Site *", siteNames, selectedSite, (value) {
              setState(() {
                selectedSite = value;
                fetchExistingSettings();
              });
            }),
            SizedBox(height: 20),
            buildDropdownWithLabel("Select Period *", periods, selectedPeriod, (value) {
              setState(() {
                selectedPeriod = value;
              });
            }),
            SizedBox(height: 20),
            buildDropdownWithLabel("Select Refilling Value *", refillingValues, selectedRefillingValue, (value) {
              setState(() {
                selectedRefillingValue = value;
              });
            }),
            SizedBox(height: 20),
            buildDropdownWithLabel("Select CO2 Extinguishers *", co2Extinguishers, selectedCo2Extinguisher, (value) {
              setState(() {
                selectedCo2Extinguisher = value;
              });
            }),
            SizedBox(height: 20),
            buildDropdownWithLabel("Select Other Extinguishers *", otherExtinguishers, selectedOtherExtinguisher,
                    (value) {
                  setState(() {
                    selectedOtherExtinguisher = value;
                  });
                }),
            SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12), // Match button border radius
              ),
              child: ElevatedButton(
                onPressed: selectedCompany == null ||
                    selectedSite == null ||
                    selectedPeriod == null ||
                    selectedRefillingValue == null ||
                    selectedCo2Extinguisher == null ||
                    selectedOtherExtinguisher == null
                    ? null
                    : saveDueData,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, // Text color
                  backgroundColor: Colors.transparent, // Transparent for gradient
                  shadowColor: Colors.transparent, // Remove default shadow
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Match border radius
                  ),
                ),
                child: Text(
                  "Save",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdownWithLabel(
      String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blue, // Outline color
                width: 2.0, // Outline width
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blue, // Outline color for enabled state
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.blueAccent, // Outline color for focused state
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
