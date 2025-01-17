import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'InspectionScanPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
class PreviewPage extends StatefulWidget {
  final Map<String, dynamic> data;

  PreviewPage({required this.data});

  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<MapEntry<String, dynamic>> _animatedData = [];
  bool _isAnimationComplete = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(Duration(milliseconds: 300), () {
      for (int i = 0; i < widget.data.entries.length; i++) {
        Future.delayed(Duration(milliseconds: 300 * i), () {
          _animatedData.add(widget.data.entries.elementAt(i));
          _listKey.currentState?.insertItem(_animatedData.length - 1);
          if (i == widget.data.entries.length - 1) {
            setState(() {
              _isAnimationComplete = true;
            });
          }
        });
      }
    });
  }

  Future<void> appendDataToServer(BuildContext context) async {
    const String apiUrl = "https://esheapp.in/esheapp_php/newentry_append_row.php";

    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve the company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id');

      debugPrint("Retrieved Company ID: $companyId");

      if (companyId == null || companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Company ID not found. Please log in again.")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare data to send
      final Map<String, dynamic> postData = {
        "action": "add_new_entry",
        "company_id": companyId, // Add the company_id to the POST data
        ...widget.data,
      };

      debugPrint("POST Data: $postData");

      // Send POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: postData.map((key, value) => MapEntry(key, value.toString())),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        debugPrint("Server Response: $responseData");

        if (responseData["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Data successfully updated!")),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionScanPage(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData["message"])),
          );
        }
      } else {
        throw Exception("Failed to connect to the server. Status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating data: $e")),
      );
      debugPrint("Exception: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                  'Entry Preview',
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Preview Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: _animatedData.length,
                itemBuilder: (context, index, animation) {
                  final entry = _animatedData[index];
                  return SizeTransition(
                    sizeFactor: animation,
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(entry.value.toString()),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            if (_isAnimationComplete)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30), // Match button's border radius
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                        await appendDataToServer(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Transparent to show gradient
                        shadowColor: Colors.transparent, // Remove default shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Match container's radius
                        ),
                      ),
                      icon: _isLoading
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : Icon(Icons.update),
                      label: _isLoading ? Text("Updating...") : Text("Update"),
                    ),
                  ),
                  SizedBox(width: 16), // Add spacing between buttons
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30), // Match button's border radius
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Transparent to show gradient
                        shadowColor: Colors.transparent, // Remove default shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Match container's radius
                        ),
                      ),
                      icon: Icon(Icons.edit),
                      label: Text("Edit"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
