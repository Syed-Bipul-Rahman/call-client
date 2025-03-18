import 'package:call_agora_lock/pages/call_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final CallScreenController _controller = Get.put(CallScreenController());

  @override
  void initState() {
    super.initState();
  _controller.getUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
        children: [],
      )),
    );
  }
}
