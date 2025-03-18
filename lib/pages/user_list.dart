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
          children: [
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  // Show a loading indicator while data is being fetched
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (_controller.userList.isEmpty) {
                  // Show a message when there is no data
                  return const Center(
                    child: Text(
                      "No users available",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                } else {
                  // Populate the ListView with ListTile widgets
                  return ListView.builder(
                    itemCount: _controller.userList.length,
                    itemBuilder: (context, index) {
                      final user = _controller.userList[index];
                      return ListTile(
                        title: Text(user.username??""),
                        subtitle: Text(user.email??""),
                        onTap: () {
                          _controller.makeCall(context, user.fcmToken??"");
                        },
                      );
                    },
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}