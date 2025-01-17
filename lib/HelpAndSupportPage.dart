import 'package:flutter/material.dart';

class HelpAndSupportPage extends StatelessWidget {
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
                  'Help and Support',
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
        color: Color(0xFFF4F6FC), // Set your desired background color (light gray in this case)
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ChatBubble(
              title: "General Questions",
              content: [
                ChatContent(
                    question: "What is the E-SHE Fire app?",
                    answer: "E-SHE Fire is an Android-based application designed to comply with Indian Standard 2190:2024 for fire extinguisher inspection and management. It simplifies the inspection process, tracks due dates, and securely stores all fire extinguisher data on our servers."
                ),
                ChatContent(
                    question: "Who is the app intended for?",
                    answer: "The app is designed for AMC (Annual Maintenance Contract) teams, fire safety professionals, and businesses that need to inspect and manage fire extinguishers efficiently."
                ),
                ChatContent(
                    question: "What platforms does the app support?",
                    answer: "The app is compatible with Android devices, including smartphones and tablets. It is not available for iOS devices."
                ),
                ChatContent(
                    question: "What is the annual premium plan?",
                    answer: "The annual premium plan provides access to all app features, secure data storage, updates, and customer support for one year."
                ),
              ],
            ),
            ChatBubble(
              title: "Features and Usage",
              content: [
                ChatContent(
                    question: "How do I access fire extinguisher information?",
                    answer: "Each extinguisher has an RFID card with a printed QR code. You can:\n1. Scan the QR code to open a web URL and type the Unique Identification Number (UIN).\n2. Use an RFID reader to scan the card and access the extinguisher’s details in the app."
                ),
                ChatContent(
                    question: "What information can I view about the extinguisher?",
                    answer: "The app displays inspection dates, due dates (HPT, refilling, life end), defects, next inspection schedules, and more."
                ),
                ChatContent(
                    question: "What happens if I don’t have an RFID reader?",
                    answer: "You can manually type the UIN number printed on the RFID card to access the extinguisher details and checklist."
                ),
                ChatContent(
                    question: "Can I export data?",
                    answer: "Yes, the app allows you to export all fire extinguisher data in Excel format for easy reporting and analysis."
                ),
              ],
            ),
            ChatBubble(
              title: "Technical Questions",
              content: [
                ChatContent(
                    question: "What type of RFID cards does the app support?",
                    answer: "The app supports 125kHz RFID cards, which are commonly used for fire extinguisher tagging."
                ),
                ChatContent(
                    question: "What hardware is required for scanning?",
                    answer: "You will need an Android-supported RFID reader to scan RFID cards. If you don’t have an RFID reader, you can still use the app by entering the UIN manually."
                ),
                ChatContent(
                    question: "Does the app work offline?",
                    answer: "While the app requires an internet connection for data synchronization and exporting, you can still input data offline. The data will sync to the server once you reconnect to the internet."
                ),
              ],
            ),
            ChatBubble(
              title: "Data Security and Storage",
              content: [
                ChatContent(
                    question: "Where is the data stored?",
                    answer: "All client AMC data is securely stored on our servers with encryption to protect sensitive information."
                ),
                ChatContent(
                    question: "Is my data safe?",
                    answer: "Yes, your data is encrypted and stored securely. Access is restricted to authorized users only."
                ),
                ChatContent(
                    question: "Can I access my data after canceling my subscription?",
                    answer: "Your data will remain accessible for 30 days after subscription cancellation. You can export it before the data is permanently removed."
                ),
              ],
            ),
            ChatBubble(
              title: "Troubleshooting",
              content: [
                ChatContent(
                    question: "What if the QR code doesn’t scan?",
                    answer: "Ensure the QR code is not damaged and your device's camera is functional. If the issue persists, manually type the UIN to access the data."
                ),
                ChatContent(
                    question: "What should I do if the RFID reader isn’t working?",
                    answer: "Check that the RFID reader is properly connected to your Android device. If the issue continues, use the UIN number manually to proceed."
                ),
                ChatContent(
                    question: "How do I renew my subscription?",
                    answer: "You can renew your subscription directly from the app or by contacting our support team."
                ),
              ],
            ),
            ChatBubble(
              title: "Support and Assistance",
              content: [
                ChatContent(
                    question: "How do I contact customer support?",
                    answer: "You can reach our customer support team via:\n• Email: support@esheapp.in\n• Phone: +91-91501 40615."
                ),
                ChatContent(
                    question: "Is training provided for using the app?",
                    answer: "Yes, we offer training materials and support to ensure smooth onboarding for your team."
                ),
                ChatContent(
                    question: "Are there regular updates for the app?",
                    answer: "Yes, regular updates are provided to improve functionality, security, and compliance with the latest standards."
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String title;
  final List<ChatContent> content;

  ChatBubble({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 8),
        ...content.map((chat) => ChatItem(chat: chat)),
        Divider(color: Colors.grey),
      ],
    );
  }
}

class ChatContent {
  final String question;
  final String answer;

  ChatContent({required this.question, required this.answer});
}

class ChatItem extends StatelessWidget {
  final ChatContent chat;

  ChatItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                chat.question,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.blue, ),
              ),
            ),
          ),
          SizedBox(height: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                chat.answer,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
