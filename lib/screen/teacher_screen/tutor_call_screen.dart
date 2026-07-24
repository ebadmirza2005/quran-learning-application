import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/text.dart';

class TutorCallScreen extends StatefulWidget {
  final String channelId;
  final String receiverName;
  final String? receiverImage; // 👈 1. Receiver Image URL Add Kiya

  const TutorCallScreen({
    super.key,
    required this.channelId,
    required this.receiverName,
    this.receiverImage, // 👈 Nullable rakha hai taake crash na ho agar image na mile
  });

  @override
  State<TutorCallScreen> createState() => _TutorCallScreenState();
}

class _TutorCallScreenState extends State<TutorCallScreen> {
  final String appId = "093e6c4056be4adf83aa61ce80c98687";
  final SupabaseClient supabase = Supabase.instance.client;

  final int myUid = Random().nextInt(1000000) + 1;

  int? _remoteUid;
  bool _localUserJoined = false;
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isEndingCall = false;
  RealtimeChannel? _callStatusChannel;

  @override
  void initState() {
    super.initState();
    initAgora();
    _listenForCallEnd();
  }

  // 1. Supabase Edge Function se Agora Token Fetch Karne Ka Function
  Future<String?> _fetchAgoraToken() async {
    try {
      debugPrint("🚀 Calling Edge Function for Channel: ${widget.channelId}");

      final response = await supabase.functions.invoke(
        'get-agora-token',
        body: {
          'channelName': widget.channelId,
          'uid': myUid,
        },
      );

      debugPrint("📩 Raw Response from Supabase: ${response.data}");

      if (response.data != null) {
        final token = response.data is Map ? response.data['token'] : response.data;
        debugPrint("🔑 Final Token: $token");
        return token.toString();
      } else {
        debugPrint("❌ Response data is null");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception fetching token: $e");
      return null;
    }
  }

  // 2. Agora Audio Engine Initialization
  Future<void> initAgora() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
      ].request();

      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        debugPrint("❌ Microphone Permission Denied");
        return;
      }

      if (!mounted) return;

      String? dynamicToken = await _fetchAgoraToken();
      if (dynamicToken == null || dynamicToken.isEmpty) {
        debugPrint("❌ Token issue! Cannot proceed.");
        return;
      }

      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
      }

      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: appId.trim(),
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("✅ Local User Joined: ${connection.localUid}");
          if (mounted) {
            setState(() {
              _localUserJoined = true;
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("🎉 Remote User Joined: $remoteUid");
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

      await _engine!.enableAudio();

      await _engine!.joinChannel(
        token: dynamicToken,
        channelId: widget.channelId,
        uid: myUid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      await _engine!.setEnableSpeakerphone(_isSpeakerOn);

    } catch (e) {
      debugPrint("❌ Error initializing Agora: $e");
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
        backgroundColor: const Color(0xff121212),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              // Call Info Section
              Column(
                children: [
                  // 👈 2. Updated Profile Image Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff0f766e),
                      border: Border.all(color: Colors.white24, width: 2),
                      image: (widget.receiverImage != null && widget.receiverImage!.isNotEmpty)
                          ? DecorationImage(
                        image: NetworkImage(widget.receiverImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: (widget.receiverImage == null || widget.receiverImage!.isEmpty)
                        ? Center(
                      child: Text(
                        widget.receiverName.isNotEmpty
                            ? widget.receiverName[0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Receiver Name (Below Image)
                  TextWidget(
                    text: widget.receiverName,
                    textSize: 22,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 10),

                  // Call Status
                  TextWidget(
                    text: _remoteUid != null
                        ? "Connected"
                        : (_localUserJoined
                        ? "Calling..."
                        : "Connecting..."),
                    textSize: 16,
                    textColor: Colors.white70,
                  ),
                ],
              ),

              // Control Buttons (Mute, End Call, Speaker)
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Button
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _isMuted ? Colors.white : Colors.white24,
                      child: IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _isMuted ? Colors.black : Colors.white,
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

                    // End Call Button
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 32,
                      child: IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.white, size: 30),
                        onPressed: _endCall,
                      ),
                    ),

                    // Speaker Button
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _isSpeakerOn ? Colors.white24 : Colors.white,
                      child: IconButton(
                        icon: Icon(
                          _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          color: _isSpeakerOn ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          if (_engine == null) return;
                          setState(() {
                            _isSpeakerOn = !_isSpeakerOn;
                          });
                          _engine!.setEnableSpeakerphone(_isSpeakerOn);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}