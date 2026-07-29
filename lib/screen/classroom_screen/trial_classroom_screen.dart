import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/text.dart';
import '../teacher_screen/classroom_demo/qaida_index_tab.dart';
import '../teacher_screen/classroom_demo/quran_index_tab.dart';
import '../teacher_screen/classroom_demo/whiteboard_tab.dart';

class TrialClassroomScreen extends StatefulWidget {
  final String channelId;
  final String tutorName;
  final bool isTutor;

  const TrialClassroomScreen({
    super.key,
    required this.channelId,
    required this.tutorName,
    this.isTutor = false,
  });

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
  bool _isLoading = true;

  // Navigation Tab Control (0 = Video Call, 1 = Class Notes, 2 = Materials)
  int _activeTabIndex = 0;

  static const int _totalTrialSeconds = 1800;
  int _remainingSeconds = _totalTrialSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAgoraAndPermissions();
  }

  Future<String?> _fetchDynamicToken(String channelName) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'get-agora-token',
        body: {
          'channelName': channelName,
          'uid': 0,
        },
      );
      if (res.status == 200 && res.data != null) {
        return res.data['token'] as String?;
      }
    } catch (e) {
      debugPrint("Token Generation Error: $e");
    }
    return null;
  }

  Future<void> _initAgoraAndPermissions() async {
    await [Permission.camera, Permission.microphone].request();

    final String? agoraToken = await _fetchDynamicToken(widget.channelId);

    if (agoraToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to secure connection token")),
        );
      }
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine.enableDualStreamMode(enabled: true);
    await _engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 0,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ),
    );

    // Register Event Handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined: ${connection.channelId}");
          if (mounted) {
            setState(() {
              _localUserJoined = true;
              _isLoading = false;
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
            });
            _startTrialTimer();
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user offline: $remoteUid");
          if (mounted) {
            setState(() {
              _remoteUid = null;
            });
            _pauseTrialTimer();
          }
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) async {
          final newToken = await _fetchDynamicToken(widget.channelId);
          if (newToken != null) {
            await _engine.renewToken(newToken);
          }
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: agoraToken,
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _startTrialTimer() {
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer?.cancel();
        _onTrialEnded();
      }
    });
  }

  void _pauseTrialTimer() {
    _timer?.cancel();
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
              Navigator.pop(context);
              Navigator.pop(context);
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

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

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

        await _engine.updateChannelMediaOptions(
          const ChannelMediaOptions(
            publishScreenTrack: true,
            publishCameraTrack: false,
            publishScreenCaptureAudio: true,
            publishScreenCaptureVideo: true,
          ),
        );

        setState(() {
          _isScreenSharing = true;
        });
      } else {
        await _engine.stopScreenCapture();

        await _engine.updateChannelMediaOptions(
          ChannelMediaOptions(
            publishScreenTrack: false,
            publishCameraTrack: !_isVideoOff,
            publishScreenCaptureAudio: false,
            publishScreenCaptureVideo: false,
          ),
        );

        setState(() {
          _isScreenSharing = false;
        });
      }
    } catch (e) {
      debugPrint("Screen Share Error: $e");
    }
  }

  Future<void> _leaveChannel() async {
    _timer?.cancel();
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint("Engine Release Error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // --- TAB CONTENT BUILDERS ---

  Widget _buildVideoCallView() {
    return Stack(
      children: [
        // 1. Remote View
        Center(
          child: _remoteUid != null
              ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(
                uid: _remoteUid,
                renderMode: RenderModeType.renderModeFit,
              ),
              connection: RtcConnection(channelId: widget.channelId),
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xff0f766e),
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: "Waiting for ${widget.tutorName} to join...",
                textColor: Colors.white,
              )
            ],
          ),
        ),

        // 2. PIP Local View
        Positioned(
          top: 20,
          right: 20,
          width: 110,
          height: 150,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey[900],
              child: _isScreenSharing
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.screen_share,
                        color: Colors.amber, size: 30),
                    SizedBox(height: 6),
                    Text(
                      "Sharing\nScreen",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : (_localUserJoined && !_isVideoOff
                  ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
                  : const Center(
                child: Icon(
                  Icons.person_off,
                  color: Colors.white54,
                  size: 30,
                ),
              )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassQuranView() {
    return QuranIndexTab();
  }

  Widget _buildClassQaidaView() {
    return QaidaIndexTab();
  }

  Widget _buildClassWhiteboardView() {
    return WhiteboardTab();
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
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remoteUid == null
                    ? Colors.amber.shade800
                    : (_remainingSeconds < 300
                    ? Colors.redAccent
                    : Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _remoteUid == null ? Icons.hourglass_top : Icons.timer,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  TextWidget(
                    text: _remoteUid == null
                        ? "Waiting..."
                        : _formatTimer(_remainingSeconds),
                    textSize: 15,
                    textColor: Colors.white,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xff0f766e)),
      )
          : Column(
        children: [
          // 1. Navigation Bar (Allows navigating inside classroom without killing stream)
          Container(
            color: const Color(0xff111827),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavButton(
                  index: 0,
                  label: "Video",
                ),
                _buildNavButton(
                  index: 1,
                  label: "Quran",
                ),
                _buildNavButton(
                  index: 2,
                  label: "Qaida",
                ),
                _buildNavButton(
                  index: 3,
                  label: "Whiteboard",
                ),
              ],
            ),
          ),

          // 2. Active Tab View (Maintains Agora State seamlessly)
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: _activeTabIndex,
                  children: [
                    _buildVideoCallView(),
                    _buildClassQuranView(),
                    _buildClassQaidaView(),
                    _buildClassWhiteboardView(),
                  ],
                ),

                // Floating PIP Indicator when navigating away from Video tab
                if (_activeTabIndex != 0 && _isScreenSharing)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.screen_share,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Sharing Active (Tap to view)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
                IconButton(
                  icon: Icon(
                    _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    color:
                    _isVideoOff ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: _toggleVideo,
                ),
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
                CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 22,
                  child: IconButton(
                    icon:
                    const Icon(Icons.call_end, color: Colors.white),
                    onPressed: () async {
                      await _leaveChannel();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required int index,
    required String label,
  }) {
    final bool isSelected = _activeTabIndex == index;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? const Color(0xff0f766e) : Colors.white60,
      ),
      onPressed: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}