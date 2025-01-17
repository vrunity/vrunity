import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'AdminControlPage.dart';
import 'loginpage.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "syncOfflineDataTask") {
      print("SyncOfflineDataTask started");

      try {
        final prefs = await SharedPreferences.getInstance();
        List<String> savedData = prefs.getStringList('offline_data') ?? [];

        if (savedData.isNotEmpty) {
          print("Offline data found: ${savedData.length} entries");

          final List<String> successfullySynced = [];
          for (String jsonString in savedData) {
            try {
              final Map<String, dynamic> data = jsonDecode(jsonString);

              final response = await http.post(
                Uri.parse("https://sglehs.com/esheapp_php/append_new_row.php"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode(data),
              );

              if (response.statusCode == 200) {
                final result = jsonDecode(response.body);
                if (result["status"] == "success") {
                  print("Data synced successfully: $data");
                  successfullySynced.add(jsonString);
                } else {
                  print("Failed to sync data: ${result["message"]}");
                }
              } else {
                print("HTTP Error: ${response.statusCode}");
              }
            } catch (e) {
              print("Error syncing data: $e");
            }
          }

          // Remove successfully synced data
          savedData.removeWhere((entry) => successfullySynced.contains(entry));
          await prefs.setStringList('offline_data', savedData);
          print("Remaining offline data: ${savedData.length} entries");
        } else {
          print("No offline data to sync.");
        }
      } catch (e) {
        print("Error in callbackDispatcher: $e");
      }

      return Future.value(true); // Indicate the task ran successfully
    }

    return Future.value(false); // Task not recognized
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Register periodic task
  Workmanager().registerPeriodicTask(
    "syncOfflineDataTask",
    "syncOfflineDataTask",
    frequency: const Duration(minutes: 15),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Connectivity _connectivity;
  late Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();

    // Initialize Connectivity
    _connectivity = Connectivity();

    // Transform the connectivity stream
    _connectivityStream = _connectivity.onConnectivityChanged.asyncMap((results) async {
      if (results.isNotEmpty) {
        return results.first; // Use the first ConnectivityResult
      }
      return ConnectivityResult.none; // Default to no connectivity
    });

    // Listen for connectivity changes
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        print("Network is available: Syncing offline data...");
        _syncOfflineData(); // Trigger sync when network becomes available
      } else {
        print("No network available.");
      }
    });
  }


  Future<void> _syncOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedData = prefs.getStringList('offline_data') ?? [];

    if (savedData.isNotEmpty) {
      print("Offline data found: ${savedData.length} entries");

      final List<String> successfullySynced = [];
      for (String jsonString in savedData) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonString);

          final response = await http.post(
            Uri.parse("https://esheapp.in/esheapp_php/append_new_row.php"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(data),
          );

          if (response.statusCode == 200) {
            final result = jsonDecode(response.body);
            if (result["status"] == "success") {
              print("Data synced successfully: $data");
              successfullySynced.add(jsonString);
            } else {
              print("Failed to sync data: ${result["message"]}");
            }
          } else {
            print("HTTP Error: ${response.statusCode}");
          }
        } catch (e) {
          print("Error syncing data: $e");
        }
      }

      // Remove successfully synced data
      savedData.removeWhere((entry) => successfullySynced.contains(entry));
      await prefs.setStringList('offline_data', savedData);
      print("Remaining offline data: ${savedData.length} entries");

      // Show a SnackBar for success
      if (savedData.isEmpty) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text("All offline data synced successfully.")),
        );
      }
    } else {
      print("No offline data to sync.");
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("No offline data to sync.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF8E2DE2), // Gradient start color
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF8E2DE2),
          secondary: Color(0xFF4A00E0), // Accent color replacement
        ),
        scaffoldBackgroundColor:  Colors.white, // Background color for all pages
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF4A00E0), // Gradient end color for AppBar
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white), // Default body text color
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // Default headline text color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Button background color
            foregroundColor: Colors.white, // Button text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Button radius
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          filled: true, // Enable background color
          fillColor: Colors.white, // Background color for input boxes
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Rounded border
            borderSide: BorderSide(color: Color(0xFF8E2DE2)), // Border color
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue), // Enabled border color
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue), // Focused border color
          ),
          hintStyle: TextStyle(color: Colors.grey), // Hint text color
          labelStyle: TextStyle(color: Colors.grey), // Label text color
        ),
      ),

      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/admin': (context) => AdminControlPage(),
      },
    );
  }
}
