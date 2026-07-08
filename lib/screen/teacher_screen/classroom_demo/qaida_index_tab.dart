import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// =========================================================================
// 🔥 MUKAMMAL QUTOR-STYLE NOORANI QAIDA DATA (All Important Lessons & Pages)
// =========================================================================
class QaidaLessonModel {
  final int id;
  final int lessonNumber;
  final String titleEnglish;
  final String titleArabic;
  final int totalPages;
  final List<Map<String, dynamic>> words;

  QaidaLessonModel({
    required this.id,
    required this.lessonNumber,
    required this.titleEnglish,
    required this.titleArabic,
    required this.totalPages,
    required this.words,
  });
}

final List<QaidaLessonModel> completeNooraniQaida = [
  // --- LESSON 1: Huroof e Mufradat (Page 1 - 2) ---
  QaidaLessonModel(
    id: 1,
    lessonNumber: 1,
    titleEnglish: "Lesson 1: Alphabets",
    titleArabic: "حُرُوفُ الْهِجَاءِ الْمُفْرَدَةِ",
    totalPages: 2,
    words: [
      // Page 1
      {"word_arabic": "ا", "word_name": "أَلِف", "page": 1, "audio": "https://server8.mp3quran.net/afs/001.mp3"},
      {"word_arabic": "ب", "word_name": "بَا", "page": 1, "audio": null},
      {"word_arabic": "ت", "word_name": "تَا", "page": 1, "audio": null},
      {"word_arabic": "ث", "word_name": "ثَا", "page": 1, "audio": null},
      {"word_arabic": "ج", "word_name": "جِيم", "page": 1, "audio": null},
      {"word_arabic": "ح", "word_name": "حَا", "page": 1, "audio": null},
      {"word_arabic": "خ", "word_name": "خَا", "page": 1, "audio": null},
      {"word_arabic": "د", "word_name": "دَال", "page": 1, "audio": null},
      {"word_arabic": "ذ", "word_name": "ذَال", "page": 1, "audio": null},
      {"word_arabic": "ر", "word_name": "رَا", "page": 1, "audio": null},
      // Page 2
      {"word_arabic": "ز", "word_name": "زَا", "page": 2, "audio": null},
      {"word_arabic": "س", "word_name": "سِين", "page": 2, "audio": null},
      {"word_arabic": "ش", "word_name": "شِين", "page": 2, "audio": null},
      {"word_arabic": "ص", "word_name": "صَاد", "page": 2, "audio": null},
      {"word_arabic": "ض", "word_name": "ضَاد", "page": 2, "audio": null},
      {"word_arabic": "ط", "word_name": "طَا", "page": 2, "audio": null},
      {"word_arabic": "ظ", "word_name": "ظَا", "page": 2, "audio": null},
      {"word_arabic": "ع", "word_name": "عَيْن", "page": 2, "audio": null},
      {"word_arabic": "غ", "word_name": "غَيْن", "page": 2, "audio": null},
      {"word_arabic": "ف", "word_name": "فَا", "page": 2, "audio": null},
      {"word_arabic": "ق", "word_name": "قَاف", "page": 2, "audio": null},
      {"word_arabic": "ك", "word_name": "كَاف", "page": 2, "audio": null},
      {"word_arabic": "ل", "word_name": "لاَم", "page": 2, "audio": null},
      {"word_arabic": "م", "word_name": "مِيم", "page": 2, "audio": null},
      {"word_arabic": "ن", "word_name": "نُون", "page": 2, "audio": null},
      {"word_arabic": "و", "word_name": "وَاو", "page": 2, "audio": null},
      {"word_arabic": "ه", "word_name": "هَا", "page": 2, "audio": null},
      {"word_arabic": "ء", "word_name": "هَمْزَة", "page": 2, "audio": null},
      {"word_arabic": "ی", "word_name": "يَا", "page": 2, "audio": null},
      {"word_arabic": "ے", "word_name": "يَا", "page": 2, "audio": null},
    ],
  ),

  // --- LESSON 2: Huroof e Murakkabat (Page 3 - 5) ---
  QaidaLessonModel(
    id: 2,
    lessonNumber: 2,
    titleEnglish: "Lesson 2: Joint Letters",
    titleArabic: "حُرُوفُ الْهِجَاءِ الْمُرَكَّبَةِ",
    totalPages: 3,
    words: [
      // Page 1 of Lesson 2 (Page 3 Overall)
      {"word_arabic": "لا", "word_name": "لاَم أَلِف", "page": 1, "audio": null},
      {"word_arabic": "بَا", "word_name": "بَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "نَا", "word_name": "نُون أَلِف", "page": 1, "audio": null},
      {"word_arabic": "تَا", "word_name": "تَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "ثَا", "word_name": "ثَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "جَا", "word_name": "جِيم أَلِف", "page": 1, "audio": null},
      {"word_arabic": "حَا", "word_name": "حَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "خَا", "word_name": "خَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "سَا", "word_name": "سِين أَلِف", "page": 1, "audio": null},
      {"word_arabic": "شَا", "word_name": "شِين أَلِف", "page": 1, "audio": null},
      // Page 2 of Lesson 2 (Page 4 Overall)
      {"word_arabic": "بب", "word_name": "بَا بَا", "page": 2, "audio": null},
      {"word_arabic": "بت", "word_name": "بَا تَا", "page": 2, "audio": null},
      {"word_arabic": "بح", "word_name": "بَا حَا", "page": 2, "audio": null},
      {"word_arabic": "بل", "word_name": "بَا لاَم", "page": 2, "audio": null},
      {"word_arabic": "تم", "word_name": "تَا مِيم", "page": 2, "audio": null},
      // Page 3 of Lesson 2 (Page 5 Overall)
      {"word_arabic": "نـن", "word_name": "نُون نُون", "page": 3, "audio": null},
      {"word_arabic": "ثـث", "word_name": "ثَا ثَا", "page": 3, "audio": null},
      {"word_arabic": "تـث", "word_name": "تَا ثَا", "page": 3, "audio": null},
    ],
  ),

  // --- LESSON 3: Huroof e Muqatta'at (Page 6) ---
  QaidaLessonModel(
    id: 3,
    lessonNumber: 3,
    titleEnglish: "Lesson 3: Shortened Letters",
    titleArabic: "حُرُوفُ الْمُقَطَّعَاتِ",
    totalPages: 1,
    words: [
      {"word_arabic": "الٓمٓ", "word_name": "الم", "page": 1, "audio": null},
      {"word_arabic": "الٓمٓصٓ", "word_name": "المص", "page": 1, "audio": null},
      {"word_arabic": "الٓر", "word_name": "الر", "page": 1, "audio": null},
      {"word_arabic": "الٓمٓر", "word_name": "المر", "page": 1, "audio": null},
      {"word_arabic": "كٓهٰيٰعٓصٓ", "word_name": "كهيعص", "page": 1, "audio": null},
      {"word_arabic": "طٰهٰ", "word_name": "طه", "page": 1, "audio": null},
      {"word_arabic": "طٓسٓمٓ", "word_name": "طسم", "page": 1, "audio": null},
      {"word_arabic": "طٰسٓ", "word_name": "طس", "page": 1, "audio": null},
      {"word_arabic": "يٰسٓ", "word_name": "يس", "page": 1, "audio": null},
      {"word_arabic": "صٓ", "word_name": "صاد", "page": 1, "audio": null},
    ],
  ),

  // --- LESSON 4: Harakat (Page 7 - 9) ---
  QaidaLessonModel(
    id: 4,
    lessonNumber: 4,
    titleEnglish: "Lesson 4: Movements (Harakat)",
    titleArabic: "الْحَرَكَاتُ: فَتحَة، كَسْرَة، ضَمَّة",
    totalPages: 1,
    words: [
      {"word_arabic": "أَ", "word_name": "هَمزة فَتحَة", "page": 1, "audio": null},
      {"word_arabic": "إِ", "word_name": "هَمزة كَسْرَة", "page": 1, "audio": null},
      {"word_arabic": "أُ", "word_name": "هَمزة ضَمَّة", "page": 1, "audio": null},
      {"word_arabic": "بَ", "word_name": "بَا فَتحَة", "page": 1, "audio": null},
      {"word_arabic": "بِ", "word_name": "بَا كَسْرَة", "page": 1, "audio": null},
      {"word_arabic": "بُ", "word_name": "بَا ضَمَّة", "page": 1, "audio": null},
    ],
  ),
];

// =========================================================================
// 1. MAIN TAB (Sabaq ki List Screen)
// =========================================================================
class QaidaIndexTab extends StatelessWidget {
  const QaidaIndexTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      body: ListView.builder(
        itemCount: completeNooraniQaida.length,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        itemBuilder: (context, index) {
          final lesson = completeNooraniQaida[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: const Color(0xff0f766e),
                foregroundColor: Colors.white,
                child: Text(lesson.lessonNumber.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(
                lesson.titleEnglish,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1f2937)),
              ),
              subtitle: Text("Total Pages: ${lesson.totalPages}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: Text(
                lesson.titleArabic,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0f766e), fontFamily: 'QuranFont'),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QaidaDetailScreen(lesson: lesson),
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

// =========================================================================
// 2. DETAILED SCREEN (Qutor Book Grid & Board View)
// =========================================================================
class QaidaDetailScreen extends StatefulWidget {
  final QaidaLessonModel lesson;
  const QaidaDetailScreen({super.key, required this.lesson});

  @override
  State<QaidaDetailScreen> createState() => _QaidaDetailScreenState();
}

class _QaidaDetailScreenState extends State<QaidaDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController();

  Map<int, List<Map<String, dynamic>>> _pagesMap = {};
  List<int> _pageNumbers = [];
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _groupWordsByPage();
  }

  void _groupWordsByPage() {
    Map<int, List<Map<String, dynamic>>> temporaryMap = {};
    for (var word in widget.lesson.words) {
      int page = word['page'] ?? 1;
      if (!temporaryMap.containsKey(page)) {
        temporaryMap[page] = [];
      }
      temporaryMap[page]!.add(word);
    }
    setState(() {
      _pagesMap = temporaryMap;
      _pageNumbers = temporaryMap.keys.toList()..sort();
    });
  }

  Future<void> _playAudio(String? url) async {
    if (url == null) return;
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print("Audio Play Error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String getArabicLessonNumber(int num) {
      List<String> arabicNumbers = ["الأَوَّل", "الثَّانِي", "الثَّالِث", "الرَّابِع", "الْخَامِس"];
      return num <= arabicNumbers.length ? "اَلدَّرْسُ ${arabicNumbers[num - 1]}" : "اَلدَّرْسُ $num";
    }

    return Scaffold(
      backgroundColor: const Color(0xfffcfdfa),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: Text(widget.lesson.titleEnglish),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Bismillah
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'QuranFont', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),

            // 2. Dynamic Banner Ribbon (Red & Green Split Like Book Picture)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xffa81c1c),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                      ),
                      child: Text(
                        widget.lesson.titleArabic,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'QuranFont'),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xff064e3b),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                      ),
                      child: Text(
                        getArabicLessonNumber(widget.lesson.lessonNumber),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'QuranFont'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Main Book Board View (PageView)
            Expanded(
              child: _pageNumbers.isEmpty
                  ? const Center(child: Text("Loading Qaida Grid..."))
                  : PageView.builder(
                controller: _pageController,
                itemCount: _pageNumbers.length,
                reverse: true, // Right to left book swiping
                onPageChanged: (index) => setState(() => _currentPageIndex = index),
                itemBuilder: (context, pageIndex) {
                  int currentPageNumber = _pageNumbers[pageIndex];
                  List<Map<String, dynamic>> currentPageWords = _pagesMap[currentPageNumber] ?? [];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: GridView.builder(
                        itemCount: currentPageWords.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 🔥 Qutor/Real Qaida layout structure
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final item = currentPageWords[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300, width: 0.5),
                            ),
                            child: InkWell(
                              onTap: () => _playAudio(item['audio']),
                              child: Stack(
                                children: [
                                  if (item['word_name'] != null)
                                    Positioned(
                                      top: 4,
                                      left: 6,
                                      child: Text(
                                        item['word_name'],
                                        style: const TextStyle(color: Color(0xffdc2626), fontSize: 9, fontFamily: 'QuranFont', fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        item['word_arabic'],
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'QuranFont', color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Bottom Qutor Navigation Page Controllers
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xff0f766e), size: 22),
                    onPressed: _currentPageIndex < _pageNumbers.length - 1
                        ? () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      "${(_currentPageIndex + 1).toString().padLeft(2, '0')} / ${widget.lesson.totalPages.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Color(0xff0f766e), size: 22),
                    onPressed: _currentPageIndex > 0
                        ? () => _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                        : null,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}