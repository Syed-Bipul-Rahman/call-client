import 'package:call_agora_lock/enum_file.dart';
import 'package:call_agora_lock/pages/login_page.dart';
import 'package:call_agora_lock/pages/user_list.dart';
import 'package:call_agora_lock/prefs_helpers.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? bearerToken = "";

  @override
  void initState() {
    super.initState();
    // Call the token check and navigation logic when the widget initializes
    checkTokenAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Splash", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // Get token from shared preferences
  Future<void> getToken() async {
    bearerToken = await PrefsHelper.getString(AppConstants.BEARER_TOKEN.toString());
  }

  // Check token and navigate to appropriate page
  Future<void> checkTokenAndNavigate() async {
    // Add a slight delay to show splash screen (optional)
    await Future.delayed(Duration(seconds: 2));

    // Get the token from shared preferences
    await getToken();

    // Navigate based on token availability
    if (bearerToken != null && bearerToken!.isNotEmpty) {
      // Token exists, navigate to UserListPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserList()),
      );
    } else {
      // No token, navigate to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }
}