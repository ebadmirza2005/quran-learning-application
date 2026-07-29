import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/text.dart';

class TrialClassroomScreen extends StatefulWidget {
  final String channelId;
  final String tutorName;
  final bool isTutor;
  const TrialClassroomScreen({super.key, required this.channelId, required this.tutorName, this.isTutor = false});

  @override
  State<TrialClassroomScreen> createState() => _TrialClassroomScreenState();
}

class _TrialClassroomScreenState extends State<TrialClassroomScreen> {
  static const String appId = "093e6c4056be4adf83aa61ce80c98687";
  late RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isScreenSharing = false;

  static const int _totalTrialSeconds = 1800; // 30 Minutes
  int _remainingSeconds = _totalTrialSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAgoraAndPermissions();
    _startTrialTimer();
  }

  Future<void> _initAgoraAndPermissions() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined channel: ${connection.channelId}");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user offline: $remoteUid");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: "007eJxTYDgnfiBSlyuBd+73FoHMVCvvVuWfZ+72br0dXz+9l8fs4S0FBgNL41SzZBMDU7OkVJPElDQL48REM8PkVAuDZEsLMwvz+I7MrIZARgbxvomMjAwQCOLzMISkFpcoBBTlZ6UmlzAwAAArXiHM",
      channelId: "Test Project",
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _startTrialTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _onTrialEnded();
      }
    });
  }

  Future<void> _onTrialEnded() async {
    await _leaveChannel();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "30-Min Free Trial Ended!",
          style: TextStyle(
            color: Color(0xff0f766e),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          widget.isTutor
              ? "Your 30-minute free trial with the student has concluded."
              : "Your trial with ${widget.tutorName} has ended. Would you like to hire this tutor for full sessions?",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0f766e),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave classroom screen
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    String minStr = minutes.toString().padLeft(2, '0');
    String secStr = seconds.toString().padLeft(2, '0');
    return "$minStr:$secStr";
  }

  // Toggle Mute Audio
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  // Toggle Local Camera Video
  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _engine.muteLocalVideoStream(_isVideoOff);
  }

  Future<void> _toggleScreenShare() async {
    try {
      if (!_isScreenSharing) {
        await _engine.startScreenCapture(
          const ScreenCaptureParameters2(
            captureAudio: true,
            audioParams: ScreenAudioParameters(
              sampleRate: 16000,
              channels: 2,
              captureSignalVolume: 100,
            ),
            captureVideo: true,
            videoParams: ScreenVideoParameters(
              dimensions: VideoDimensions(width: 1280, height: 720),
              frameRate: 15,
              bitrate: 0,
            ),
          ),
        );
        setState(() {
          _isScreenSharing = true;
        });
      } else {
        await _engine.stopScreenCapture();
        setState(() {
          _isScreenSharing = false;
        });
      }
    } catch (e) {
      debugPrint("Screen Share Error: $e");
    }
  }

  // Clean Leave Channel
  Future<void> _leaveChannel() async {
    _timer?.cancel();
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextWidget(
                text: "Trial: ${widget.tutorName}",
                textSize: 16,
                textColor: Colors.white,
              )
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300 ? Colors.redAccent : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 18, color: Colors.white),
                  TextWidget(
                    text: _formatTimer(_remainingSeconds),
                    textSize: 16,
                    textColor: Colors.white,
                  ),
                ],
              )
            )
          ],
        )
      ),
      body: Stack(
        children: [
          Center(
            child: _remoteUid != null
                ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelId),
              )
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xff0f766e),),
                const SizedBox(height: 16),
                TextWidget(
                  text: "Waiting for ${widget.tutorName} to join...",
                  textColor: Colors.white,
                )
              ]
            )
          ),
          Positioned(
            top: 20,
            right: 20,
            width: 110,
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.grey[900],
                child: _localUserJoined && !_isVideoOff
                  ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0)
                  )
                )
                    : const Center(
                  child: Icon(Icons.person_off,
                      color: Colors.white54, size: 30),
                ),
              )
            )
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic Toggle
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: _toggleMute,
                  ),

                  // Camera Toggle
                  IconButton(
                    icon: Icon(
                      _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      color: _isVideoOff ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: _toggleVideo,
                  ),

                  // Screen Share Toggle (Highly Useful for Tutors)
                  IconButton(
                    icon: Icon(
                      _isScreenSharing
                          ? Icons.stop_screen_share
                          : Icons.screen_share,
                      color:
                      _isScreenSharing ? Colors.amber : Colors.white,
                    ),
                    onPressed: _toggleScreenShare,
                  ),

                  // End Call Button
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      onPressed: () async {
                        await _leaveChannel();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      )
    );
  }
}
