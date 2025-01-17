import 'package:flutter/material.dart';

class TermsAndPoliciesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  'Terms and Policies',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1. Overview'),
            _buildSectionBody(
                "E-SHE Fire is an Android-based application designed in compliance with Indian Standard 2190:2024 for fire extinguisher inspection and management. The app facilitates AMC (Annual Maintenance Contract) teams in inspecting, tracking, and maintaining fire extinguishers using RFID and QR code technology. It provides a comprehensive dashboard for monitoring due dates, life end status, defects, and next inspections, and supports data export in Excel format. E-SHE Fire is offered exclusively on an annual premium subscription plan, with all client data securely stored on our servers."),
            _buildSectionHeader('2. Core Features'),
            _buildBulletedList([
              "RFID and QR Code Integration:\n• RFID cards fixed to extinguishers with a printed QR code for easy access.\n• Scanning the QR code redirects to a web URL where the UIN (Unique Identification Number) provides extinguisher information.",
              "AMC Inspection Management:\n• AMC teams can scan RFID cards with a reader to access the inspection checklist directly in the app.\n• Checklist completion updates server-side data in real-time.",
              "Dashboard Monitoring:\n• View HPT and refilling dues.\n• Track extinguisher life-end dates, defects, and next inspections.\n• Export all data in Excel format at any time.",
              "Secure Data Storage:\n• All client AMC data is securely stored on dedicated servers.",
              "Subscription Model:\n• Available on an annual premium plan with regular updates and support.",
              "Platform Support:\n• Android only (compatible with smartphones and tablets).",
            ]),
            _buildSectionHeader('3. Data Security and Privacy'),
            _buildBulletedList([
              "Client Data Storage:\n• All AMC data is stored securely on our cloud servers with access restricted to authorized personnel.\n• Data is encrypted during transit and storage.",
              "Client Ownership:\n• Clients retain full ownership of their data, which can be exported at any time via the app.",
              "Data Access:\n• Only authenticated users from the client's AMC team can access and update data using RFID or QR code scans.",
              "Data Backup:\n• Regular backups ensure data recovery in case of unforeseen circumstances.",
            ]),
            _buildSectionHeader('4. Subscription Policy'),
            _buildBulletedList([
              "Annual Premium Plan:\n• Subscriptions are billed annually, including access to all app features, server storage, updates, and customer support.",
              "Cancellation and Renewal:\n• Clients may cancel their subscription at any time; however, data will be retained on the server for 30 days post-cancellation.\n• Subscriptions must be renewed within 30 days of expiry to maintain uninterrupted service.",
              "Additional Fees:\n• Additional storage or custom features may incur extra charges, based on client requirements.",
            ]),
            _buildSectionHeader('5. Terms of Use'),
            _buildBulletedList([
              "App Usage:\n• The app is intended exclusively for AMC teams and fire safety professionals.\n• Unauthorized use, including attempts to modify or reverse-engineer the app, is prohibited.",
              "Device Compatibility:\n• The app is compatible with Android devices only. iOS devices are not supported.",
              "Limitations:\n• The app functionality is reliant on an active internet connection for data synchronization.\n• RFID scanning requires compatible hardware.",
            ]),
            _buildSectionHeader('6. Support and Updates'),
            _buildBulletedList([
              "Customer Support:\n• 24/7 support is provided through email and chat for troubleshooting and guidance.",
              "App Updates:\n• Regular updates include feature enhancements, bug fixes, and security patches.\n• Clients will be notified of major updates through the app.",
            ]),
            _buildSectionHeader('7. Disclaimer'),
            _buildBulletedList([
              "Liability:\n• E-SHE Fire is a tool to assist in extinguisher management but does not replace professional fire safety inspections.\n• The app developer is not liable for any damages or losses arising from misuse or failure to follow fire safety regulations.",
              "Compliance:\n• It is the responsibility of the client to ensure that all fire extinguishers comply with Indian Standard 2190:2024.",
            ]),
            _buildSectionHeader('8. Agreement'),
            _buildSectionBody(
                "By subscribing to the E-SHE Fire app, the client acknowledges and agrees to the terms and policies outlined in this document."),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black,
          fontSize: 14.0,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ",
                style: TextStyle(color: Colors.blue, fontSize: 16.0),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.0,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
