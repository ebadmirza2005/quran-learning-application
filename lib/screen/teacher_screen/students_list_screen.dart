import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/text.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final supabase = Supabase.instance.client;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: Text("Students"),
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
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];

              String studentName = student['name'] ?? 'No Name';
              String studentEmail = student['email'] ?? 'No Email';
              String location = student['city'] ?? 'Unknown Location';
              String country = student['country'] ?? 'Unknown Country';
              String gender = student['student_gender'] ?? '-';
              String languages = student['languages'] ?? '-';
              List<dynamic> seekingKnowledge = student['seeking_knowledge'] ?? '-';
              String timezone = student['timezone'] ?? '-';

              return Padding(
                padding: const EdgeInsets.only(top: 30.0, bottom: 12.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: SizedBox(
                        height: 240.0,
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 35,),
                            Text(
                              studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text("$location, $country", style: const TextStyle(color: Colors.black45, fontSize: 12)),
                            SizedBox(height: 10,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12)
                                      ),
                                      color: Color(0xff0f766e),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        TextWidget(text: "Gender", textColor: Colors.white,),
                                        TextWidget(text: "Languages", textColor: Colors.white,),
                                        TextWidget(text: "Seeking Knowledge", textColor: Colors.white,),
                                        TextWidget(text: "Timezone", textColor: Colors.white,),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(12)
                                      ),
                                      color: Color(0xff0f766e),
                                    ),

                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        TextWidget(text: gender, textColor: Colors.white),
                                        TextWidget(text: languages, textColor: Colors.white),
                                        TextWidget(text: seekingKnowledge.join(', '), textColor: Colors.white),
                                        TextWidget(text: timezone, textColor: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ),
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
