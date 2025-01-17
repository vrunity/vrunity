import 'dart:io';
import 'package:eshefireapp/AboutUsPage.dart';
import 'package:eshefireapp/HelpAndSupportPage.dart';
import 'package:eshefireapp/ProfileSettingsPage.dart';
import 'package:eshefireapp/TermsAndPoliciesPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'AccessPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'userdetailsscreen.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController popupController = TextEditingController();
  bool isFetching = false; // Tracks if data is being fetched
  bool isDataFetched = false; // Tracks if the data is successfully fetched
  String companyName = "";
  String? selectedCompany;
  String? selectedSite;
  String? enteredNumber;
  List<String> companyNames = [];
  List<String> siteNames = [];
  String userName = ""; // To hold the username from SharedPreferences
  Map<String, String> summaryData = {
    "HPT Due Count": "Loading...",
    "Total Unique Tags": "Loading...",
    "Refilling Due Count": "Loading...",
    "Life End Count": "Loading...",
    "Checkin/Checkout Count": "Loading...",
  };
  Map<String, String> upcomingData = {
    "service_due": "Loading...",
    "hpt_due": "Loading...",
    "refilling_due": "Loading...",
  };
  Map<String, String> filteredData = {
    "inspected_count": "Loading...",
    "pending_count": "Loading...",
    "defect_count": "Loading...",
  };

  final TextEditingController numberController = TextEditingController();
  bool isSubmittingFiltered = false;
  bool isSubmittingSummary = false;
  bool isSubmittingUpcoming = false;
  final GlobalKey<AnimatedListState> _summaryListKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _upcomingListKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _filteredListKey = GlobalKey<AnimatedListState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<MapEntry<String, String>> _summaryDataList = [];
  List<MapEntry<String, String>> _upcomingDataList = [];
  List<MapEntry<String, String>> _filteredDataList = [];
  @override
  void initState() {
    super.initState();
    fetchDropdownData();
    requestStoragePermission();
    fetchUserName(); // Fetch the username during initialization
    _showPopupOnPageLoad();
  }
  Future<void> _showPopupOnPageLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCompanyId = prefs.getString('company_id');

    if (savedCompanyId != null && savedCompanyId.isNotEmpty) {
      print('Company ID already saved locally: $savedCompanyId');
      // No need to show the popup if the company ID is already saved locally
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter 4-digit Company ID'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: popupController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: TextStyle(
                      color: Colors.black, // Black text color
                    ),
                    decoration: InputDecoration(
                      labelText: '4-digit Number',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      if (value.length == 4) {
                        setState(() {
                          isFetching = true;
                          companyName = ""; // Clear previous company name
                        });
                        await _fetchCompanyName(value, setState);
                      }
                    },
                  ),
                  SizedBox(height: 8),
                  if (isFetching)
                    CircularProgressIndicator(), // Show loading indicator while fetching
                  SizedBox(height: 8),
                  Text(
                    'Company Name: $companyName',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    popupController.clear(); // Clear text field on cancel
                  },
                  child: Text('Cancel'),
                ),
                if (isDataFetched)
                  TextButton(
                    onPressed: () async {
                      // Save the entered number locally
                      await _saveNumberLocally(popupController.text);
                      await fetchDropdownData();
                      // Close the dialog
                      Navigator.of(context).pop();

                      // Clear the text field
                      popupController.clear();

                      print('Company ID saved locally and dialog closed.');
                    },
                    child: Text('OK'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveNumberLocally(String company_id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_id', company_id);
    print('company_id saved locally: $company_id');
  }
  Future<void> _fetchCompanyName(String company_id, Function setState) async {
    final url = Uri.parse('https://esheapp.in/esheapp_php/connect_company_db.php');
    try {
      // Log the request for debugging
      print('Request Body: {"company_id": $company_id}');

      final response = await http.post(
        url,
        body: {'company_id': company_id},
      );

      // Log the response for debugging
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['company_name'] != null) {
          setState(() {
            companyName = data['company_name'];
            isDataFetched = true;
          });
        } else {
          setState(() {
            companyName = data['message'] ?? "No match found";
            isDataFetched = false;
          });
        }
      } else {
        setState(() {
          companyName = "Server error: ${response.statusCode}";
          isDataFetched = false;
        });
      }
    } catch (error) {
      print('Error in API call: $error');
      setState(() {
        companyName = "Error occurred. Check logs.";
        isDataFetched = false;
      });
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }
  void _resetAndAnimateTable(
      Map<String, String> data,
      GlobalKey<AnimatedListState> listKey,
      List<MapEntry<String, String>> targetList) {
    setState(() {
      targetList.clear(); // Clear the specific list
    });
    Future.delayed(Duration(milliseconds: 300), () {
      final dataEntries = data.entries.toList();
      for (int i = 0; i < dataEntries.length; i++) {
        Future.delayed(Duration(milliseconds: 300 * i), () {
          if (mounted && i < dataEntries.length) {
            setState(() {
              targetList.add(dataEntries[i]);
              if (listKey.currentState != null) {
                listKey.currentState!.insertItem(targetList.length - 1);
              }
            });
          }
        });
      }
    });
  }
  //username
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
    // Fetch company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id') ?? '';

    // Check if company_id is available
    if (companyId.isEmpty) {
      print('No company_id found.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No company_id found. Please save a company ID first.')),
      );
      return;
    }

    // API URL
    final url = Uri.parse('https://esheapp.in/esheapp_php/overall_count_display.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'company_id': companyId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        setState(() {
          companyNames = List<String>.from(data['company_names']);
          siteNames = List<String>.from(data['site_names']);
        });
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }

  }

  Future<void> fetchSummaryData() async {
    // Fetch company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id') ?? '';

    // Check if company_id is available
    if (companyId.isEmpty) {
      print('No company_id found.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No company_id found. Please save a company ID first.')),
      );
      return;
    }

    // Ensure that both selectedCompany and selectedSite are selected
    if (selectedCompany == null || selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both Company Name and Site Name')),
      );
      return;
    }

    setState(() {
      isSubmittingSummary = true;
    });

    // API URL
    final url = Uri.parse('https://esheapp.in/esheapp_php/overall_count_display.php');

    try {
      // Send POST request with company_id, selectedCompany, and selectedSite
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'company_id': companyId,
          'company_name': selectedCompany,
          'site_name': selectedSite,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the response body
        final data = json.decode(response.body);

        // Check for errors in the response
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }

        // Update summary data
        setState(() {
          summaryData = {
            "HPT Due Count": data['hpt_due_count']?.toString() ?? "",
            "Total Unique Tags": data['total_unique_tags']?.toString() ?? "",
            "Refilling Due Count": data['refilling_due_count']?.toString() ?? "",
            "Life End Count": data['life_end_count']?.toString() ?? "",
            "Checkin/Checkout Count": data['checkin_checkout_count']?.toString() ?? "",
          };
        });

        // Call reset and animate table function
        _resetAndAnimateTable(summaryData, _summaryListKey, _summaryDataList);

        print('Summary Data: $summaryData');
      } else {
        throw Exception('Failed to fetch summary data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching summary data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching summary data: $e')),
      );
    } finally {
      setState(() {
        isSubmittingSummary = false;
      });
    }
  }


  Future<void> fetchUpcomingData() async {
    // Fetch company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id') ?? '';

    // Check if company_id is available
    if (companyId.isEmpty) {
      print('No company_id found.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No company_id found. Please save a company ID first.')),
      );
      return;
    }

    // Ensure that both selectedCompany and selectedSite are selected
    if (selectedCompany == null || selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both Company Name and Site Name')),
      );
      return;
    }

    setState(() {
      isSubmittingUpcoming = true;
    });

    // API URL
    final url = Uri.parse('https://esheapp.in/esheapp_php/upcomming_due_event.php');

    try {
      // Send POST request with company_id, selectedCompany, and selectedSite
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'company_id': companyId,
          'company_name': selectedCompany,
          'site_name': selectedSite,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the response body
        final data = json.decode(response.body);

        // Check for errors in the response
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }


        // Update upcoming data
        setState(() {
          upcomingData = {
            "service_due": data['service_due']?.toString() ?? "No Upcoming Date",
            "hpt_due": data['hpt_due']?.toString() ?? "No Upcoming Date",
            "refilling_due": data['refilling_due']?.toString() ?? "No Upcoming Date",
          };
        });

        // Call reset and animate table function
        _resetAndAnimateTable(upcomingData, _upcomingListKey, _upcomingDataList);

        print('Upcoming Data: $upcomingData');
      } else {
        throw Exception('Failed to fetch upcoming data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching upcoming data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching upcoming data: $e')),
      );
    } finally {
      setState(() {
        isSubmittingUpcoming = false;
      });
    }
  }


  Future<void> fetchFilteredData() async {
    // Fetch company_id from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('company_id') ?? '';

    // Check if company_id is available
    if (companyId.isEmpty) {
      print('No company_id found.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No company_id found. Please save a company ID first.')),
      );
      return;
    }

    // Ensure all required fields are filled
    if (selectedCompany == null || selectedSite == null || enteredNumber == null || enteredNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both Company Name and Site Name, and enter a number')),
      );
      return;
    }

    setState(() {
      isSubmittingFiltered = true;
    });

    // API URL
    final url = Uri.parse('https://esheapp.in/esheapp_php/overall_count_display.php');

    print("Fetching filtered data with company_id: $companyId");
    try {
      // Send POST request with company_id, selectedCompany, selectedSite, and enteredNumber
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'company_id': companyId,
          'company_name': selectedCompany,
          'site_name': selectedSite,
          'number': enteredNumber,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the response body
        final data = json.decode(response.body);

        // Check for errors in the response
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }

        // Update filtered data
        setState(() {
          filteredData = {
            "inspected_count": data['inspected_count']?.toString() ?? "",
            "pending_count": data['pending_count']?.toString() ?? "",
            "defect_count": data['defect_count']?.toString() ?? "",
          };
        });

        // Call reset and animate table function
        _resetAndAnimateTable(filteredData, _filteredListKey, _filteredDataList);

        print('Filtered Data: $filteredData');
      } else {
        throw Exception('Failed to fetch filtered data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching filtered data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching filtered data: $e')),
      );
    } finally {
      setState(() {
        isSubmittingFiltered = false;
      });
    }
  }


  Future<void> requestStoragePermission() async {
    print("Requesting storage permission...");

    if (Platform.isAndroid) {
      // Check for Android 11+ Scoped Storage
      if (await Permission.manageExternalStorage.isGranted) {
        print("Manage External Storage permission already granted.");
      } else {
        // Request Scoped Storage Permission for Android 11+
        final status = await Permission.manageExternalStorage.request();

        if (status.isGranted) {
          print("Manage External Storage permission granted.");
        } else if (status.isPermanentlyDenied) {
          print("Manage External Storage permission permanently denied.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Storage permission is required. Please enable it in your app settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  print("Opening app settings...");
                  openAppSettings();
                },
              ),
            ),
          );
        } else {
          print("Manage External Storage permission denied.");
        }
      }
    } else {
      print("This platform does not require storage permissions.");
    }
  }

  Future<void> downloadFileForHeader(String action) async {
    print("Starting download for action: $action");

    await requestStoragePermission();

    if (await Permission.manageExternalStorage.isGranted || await Permission.storage.isGranted) {
      // Fetch company_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('company_id') ?? '';

      if (companyId.isEmpty) {
        print('No company_id found.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No company_id found. Please save a company ID first.')),
        );
        return;
      }

      // Ensure that both selectedCompany and selectedSite are selected
      if (selectedCompany == null || selectedSite == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both Company Name and Site Name')),
        );
        return;
      }

      print("Company ID: $companyId, Company Name: $selectedCompany, Site Name: $selectedSite");

      // Construct the GET URL for debugging
      final urlWithParams = Uri.parse(
        'https://esheapp.in/esheapp_php/export_filtered.php?action=$action'
            '&company_id=$companyId'
            '&company_name=${Uri.encodeComponent(selectedCompany!)}'
            '&site_name=${Uri.encodeComponent(selectedSite!)}',
      );

      print("Constructed GET URL with Parameters: $urlWithParams");

      // Construct the POST URL
      final postUrl = Uri.parse('https://esheapp.in/esheapp_php/export_filtered.php');

      // Construct the POST payload
      final payload = json.encode({
        'company_id': companyId,
        'company_name': selectedCompany,
        'site_name': selectedSite,
        'action': action,
      });

      print("POST Payload: $payload");

      try {
        // Make the POST request with JSON body
        final response = await http.post(
          postUrl,
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );

        print("HTTP Response Code: ${response.statusCode}");

        if (response.statusCode == 200) {
          // Get the "Downloads" directory
          final directory = Directory('/storage/emulated/0/Download/EHS Downloads');
          if (!directory.existsSync()) {
            directory.createSync(recursive: true); // Create the directory if it doesn't exist
            print("Created directory: ${directory.path}");
          }

          // Construct the file path
          final filePath = '${directory.path}/$action.csv';

          // Write the file to storage
          final file = File(filePath);
          file.writeAsBytesSync(response.bodyBytes);

          print("File saved to: $filePath");

          // Notify user of successful download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File downloaded successfully to $filePath')),
          );

          // Optionally, display a dialog with the file location
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Download Successful'),
              content: Text('File has been saved to:\n$filePath'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          print("Failed to download file. HTTP Status Code: ${response.statusCode}");
          print("Response Body: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download file. Server error: ${response.statusCode}')),
          );
        }
      } catch (error) {
        print("Error during file download: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred while downloading file. Please try again.')),
        );
      }
    } else {
      print("Permission not granted. Cannot download file.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required to download files.')),
      );
    }
  }

  void showDownloadDialogForHeader(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download File'),
          content: Text('Do you want to download the $action file?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                downloadFileForHeader(action);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void navigateToAccessPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AccessPage()),
    );
  }
  Widget _buildListItem(MapEntry<String, String> entry, {bool showDownloadIcon = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjust padding around each item
      child: Container(
        width: double.infinity, // Make the container take full width
        decoration: BoxDecoration(
          color: Colors.white, // Background color
          borderRadius: BorderRadius.circular(12.0), // Increase corner radius
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3), // Softer shadow
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 3), // Shadow position
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0), // Adjust padding inside the container
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Align content vertically
            children: [
              Expanded(
                child: Text(
                  "${entry.key}: ${entry.value}",
                  style: TextStyle(
                    fontSize: 16, // Adjust font size
                    color: Colors.black, // Text color
                  ),
                ),
              ),
              // Conditionally show the download icon or a transparent box of the same size
              if (showDownloadIcon)
                IconButton(
                  icon: Icon(Icons.download, size: 24, color: Colors.blue), // Icon size and color
                  onPressed: () => showDownloadDialogForHeader(entry.key),
                )
              else
                SizedBox(
                  width: 48, // Same width as the IconButton
                  height: 48, // Same height as the IconButton
                ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the GlobalKey to the Scaffold
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0), // Adjusted AppBar height
        child: Container(
          margin: EdgeInsets.zero,
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
                  stops: [0.5, 1.0], // Adjust gradient ratio
                ),
              ),
              child: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.menu), // Hamburger menu icon
                  color: Colors.white, // Icon color for better contrast
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer(); // Open the drawer
                  },
                ),
                title: Text(
                  'Welcome, $userName',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // Updated title color for better visibility
                    fontWeight: FontWeight.bold, // Added bold for emphasis
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent, // Transparent to show gradient
                elevation: 0.0, // Subtle shadow effect
                shadowColor: Colors.black.withOpacity(0.25), // Shadow color
                actions: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    color: Colors.white, // Updated icon color for better contrast
                    onPressed: () {
                      print("Notification Icon Clicked");
                    },
                  ),
                ],
              ),
            ),
          ),

        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.5, 1.0], // Adjust gradient ratio
                ),
              ),
              child: Center(
                child: Text(
                  'Hello, $userName',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // Header text color
                    fontWeight: FontWeight.bold, // Bold text for emphasis
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.business, color: Colors.black),
              title: Text('Change Company ID', style: TextStyle(fontSize: 16)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('company_id'); // Remove only the company_id

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Company ID has been cleared. Please enter a new Company ID.'),
                    backgroundColor: Colors.blue,
                  ),
                );

                // Optionally refresh the current page to reflect changes
                setState(() {});
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.black),
              title: Text('Profile', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserDetailsScreen()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.black),
              title: Text('Settings & Privacy', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileSettingsPage()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.black),
              title: Text('About Us', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutUsPage()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.help, color: Colors.black),
              title: Text('Help & Support', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpAndSupportPage()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.policy, color: Colors.black),
              title: Text('Terms & Policies', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsAndPoliciesPage()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(fontSize: 16)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear all saved data
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),


      body: Container(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 50.0, 16.0, 16.0), // Add top padding (50.0)
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown for Company Name
                DropdownButtonFormField<String>(
                  value: selectedCompany,
                  items: companyNames.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCompany = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Company Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Dropdown for Site Name
                DropdownButtonFormField<String>(
                  value: selectedSite,
                  items: siteNames.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSite = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Site Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Fetch Summary Data Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                  child: ElevatedButton(
                    onPressed: fetchSummaryData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Transparent for gradient
                      shadowColor: Colors.transparent, // Remove default shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Match container's border radius
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Adjust padding for button size
                    ),
                    child: Text(
                      isSubmittingSummary ? 'Loading...' : 'Summary Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color for contrast with gradient
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16), // Reduced gap for better spacing

                // Summary Data List
                AnimatedList(
                  key: _summaryListKey,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  initialItemCount: _summaryDataList.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= _summaryDataList.length) {
                      return SizedBox.shrink();
                    }
                    final entry = _summaryDataList[index];
                    return SizeTransition(
                      sizeFactor: animation,
                      child: _buildListItem(entry),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Fetch Upcoming Data Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                  child: ElevatedButton(
                    onPressed: fetchUpcomingData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Transparent for gradient
                      shadowColor: Colors.transparent, // Remove default shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Match container's border radius
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Adjust padding for button size
                    ),
                    child: Text(
                      isSubmittingUpcoming ? 'Loading...' : 'Upcoming Events',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color for contrast with gradient
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Upcoming Data List
                AnimatedList(
                  key: _upcomingListKey,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  initialItemCount: _upcomingDataList.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= _upcomingDataList.length) {
                      return SizedBox.shrink();
                    }
                    final entry = _upcomingDataList[index];
                    return SizeTransition(
                      sizeFactor: animation,
                      child: _buildListItem(entry, showDownloadIcon: false), // No download icon
                    );
                  },
                ),
                SizedBox(height: 16),

                // Text Field for Number
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Colors.black, // Set text color to black
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enter Number',
                    labelStyle: TextStyle(
                      color: Colors.grey, // Label text color
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      enteredNumber = value;
                    });
                  },
                ),

                SizedBox(height: 16),

                // Fetch Filtered Data Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                  child: ElevatedButton(
                    onPressed: fetchFilteredData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Transparent for gradient
                      shadowColor: Colors.transparent, // Remove default shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Match container's border radius
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Adjust padding for button size
                    ),
                    child: Text(
                      isSubmittingFiltered ? 'Loading...' : 'Filtered Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color for contrast with gradient
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Filtered Data List
                AnimatedList(
                  key: _filteredListKey,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  initialItemCount: _filteredDataList.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= _filteredDataList.length) {
                      return SizedBox.shrink();
                    }
                    final entry = _filteredDataList[index];
                    return SizeTransition(
                      sizeFactor: animation,
                      child: _buildListItem(entry),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Next Button
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFF2A84F2)], // Gradient colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30.0), // Rounded corners
                    ),
                    child: ElevatedButton(
                      onPressed: navigateToAccessPage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 60.0), // Updated padding
                        backgroundColor: Colors.transparent, // Transparent for gradient
                        shadowColor: Colors.transparent, // Remove default shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0), // Match container's border radius
                        ),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18, // Font size
                          fontWeight: FontWeight.bold, // Bold for emphasis
                          color: Colors.white, // Text color for contrast with gradient
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}