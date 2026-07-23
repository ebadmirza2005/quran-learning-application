import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/text.dart';

class TutorCallScreen extends StatefulWidget {
  final String channelId;
  final String receiverName;
  const TutorCallScreen({super.key, required this.channelId, required this.receiverName});

  @override
  State<TutorCallScreen> createState() => _TutorCallScreenState();
}

class _TutorCallScreenState extends State<TutorCallScreen> {
  final String appId = "34e3961e0a8441218a7c44a6d360f779";

  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("Local User Joined: ${connection.localUid}");
        setState(() {
          _localUserJoined = true;
        });
      },

      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("Remote User Joined: $remoteUid");
        setState(() {
          _remoteUid = remoteUid;
        });
      },

      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint("Remote User Left: $remoteUid");
        setState(() {
          _remoteUid = null;
        });
        Navigator.pop(context);
      }
    ));

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(token: '', channelId: widget.channelId, uid: 0, options: const ChannelMediaOptions());
  }

  @override
  void dispose() {
    _clearAgora();
    super.dispose();
  }

  Future<void> _clearAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              height: 160,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
                    : const CircularProgressIndicator(color: Color(0xff0f766e)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      icon: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                        _engine.muteLocalAudioStream(_isMuted);
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 28,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(controller: VideoViewController.remote(rtcEngine: _engine, canvas: VideoCanvas(uid: _remoteUid), connection: RtcConnection(channelId: widget.channelId)));
    } else {
      return TextWidget(
        text: "Calling ${widget.receiverName}",
        textSize: 18,
        textColor: Colors.white,
      );
    }
  }
}
