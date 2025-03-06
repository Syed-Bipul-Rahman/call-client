import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';


class CallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const CallScreen({Key? key, required this.callData}) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initializeCallSound();
  }

  void _initializeCallSound() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.play(AssetSource('assets/sounds/incoming_call.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Caller info
            Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: widget.callData['caller_profile_pic'] != null
                      ? NetworkImage(widget.callData['caller_profile_pic'])
                      : null,
                  child: widget.callData['caller_profile_pic'] == null
                      ? Icon(Icons.person, size: 80, color: Colors.white)
                      : null,
                ),
                SizedBox(height: 20),
                Text(
                  widget.callData['callerName'] ?? 'Unknown Caller',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Incoming ${widget.callData['callType'] ?? 'video'} call',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),

            // Call actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject button
                GestureDetector(
                  onTap: () {
                    // Reject call logic
                    _audioPlayer.stop();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),

                // Accept button
                GestureDetector(
                  onTap: () {
                    // Accept call logic
                    _audioPlayer.stop();
                    // TODO: Navigate to actual call screen or start call

                    // Example:
                    // Navigator.of(context).pushReplacement(
                    //   MaterialPageRoute(
                    //     builder: (_) => AgoraCallScreen(
                    //       roomId: widget.callData['roomId'],
                    //       callType: widget.callData['callType'],
                    //     ),
                    //   ),
                    // );
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call, color: Colors.white, size: 30),
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