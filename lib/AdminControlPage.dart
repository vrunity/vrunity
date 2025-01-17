import 'package:eshefireapp/DashbordAdminpage.dart';
import 'package:flutter/material.dart';
import 'UserControlPage.dart';
import 'DueInputPage.dart';
import 'AccessPage.dart';


class AdminControlPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0), // Adjusted AppBar height
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
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
                icon: const Icon(Icons.arrow_back), // Back button icon
                color: Colors.white, // Icon color
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashbordAdminpage()), // Navigate to AdminDashboard page
                  );
                },
              ),
              title: const Text(
                'Admin Control',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white, // Title text color for better contrast
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent, // Transparent to show gradient
              elevation: 0.0, // Subtle shadow effect
              shadowColor: Colors.black.withOpacity(0.25), // Shadow color with slight opacity
              iconTheme: const IconThemeData(
                color: Colors.white, // Icon color for better contrast
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  color: Colors.white, // Notification icon color
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
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Set a single color (Violet in this case)
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align content at the top
            children: [
              const SizedBox(height: 300), // Add space from the top
              // Buttons
              SizedBox(
                width: 200, // Fixed width for buttons
                height: 50, // Consistent height for buttons
                child: _buildButton(context, "User Control", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserControlPage()),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200, // Fixed width for buttons
                height: 50, // Consistent height for buttons
                child: _buildButton(context, "Due Settings", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DueInputPage()),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200, // Fixed width for buttons
                height: 50, // Consistent height for buttons
                child: _buildButton(context, "Monitoring", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccessPage(),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // Match button radius
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
          backgroundColor: Colors.transparent, // Transparent to show gradient
          shadowColor: Colors.transparent, // Remove shadow for clean gradient effect
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white, // Text color for contrast
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

}
