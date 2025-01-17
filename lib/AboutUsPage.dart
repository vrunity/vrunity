import 'package:flutter/material.dart';



class AboutUsPage extends StatelessWidget {

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
                  'About Us',
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
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Welcome to E-SHE Fire',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'A revolutionary app initiated by Seed for Safety and brought to life by the innovative team at Lee Safezone.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            sectionTitle('Seed for Safety'),
            Text(
              'An ISO 9001:2015 and ISO 21001:2018 certified company, Seed for Safety has been a trusted name since 2010 in promoting Safety, Health, and Environmental awareness across diverse sectors, including Industries, Corporate Enterprises, Construction, Educational Institutions, and the general public.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            bulletPoints([
              '3,030+ Trainings',
              '2,500+ Safety Audits',
              '750+ Clients',
              '100+ Skilled Manpower',
              '25,000+ Fire Extinguishers Under Care',
              '300,000+ People Reached',
            ]),
            SizedBox(height: 16),
            sectionTitle('Lee Safezone'),
            Text(
              'Founded in 2024, Lee Safezone is at the forefront of technological innovation in industrial safety. Their expertise spans across:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            bulletPoints([
              'Virtual Reality (VR): Over 10 industrial safety-related VR applications.',
              'Induction Videos: Delivered 50+ multilingual induction video projects tailored for diverse industries.',
              'IoT Projects: Cutting-edge IoT solutions, demonstrating their versatility and technical prowess.',
            ]),
            SizedBox(height: 16),
            Text(
              'This dynamic collaboration between Seed for Safety and Lee Safezone has resulted in the development of E-SHE Fire, a state-of-the-art app designed to enhance fire safety management. Seed for Safety exclusively holds the selling authority of this app, ensuring quality and reliability.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            sectionTitle('E-SHE Fire'),
            Text(
              'The app aligns with Indian Standard 2190:2024, addressing all aspects of fire extinguisher inspection and maintenance. Key features include:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            bulletPoints([
              'RFID and QR Code Integration: Instant access to extinguisher details, such as inspection dates and due dates, via RFID card scans or QR code inputs.',
              'AMC Checklist Management: Simplified inspection processes for the Annual Maintenance Contract (AMC) team.',
              'Comprehensive Dashboard: A clear overview of critical metrics, including HPT and refilling dues, life end status, defects, and next inspection schedules.',
              'Data Export: Easy data management with Excel exports.',
              'Data Security: Secure storage of all AMC data on our servers.',
              'Platform Support: Exclusively designed for Android devices, including mobile phones and tablets.',
            ]),
            SizedBox(height: 16),
            sectionTitle('Our Vision'),
            Text(
              'E-SHE Fire represents a commitment to innovation and safety, ensuring that industries and businesses can manage fire safety with ease and confidence. By leveraging advanced technologies, we aim to revolutionize fire extinguisher inspection and maintenance while promoting a culture of safety across all sectors.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              'Join us in our journey to redefine fire safety management with E-SHE Fire!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.blue, // Set text color to blue
        fontSize: 24, // Optional: Set a specific font size
        fontWeight: FontWeight.bold, // Optional: Set text to bold
      ),
    );
  }

  Widget bulletPoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map((point) => Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(fontSize: 16, color: Colors.black)),
            Expanded(
              child: Text(
                point,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }
}
