import 'package:call_agora_lock/pages/call_controller.dart';
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
      body: SafeArea(
          child: Column(children: [
        Text("User Name"),
        TextField(
          controller: _controller.userNameController,
        ),
        Text("Email"),
        TextField(
          controller: _controller.emailController,
        ),
        Text("Password"),
        TextField(
          controller: _controller.passwordController,
        ),
        SizedBox(height: 20),
        ElevatedButton(
            onPressed: () {
            _controller.registerAnAccount();
            },
            child: Text("Register"))
      ])),
    );
  }
}
