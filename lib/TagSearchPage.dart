import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class TagSearchPage extends StatefulWidget {
  @override
  _TagSearchPageState createState() => _TagSearchPageState();
}

class _TagSearchPageState extends State<TagSearchPage> {
  final TextEditingController tagNumberController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<MapEntry<String, String>> _animatedData = [];
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;

  Future<void> fetchDetails(String tagNumber) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _animatedData.clear();
    });

    try {
      // Retrieve company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      if (companyId == null) {
        setState(() {
          _isError = true;
          _errorMessage = "Company ID not found. Please log in again.";
        });
        return;
      }

      // Send request to the server
      final response = await http.post(
        Uri.parse("https://esheapp.in/esheapp_php/preview_details.php"),
        body: {
          "tag_number": tagNumber,
          "company_id": companyId, // Include company_id in the request
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse["status"] == "success") {
          final data = jsonResponse["data"] as Map<String, dynamic>;
          final filteredData = data.entries.map((entry) {
            return MapEntry(entry.key, entry.value?.toString() ?? "N/A");
          }).toList();

          // Animate data into the list
          animateData(filteredData);
        } else {
          // Handle error from the server
          setState(() {
            _isError = true;
            _errorMessage = jsonResponse["message"];
          });
        }
      } else {
        // Handle HTTP error
        setState(() {
          _isError = true;
          _errorMessage = "Server responded with status code ${response.statusCode}";
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isError = true;
        _errorMessage = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Animate data into the list
  void animateData(List<MapEntry<String, String>> data) {
    for (int i = 0; i < data.length; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted) {
          setState(() {
            _animatedData.add(data[i]);
            _listKey.currentState?.insertItem(_animatedData.length - 1);
          });
        }
      });
    }
  }

  // Build the animated table
  Widget buildAnimatedTable() {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Disable internal scrolling for smooth outer scrolling
      initialItemCount: _animatedData.length,
      itemBuilder: (context, index, animation) {
        final entry = _animatedData[index];
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Text(
                        "${entry.key}: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(entry.value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                bottom: Radius.circular(0.0), // Rounded bottom corners
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF7B2FF7), // Set the background color to a solid color
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
                    'Preview',
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
        color: Color(0xFF7B2FF7), // Background color for the body (light grey)
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                style: TextStyle(
                  color: Colors.black, // Set color to black
                ),
                controller: tagNumberController,
                decoration: InputDecoration(
                  labelText: "Enter Tag Number",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Set the background color to white
                    borderRadius: BorderRadius.circular(30), // Add a border radius of 30
                  ),


                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Match button radius
                      ),
                      backgroundColor: Colors.transparent, // Transparent for gradient
                      shadowColor: Colors.transparent, // Remove default shadow
                    ),
                    onPressed: () {
                      final tagNumber = tagNumberController.text.trim();
                      if (tagNumber.isNotEmpty) {
                        fetchDetails(tagNumber);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please enter a tag number")),
                        );
                      }
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "Search",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Text color as a fallback (overridden by ShaderMask)
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (_isLoading) Center(child: CircularProgressIndicator()),
              if (_isError)
                Center(
                  child: Text(
                    _errorMessage ?? "An error occurred",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (!_isLoading && !_isError && _animatedData.isNotEmpty)
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          buildAnimatedTable(),
                        ],
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
}
