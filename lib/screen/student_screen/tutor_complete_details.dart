import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';

class TutorCompleteDetails extends StatefulWidget {
  final String tutorId;
  const TutorCompleteDetails({super.key, required this.tutorId});

  @override
  State<TutorCompleteDetails> createState() => _TutorCompleteDetailsState();
}

class _TutorCompleteDetailsState extends State<TutorCompleteDetails> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _certifications = [];
  List<Map<String, dynamic>> _employments = [];

  String makeDataSafe(dynamic rawData) {
    if (rawData == null) return '-';
    if (rawData is List) {
      return rawData.isNotEmpty ? rawData.join(', ') : '-';
    }
    String str = rawData.toString().trim();
    return str.isNotEmpty ? str : '-';
  }

  // Helper method to format date string to "MMM YYYY"
  String _formatDateString(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    try {
      DateTime parsedDate = DateTime.parse(rawDate);
      const List<String> monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${monthNames[parsedDate.month - 1]} ${parsedDate.year}";
    } catch (_) {
      return rawDate;
    }
  }

  // Helper method to construct image URL dynamically
  String? _getValidImageUrl(Map<String, dynamic> item) {
    dynamic rawUrl = item['image_url'] ??
        item['certificate_image'] ??
        item['certificate_url'] ??
        item['image'] ??
        item['document_url'] ??
        item['url'];

    if (rawUrl == null) return null;
    String urlStr = rawUrl.toString().trim();
    if (urlStr.isEmpty) return null;

    if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
      return urlStr;
    }

    try {
      return supabase.storage.from('certifications').getPublicUrl(urlStr);
    } catch (_) {
      return urlStr;
    }
  }

  // Dialog to view full certificate image
  void _showCertificateImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Unable to load image"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getTutorData() async {
    final tutorData = await supabase
        .from('tutors')
        .select()
        .eq('id', widget.tutorId)
        .maybeSingle();

    if (tutorData == null) {
      throw Exception("Tutor Details Not Found For ID: ${widget.tutorId}");
    }

    try {
      final certsResponse = await supabase
          .from('tutor_certifications')
          .select()
          .eq('tutor_id', widget.tutorId);

      _certifications = List<Map<String, dynamic>>.from(certsResponse);
    } catch (e) {
      if (tutorData['certifications'] != null && tutorData['certifications'] is List) {
        _certifications = List<Map<String, dynamic>>.from(tutorData['certifications']);
      } else {
        _certifications = [];
      }
    }

    try {
      final empResponse = await supabase
          .from('tutor_employments')
          .select()
          .eq('tutor_id', widget.tutorId);

      _employments = List<Map<String, dynamic>>.from(empResponse);
    } catch (e) {
      if (tutorData['employments'] != null && tutorData['employments'] is List) {
        _employments = List<Map<String, dynamic>>.from(tutorData['employments']);
      } else {
        _employments = [];
      }
    }

    return tutorData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Tutor Profile"),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getTutorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff0f766e)),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "Error Details:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          final tutorData = snapshot.data!;
          final String? profileImage = tutorData['profile_image'];
          final String tutorName = tutorData['name'] ?? 'Unknown Name';
          final String tutorCity = tutorData['city'] ?? 'Unknown City';
          final String tutorCountry = tutorData['country'] ?? 'Unknown Country';
          final String location = '$tutorCity, $tutorCountry';
          final double averageRating = (tutorData['rating'] as num? ?? 0.0).toDouble();
          final double hourlyRate = (tutorData['hourly_rate'] as num? ?? 0.0).toDouble();
          final String languages = makeDataSafe(tutorData['languages']);
          final int tutorSessions = tutorData['sessions'] ?? 0;
          final String? tutorVideo = tutorData['video_url'];
          final String? tutorAudio = tutorData['recitation_audio_url'];
          final String aboutTutor = tutorData['about'] ?? tutorData['bio'] ?? 'No bio provided.';

          return Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xff0f766e),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: (profileImage != null && profileImage.isNotEmpty)
                            ? Image.network(
                          profileImage,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.white,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                            : const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextWidget(
                      text: tutorName,
                      textSize: 22,
                      textWeight: FontWeight.bold,
                      textColor: Colors.white,
                    ),
                    TextWidget(
                      text: location,
                      textColor: Colors.white70,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (starIndex) {
                          double starValue = starIndex + 1.0;
                          if (averageRating >= starValue) {
                            return const Icon(Icons.star, color: Colors.amber, size: 18);
                          } else if (averageRating >= starValue - 0.5) {
                            return const Icon(Icons.star_half, color: Colors.amber, size: 18);
                          } else {
                            return const Icon(Icons.star_border, color: Colors.white70, size: 18);
                          }
                        }),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: averageRating.toStringAsFixed(1),
                          textWeight: FontWeight.bold,
                          textColor: Colors.white,
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),

              // Details Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rate & Language Info Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: "Per Hour : ", style: TextStyle(color: Colors.black)),
                                        TextSpan(
                                          text: "US\$${hourlyRate.toStringAsFixed(1)}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                                        )
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: "Sessions : ", style: TextStyle(color: Colors.black)),
                                        TextSpan(
                                          text: "$tutorSessions",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(text: "Languages : ", style: TextStyle(color: Colors.black)),
                                    TextSpan(
                                      text: languages,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Audio Recitation Section
                      TextWidget(
                        text: "Recitation Audio Of Tutor",
                        textSize: 18,
                        textWeight: FontWeight.bold,
                        textColor: const Color(0xff0f766e),
                      ),
                      const SizedBox(height: 10),
                      (tutorAudio != null && tutorAudio.trim().isNotEmpty)
                          ? TutorAudioPlayer(
                        key: ValueKey(tutorAudio),
                        tutorAudioUrl: tutorAudio,
                      )
                          : Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audiotrack_outlined,
                              size: 30,
                              color: Colors.black38,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "No tutor audio found",
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Video Player Section
                      TextWidget(
                        text: "Video Of Tutor",
                        textSize: 18,
                        textWeight: FontWeight.bold,
                        textColor: const Color(0xff0f766e),
                      ),
                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (tutorVideo != null && tutorVideo.trim().isNotEmpty)
                            ? TutorVideoPlayer(
                          tutorVideo: tutorVideo,
                          height: 300,
                        )
                            : Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_off,
                                size: 45,
                                color: Colors.black38,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "No tutor video found",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Employments Section (Updated with Details & Dates)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: const Icon(Icons.business_center_outlined, color: Color(0xff0f766e)),
                          title: const Text("Employments", style: TextStyle(fontWeight: FontWeight.w500)),
                          children: [
                            if (_employments.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _employments.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                                itemBuilder: (context, index) {
                                  final item = _employments[index];
                                  final company = item['company'] ?? item['organization'] ?? 'Unknown Company';
                                  final role = item['role'] ?? item['position'] ?? item['designation'] ?? '';

                                  final startDate = _formatDateString(item['start_date']?.toString() ?? item['from']?.toString());
                                  final endDate = (item['is_present'] == true || item['is_current'] == true)
                                      ? 'Present'
                                      : _formatDateString(item['end_date']?.toString() ?? item['to']?.toString());

                                  final duration = (startDate.isNotEmpty || endDate.isNotEmpty)
                                      ? "$startDate - ${endDate.isNotEmpty ? endDate : 'Present'}"
                                      : '';

                                  final description = item['description'] ?? item['details'] ?? item['summary'] ?? '';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                company,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            if (duration.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xff0f766e).withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  duration,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xff0f766e),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (role.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            role,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                        if (description.toString().trim().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            description.toString().trim(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            if (_employments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: Text("No Employment Record Found!"),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Certifications / Ijazah Section (Updated with Details)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: const Icon(Icons.verified_outlined, color: Color(0xff0f766e)),
                          title: const Text("Certifications / Ijazah", style: TextStyle(fontWeight: FontWeight.w500)),
                          children: [
                            if (_certifications.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _certifications.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                                itemBuilder: (context, index) {
                                  final item = _certifications[index];
                                  final title = item['title'] ?? item['degree'] ?? item['certificate_name'] ?? 'Certification';
                                  final issuer = item['issuer'] ?? item['institute'] ?? item['organization'] ?? 'Unknown Institute';
                                  final year = _formatDateString(item['year']?.toString() ?? item['issue_date']?.toString() ?? item['date']?.toString());
                                  final details = item['description'] ?? item['details'] ?? item['subject'] ?? item['notes'] ?? '';
                                  final imageUrl = _getValidImageUrl(item);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Certificate Thumbnail
                                        (imageUrl != null)
                                            ? GestureDetector(
                                          onTap: () => _showCertificateImageDialog(imageUrl, title),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              width: 52,
                                              height: 52,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 52,
                                                height: 52,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.workspace_premium, color: Color(0xff0f766e)),
                                              ),
                                            ),
                                          ),
                                        )
                                            : Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: const Color(0xff0f766e).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.workspace_premium, color: Color(0xff0f766e)),
                                        ),
                                        const SizedBox(width: 12),
                                        // Certification Info & Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                year.isNotEmpty ? "By $issuer ($year)" : "By $issuer",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              if (details.toString().trim().isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  details.toString().trim(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade800,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (imageUrl != null)
                                          IconButton(
                                            icon: const Icon(Icons.visibility, color: Color(0xff0f766e)),
                                            onPressed: () => _showCertificateImageDialog(imageUrl, title),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            if (_certifications.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: Text("No Certification Found!"),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextWidget(
                        text: "About Tutor",
                        textSize: 18,
                        textWeight: FontWeight.bold,
                        textColor: const Color(0xff0f766e),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          aboutTutor,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: ElevatedButtonWidget(
          buttonText: "Invite To Teach",
          onTap: () {},
          buttonColor: const Color(0xff0f766e),
          textColor: Colors.white,
        ),
      ),
    );
  }
}

class TutorVideoPlayer extends StatefulWidget {
  final String tutorVideo;
  final double height;

  const TutorVideoPlayer({
    super.key,
    required this.tutorVideo,
    this.height = 170,
  });

  @override
  State<TutorVideoPlayer> createState() => _TutorVideoPlayerState();
}

class _TutorVideoPlayerState extends State<TutorVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.tutorVideo),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Text(
              "Failed to load video.",
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.black12,
        child: const Center(
          child: Text(
            "Error loading video",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Chewie(controller: _chewieController!),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.black12,
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xff0f766e)),
      ),
    );
  }
}

