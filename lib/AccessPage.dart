import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eshefireapp/InspectionScanPage.dart';
import 'NewEntryPage.dart';
import 'HPTRefillingPage.dart';
import 'CheckInCheckOutPage.dart';
import 'TagSearchPage.dart';
class AccessPage extends StatefulWidget {
  @override
  _AccessPageState createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  int approvalType = 0;

  @override
  void initState() {
    super.initState();
    _loadApprovalType();
  }

  Future<void> _loadApprovalType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      approvalType = int.parse(prefs.getString('approval_type') ?? '0');
    });
  }

  bool _isButtonEnabled(int buttonCode) {
    if (buttonCode == 8) {
      // Always enable the Preview button
      return true;
    }
    return (approvalType & buttonCode) != 0;
  }

  void _showNotApprovedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You do not have access to this feature."),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved user data
    Navigator.pushReplacementNamed(context, '/loginpage'); // Redirect to the login page
  }

  Widget buildButton(BuildContext context, String label, int buttonCode, VoidCallback action) {
    final isEnabled = _isButtonEnabled(buttonCode);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      width: 250,
      decoration: isEnabled
          ? BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8), // Match button border radius
      )
          : null, // No gradient if disabled
      child: ElevatedButton(
        onPressed: isEnabled ? action : _showNotApprovedMessage,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.transparent : Colors.grey[400], // Transparent for gradient
          shadowColor: Colors.transparent, // Remove default shadow
          foregroundColor: isEnabled ? Colors.white : Colors.black38, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Match border radius
          ),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.white : Colors.black38, // Text color
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
                  'Access Page',
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
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Buttons
              buildButton(context, "Inspection", 1, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InspectionScanPage()),
                );
              }),
              buildButton(context, "HPT", 2, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HPTRefillingPage()),
                );
              }),
              buildButton(context, "New Entry", 4, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewEntryPage()),
                );
              }),
              buildButton(context, "Preview", 8, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TagSearchPage()),
                );
              }),
              buildButton(context, "Check in / Check out", 16, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckInCheckoutPage()),
                );
              }),
              buildButton(context, "Custom Option - 2", 32, () {
                print("Custom Option - 2 clicked");
              }),
              buildButton(context, "Custom Option - 3", 64, () {
                print("Custom Option - 3 clicked");
              }),
            ],
          ),
        ),
      ),
    );
  }
}
