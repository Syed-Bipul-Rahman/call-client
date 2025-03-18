import 'package:call_agora_lock/pages/call_controller.dart';
import 'package:call_agora_lock/pages/registerPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final CallScreenController _controller = Get.put(CallScreenController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Login Kor HaramJada",
              style: TextStyle(fontSize: 30),
            ),
          ),
          Text("Email"),
          TextField(
            controller: _controller.loginEmail,
          ),
          Text("password"),
          TextField(
            controller: _controller.loginPass,
          ),
          ElevatedButton(
            onPressed: () {
              _controller.loginVaiya(context);
            },
            child: Text("Login"),
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationPage(),
                  ),
                );
              },
              child: Text("Register"))
        ],
      )),
    );
  }
}