class TutorAudioPlayer extends StatefulWidget {
  final String tutorAudioUrl;

  const TutorAudioPlayer({super.key, required this.tutorAudioUrl});

  @override
  State<TutorAudioPlayer> createState() => _TutorAudioPlayerState();
}

class _TutorAudioPlayerState extends State<TutorAudioPlayer> {
  late ja.AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isSourceSet = false;
  bool _hasError = false;
  String _errorMessage = "Failed to load audio track";

  @override
  void initState() {
    super.initState();
    _audioPlayer = ja.AudioPlayer();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      final isBuffering = state.processingState == ja.ProcessingState.loading ||
          state.processingState == ja.ProcessingState.buffering;

      setState(() {
        _isPlaying = state.playing;
        _isLoading = isBuffering;

        if (state.processingState == ja.ProcessingState.completed) {
          _position = Duration.zero;
          _isPlaying = false;
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      });
    });

    _audioPlayer.durationStream.listen((newDuration) {
      if (mounted && newDuration != null && newDuration != Duration.zero) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  Future<void> _toggleAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      if (_isSourceSet) {
        await _audioPlayer.play();
        return;
      }

      final String rawUrl = widget.tutorAudioUrl.trim();
      final String lowerUrl = rawUrl.toLowerCase();

      bool isValidFormat = lowerUrl.endsWith('.mp3') ||
          lowerUrl.endsWith('.m4a') ||
          lowerUrl.endsWith('.aac') ||
          lowerUrl.endsWith('.wav');

      if (!isValidFormat) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = "Unsupported format. Only MP3, M4A, AAC, and WAV are allowed.";
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final Uri audioUri = Uri.parse(rawUrl);

      try {
        final duration = await _audioPlayer.setAudioSource(
          ja.AudioSource.uri(audioUri),
          preload: true,
        );

        if (mounted) {
          setState(() {
            if (duration != null) _duration = duration;
            _isLoading = false;
            _isSourceSet = true;
          });
        }
        await _audioPlayer.play();
        return;
      } catch (streamError) {
        debugPrint("Direct stream failed, attempting local fallback: $streamError");
      }

      final response = await http.get(audioUri);

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/temp_audio.mp3');
        await file.writeAsBytes(response.bodyBytes);

        final duration = await _audioPlayer.setFilePath(file.path);
        if (mounted) {
          setState(() {
            if (duration != null) _duration = duration;
            _isLoading = false;
            _isSourceSet = true;
          });
        }
        await _audioPlayer.play();
      } else {
        throw Exception("Failed to download audio file");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = "Unable to play audio: ${e.toString()}";
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xff0f766e),
              ),
            )
                : Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 36,
              color: const Color(0xff0f766e),
            ),
            onPressed: _toggleAudio,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 4,
              ),
              child: Slider(
                activeColor: const Color(0xff0f766e),
                inactiveColor: Colors.grey.shade300,
                min: 0.0,
                max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                value: _position.inMilliseconds.toDouble().clamp(
                  0.0,
                  _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                ),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}