import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/text.dart';

class TutorCallScreen extends StatefulWidget {
  final String channelId;
  final String receiverName;

  const TutorCallScreen({
    super.key,
    required this.channelId,
    required this.receiverName,
  });

  @override
  State<TutorCallScreen> createState() => _TutorCallScreenState();
}

class _TutorCallScreenState extends State<TutorCallScreen> {
  final String appId = "34e3961e0a8441218a7c44a6d360f779";
  final SupabaseClient supabase = Supabase.instance.client;

  // Har instance ke liye unique random UID generate karein (Testing ke liye)
  final int myUid = Random().nextInt(1000000) + 1;

  int? _remoteUid;
  bool _localUserJoined = false;
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isEndingCall = false;
  RealtimeChannel? _callStatusChannel;

  @override
  void initState() {
    super.initState();
    initAgora();
    _listenForCallEnd();
  }

  Future<void> initAgora() async {
    try {
      // 1. Permissions Request
      await [Permission.microphone, Permission.camera].request();

      if (!mounted) return;

      // 2. Engine Creation & Init
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 3. Register Event Handlers BEFORE joining
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("✅ Local User Joined with UID: ${connection.localUid}");
          if (mounted) {
            setState(() {
              _localUserJoined = true;
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("🎉 Remote User Joined with UID: $remoteUid");
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
            });
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("❌ Remote User Left: $remoteUid");
          _leaveAndPop();
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("⚠️ Agora Error [$err]: $msg");
        },
      ));

      // 4. Video & Audio Configuration
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.startPreview();

      // 5. Join Channel
      await _engine!.joinChannel(
        token: '007eJxTYBD9v3GlLMOu/XPFq0ria+PqzxpFTdAQKd3axVDs88Lam0mBwdgk1djSzDDVINHCxMTQyNAi0TzZxCTRLMXYzCDN3Nzy+OnErIZARgb+tdcZGRkgEMRnYShJLS5hYAAAkBodCg==',
        channelId: 'test',
        uid: myUid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
    }
  }

  void _listenForCallEnd() {
    _callStatusChannel = supabase
        .channel('call_status_${widget.channelId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'channel_id',
        value: widget.channelId,
      ),
      callback: (payload) {
        final newStatus = payload.newRecord['status'];
        if (newStatus == 'ended' || newStatus == 'rejected') {
          _leaveAndPop();
        }
      },
    )
        .subscribe();
  }

  Future<void> _endCall() async {
    try {
      await supabase
          .from('calls')
          .update({'status': 'ended'})
          .eq('channel_id', widget.channelId);
    } catch (e) {
      debugPrint("Error updating call status: $e");
    } finally {
      await _leaveAndPop();
    }
  }

  Future<void> _leaveAndPop() async {
    if (_isEndingCall) return;
    _isEndingCall = true;

    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
      }
    } catch (e) {
      debugPrint("Error leaving channel: $e");
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    if (_callStatusChannel != null) {
      supabase.removeChannel(_callStatusChannel!);
    }
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _endCall();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Main Remote View
              Center(
                child: _remoteVideo(),
              ),

              // Top-Left Local Preview
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  width: 110,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 2),
                    color: Colors.black54,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _localUserJoined && _engine != null
                      ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                      : const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff0f766e),
                    ),
                  ),
                ),
              ),

              // Control Buttons
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        child: IconButton(
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (_engine == null) return;
                            setState(() {
                              _isMuted = !_isMuted;
                            });
                            _engine!.muteLocalAudioStream(_isMuted);
                          },
                        ),
                      ),
                      const SizedBox(width: 30),
                      CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 30,
                        child: IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.white, size: 28),
                          onPressed: _endCall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null && _engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xff0f766e)),
          const SizedBox(height: 16),
          TextWidget(
            text: _localUserJoined
                ? "Waiting for ${widget.receiverName}..."
                : "Connecting...",
            textSize: 18,
            textColor: Colors.white,
          ),
        ],
      );
    }
  }
}