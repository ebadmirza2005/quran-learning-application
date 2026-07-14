import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/text.dart';
import '../teacher_screen/tutor_chat_screen.dart';

class TutorListScreen extends StatefulWidget {
  const TutorListScreen({super.key});

  @override
  State<TutorListScreen> createState() => _TutorListScreenState();
}

class _TutorListScreenState extends State<TutorListScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _refreshSession();
  }

  Future<void> _refreshSession() async {
    try {
      await supabase.auth.refreshSession();
    } catch (e) {
      print("Session refresh error: $e");
    }
  }

  String makeDataSafe(dynamic rawData) {
    if (rawData == null) return '-';
    if (rawData is List) {
      return rawData.isNotEmpty ? rawData.join(', ') : '-';
    }
    return rawData.toString();
  }

  Widget _buildDataRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: TextWidget(text: label, textColor: Colors.white, textWeight: FontWeight.bold,),
          ),
          Expanded(
            flex: 6,
            child: TextWidget(
              text: value,
              textColor: valueColor ?? Colors.white,
              textWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xffd2dad2),
        appBar: AppBar(
          backgroundColor: const Color(0xff0f766e),
          foregroundColor: Colors.white,
          title: const Text("Tutors"),
          centerTitle: true,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('tutors').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting){
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xff0f766e)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              }

              final tutors = snapshot.data ?? [];

              if (tutors.isEmpty) {
                return const Center(
                  child: Text("No tutors found!"),
                );
              }
              return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 12),
                  itemCount: tutors.length,
                  itemBuilder: (context, index) {
                    final tutor = tutors[index];

                    String tutorImage = tutor['profile_image'] ?? '';
                    String tutorName = tutor['name'] ?? 'No Name';
                    String location = tutor['city'] ?? 'Unknown Location';
                    String country = tutor['country'] ?? 'Unknown Country';

                    String gender = makeDataSafe(tutor['gender']);
                    String languages = makeDataSafe(tutor['languages']);
                    String skillsDisplay = makeDataSafe(tutor['skills']);
                    String rates = makeDataSafe(tutor['rates']);

                    bool isOnline = tutor['is_online'] as bool? ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(top: 35.0, bottom: 12.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 35),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                      tutorName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                        "$location, $country",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.black45, fontSize: 12)
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  Container(
                                    color: const Color(0xff0f766e),
                                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                    child: Column(
                                      children: [
                                        _buildDataRow("Gender", gender,),
                                        _buildDataRow("Languages", languages),
                                        _buildDataRow("Expertise", skillsDisplay),
                                        _buildDataRow("Rates", rates),
                                        _buildDataRow(
                                          "Online",
                                          isOnline ? "Yes" : "No",
                                          valueColor: isOnline ? Colors.greenAccent : Colors.white60,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // --- FLOATING PROFILE AVATAR ---
                          Positioned(
                            top: -30,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xff0f766e),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: tutorImage.isNotEmpty
                                    ? Image.network(
                                  tutorImage,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        tutorName.isNotEmpty ? tutorName[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
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
                                    : Text(
                                  tutorName.isNotEmpty ? tutorName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            right: -10,
                            top: -15,
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black
                                    ),
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                ),
                                child: IconButton(onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorChatScreen()));
                                }, icon: Icon(Icons.message, color: Color(0xff0f766e),))),
                          )
                        ],
                      ),
                    );
                  }
              );
            }
        )
    );
  }
}