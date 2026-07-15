import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/text.dart';
import '../student_screen/student_chat_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final supabase = Supabase.instance.client;

  String makeDataSafe(dynamic rawData) {
    if (rawData == null) return '-';
    if (rawData is List) {
      return rawData.isNotEmpty ? rawData.join(', ') : '-';
    }
    return rawData.toString();
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: TextWidget(text: label, textColor: Colors.white60),
          ),
          Expanded(
            flex: 6,
            child: TextWidget(text: value, textColor: Colors.white),
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
          title: const Text("Students"),
          centerTitle: true,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('students').stream(primaryKey: ['id']),
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

              final students = snapshot.data ?? [];

              if (students.isEmpty) {
                return const Center(
                  child: Text("No students found!"),
                );
              }
              return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 12),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    String studentName = student['name'] ?? 'No Name';
                    String location = student['city'] ?? 'Unknown Location';
                    String country = student['country'] ?? 'Unknown Country';

                    String profileImage = student['profile_image'] ?? '';

                    String gender = makeDataSafe(student['student_gender']);
                    String languages = makeDataSafe(student['languages']);
                    String seekingKnowledge = makeDataSafe(student['seeking_knowledge']);
                    String timezone = makeDataSafe(student['timezone']);

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
                                      studentName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                        "$location, $country",
                                        style: const TextStyle(color: Colors.black45, fontSize: 12)
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    color: const Color(0xff0f766e),
                                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                    child: Column(
                                      children: [
                                        _buildDataRow("Gender", gender),
                                        _buildDataRow("Languages", languages),
                                        _buildDataRow("Seeking Knowledge", seekingKnowledge),
                                        _buildDataRow("Timezone", timezone),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: -30,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xff0f766e),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: profileImage.isNotEmpty
                                    ? Image.network(
                                  profileImage,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Transform.translate(
                                        offset: const Offset(0, 5),
                                        child: const Icon(
                                          Icons.person,
                                          size: 65,
                                          color: Colors.white,
                                        ),
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
                                    : Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Transform.translate(
                                    offset: const Offset(-2, 6),
                                    child: const Icon(
                                      Icons.person,
                                      size: 65,
                                      color: Colors.white,
                                    ),
                                  ),
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
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentChatScreen(receiverId: student['id'].toString(),
                                    receiverName: studentName,)));
                                }, icon: const Icon(Icons.message, color: Color(0xff0f766e),))),
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