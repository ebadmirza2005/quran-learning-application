import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http show get;
import '../../../utils/text.dart';

class QuranIndexTab extends StatefulWidget {
  const QuranIndexTab({super.key});

  @override
  State<QuranIndexTab> createState() => _QuranIndexTabState();
}

class _QuranIndexTabState extends State<QuranIndexTab> {
  List _surahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
  }

  Future<void> _fetchSurahs() async {
    try {
      final response = await  http.get(Uri.parse("https://api.alquran.cloud/v1/surah"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _surahs = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Fetching Quran: $e")));
      }
      print("Error Fetching Quran: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)))
          : ListView.builder(
        itemCount: _surahs.length,
        itemBuilder: (context, index) {
          final surah = _surahs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xff0f766e),
                foregroundColor: Colors.white,
                child: Text(surah['number'].toString()),
              ),
              title: TextWidget(text: surah['englishName'], textWeight: FontWeight.bold),
              subtitle: TextWidget(text: "${surah['englishNameTranslation']} (${surah['numberOfAyahs']} Ayahs)"),
              trailing: TextWidget(text: surah['name'], textSize: 18, textWeight: FontWeight.bold),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahDetailScreen(
                      surahNumber: surah['number'],
                      surahName: surah['englishName'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- 3. SURAH DETAIL SCREEN ---
class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  const SurahDetailScreen({super.key, required this.surahNumber, required this.surahName});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  List _ayahs = [];
  List _translations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSurahDetails();
  }

  Future<void> _fetchSurahDetails() async {
    try {
      final arabicResponse = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.surahNumber}'));
      final translationResponse = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.surahNumber}/ur.junagarhi'));

      if (arabicResponse.statusCode == 200 && translationResponse.statusCode == 200) {
        final arabicData = json.decode(arabicResponse.body);
        final translationData = json.decode(translationResponse.body);

        setState(() {
          _ayahs = arabicData['data']['ayahs'];
          _translations = translationData['data']['ayahs'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Loading Surah: $e")));
      }
      print("Error Loading Surah: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2ded2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: Text(widget.surahName),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _ayahs.length,
        itemBuilder: (context, index) {
          final translationText = _translations.isNotEmpty ? _translations[index]['text'] : '';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade300,
                      child: Text(_ayahs[index]['numberInSurah'].toString(), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _ayahs[index]['text'],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'QuranFont',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Text(
                    translationText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}