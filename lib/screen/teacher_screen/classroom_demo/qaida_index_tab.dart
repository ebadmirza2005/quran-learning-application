import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// =========================================================================
// 🔥 MUKAMMAL PRODUCTION-READY DATA MODEL
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

// Helper wrapper to process book-wide global page flattening
class FlatPageModel {
  final QaidaLessonModel lesson;
  final int pageWithinLesson;
  final List<Map<String, dynamic>> words;

  FlatPageModel({
    required this.lesson,
    required this.pageWithinLesson,
    required this.words,
  });
}

// =========================================================================
// 🗂️ COMPLETELY FLATTENED 27-PAGES MAPPED NOORANI QAIDA DATABASE
// =========================================================================
final List<QaidaLessonModel> completeNooraniQaida = [
  // --- LESSON 1: Huroof e Mufradat (Page 1 - 2) ---
  QaidaLessonModel(
    id: 1, lessonNumber: 1,
    titleEnglish: "Lesson 1: Individual Alphabets",
    titleArabic: "حُرُوفُ الْهِجَاءِ الْمُفْرَدَةِ",
    totalPages: 2,
    words: [
      // Page 1
      {"word_arabic": "ا", "word_name": "أَلِف", "page": 1, "audio": null},
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
    id: 2, lessonNumber: 2,
    titleEnglish: "Lesson 2: Joint Letters",
    titleArabic: "حُرُوفُ الْهِجَاءِ الْمُرَكَّبَةِ",
    totalPages: 3,
    words: [
      // Page 3
      {"word_arabic": "لا", "word_name": "لاَم أَلِف", "page": 1, "audio": null},
      {"word_arabic": "بَا", "word_name": "بَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "نَا", "word_name": "نُون أَلِف", "page": 1, "audio": null},
      {"word_arabic": "تَا", "word_name": "تَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "ثَا", "word_name": "ثَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "جَا", "word_name": "جِيم أَلِف", "page": 1, "audio": null},
      {"word_arabic": "حَا", "word_name": "حَا أَلِف", "page": 1, "audio": null},
      {"word_arabic": "خَا", "word_name": "خَا أَلِف", "page": 1, "audio": null},
      // Page 4
      {"word_arabic": "بب", "word_name": "بَا بَا", "page": 2, "audio": null},
      {"word_arabic": "بت", "word_name": "بَا تَا", "page": 2, "audio": null},
      {"word_arabic": "بح", "word_name": "بَا حَا", "page": 2, "audio": null},
      {"word_arabic": "بل", "word_name": "بَا لاَم", "page": 2, "audio": null},
      {"word_arabic": "تم", "word_name": "تَا مِيم", "page": 2, "audio": null},
      // Page 5
      {"word_arabic": "نـن", "word_name": "نُون نُون", "page": 3, "audio": null},
      {"word_arabic": "ثـث", "word_name": "ثَا ثَا", "page": 3, "audio": null},
      {"word_arabic": "تـث", "word_name": "تَا ثَا", "page": 3, "audio": null},
    ],
  ),

  // --- LESSON 3: Huroof e Muqatta'at (Page 6) ---
  QaidaLessonModel(
    id: 3, lessonNumber: 3,
    titleEnglish: "Lesson 3: Shortened Letters",
    titleArabic: "حُرُوفُ الْمُقَطَّعَاتِ",
    totalPages: 1,
    words: [
      {"word_arabic": "الٓمٓ", "word_name": "الم", "page": 1, "audio": null},
      {"word_arabic": "الٓمٓصٓ", "word_name": "المص", "page": 1, "audio": null},
      {"word_arabic": "الٓر", "word_name": "الر", "page": 1, "audio": null},
      {"word_arabic": "الٓمٓر", "word_name": "المر", "page": 1, "audio": null},
      {"word_arabic": "كٓهٰيٰعٓصٓ", "word_name": "كهيعص", "page": 1, "audio": null},
      {"word_arabic": "طٰهٰ", "word_name": "طه", "page": 1, "audio": null},
    ],
  ),

  // --- LESSON 4: Harakat (Page 7 - 8) ---
  QaidaLessonModel(
    id: 4, lessonNumber: 4,
    titleEnglish: "Lesson 4: Movements (Harakat)",
    titleArabic: "الْحَرَكَاتُ",
    totalPages: 2,
    words: [
      // Page 7
      {"word_arabic": "أَ", "word_name": "هَمْزَة فَتحَة", "page": 1, "audio": null},
      {"word_arabic": "إِ", "word_name": "هَمْزَة كَسْرَة", "page": 1, "audio": null},
      {"word_arabic": "أُ", "word_name": "هَمْزَة ضَمَّة", "page": 1, "audio": null},
      {"word_arabic": "بَ", "word_name": "بَا فَتحَة", "page": 1, "audio": null},
      {"word_arabic": "بِ", "word_name": "بَا كَسْرَة", "page": 1, "audio": null},
      {"word_arabic": "بُ", "word_name": "بَا ضَمَّة", "page": 1, "audio": null},
      // Page 8
      {"word_arabic": "تَ", "word_name": "تَا فَتحَة", "page": 2, "audio": null},
      {"word_arabic": "تِ", "word_name": "تَا كَسْرَة", "page": 2, "audio": null},
      {"word_arabic": "تُ", "word_name": "تَا ضَمَّة", "page": 2, "audio": null},
    ],
  ),

  // --- LESSON 5: Tanween (Page 9 - 10) ---
  QaidaLessonModel(
    id: 5, lessonNumber: 5,
    titleEnglish: "Lesson 5: Double Movements (Tanween)",
    titleArabic: "التَّنْوِينُ: فَتْحَتَانِ كَسْرَتَانِ ضَمَّتَانِ",
    totalPages: 2,
    words: [
      {"word_arabic": "اً", "word_name": "مِيم فَتْحَتَانِ", "page": 1, "audio": null},
      {"word_arabic": "ٍ", "word_name": "مِيم كَسْرَتَانِ", "page": 1, "audio": null},
      {"word_arabic": "ٌ", "word_name": "مِيم ضَمَّتَانِ", "page": 1, "audio": null},
      {"word_arabic": "باً", "word_name": "بَا فَتْحَتَانِ", "page": 2, "audio": null},
      {"word_arabic": "بٍ", "word_name": "بَا كَسْرَتَانِ", "page": 2, "audio": null},
      {"word_arabic": "بٌ", "word_name": "بَا ضَمَّتَانِ", "page": 2, "audio": null},
    ],
  ),

  // --- LESSON 6: Exercises of Harakat & Tanween (Page 11 - 13) ---
  QaidaLessonModel(
    id: 6, lessonNumber: 6,
    titleEnglish: "Lesson 6: Mashq (Exercises)",
    titleArabic: "تَمْرِيناتٌ عَلَی الْحَرَكَاتِ وَالتَّنْوِينِ",
    totalPages: 3,
    words: [
      {"word_arabic": "أَبَدًا", "word_name": "أَبَدًا", "page": 1, "audio": null},
      {"word_arabic": "أَحَدٌ", "word_name": "أَحَدٌ", "page": 1, "audio": null},
      {"word_arabic": "أَخَذَ", "word_name": "أَخَذَ", "page": 2, "audio": null},
      {"word_arabic": "بَرَرَةٍ", "word_name": "بَرَرَةٍ", "page": 2, "audio": null},
      {"word_arabic": "جَعَلَ", "word_name": "جَعَلَ", "page": 3, "audio": null},
      {"word_arabic": "حَسَدَ", "word_name": "حَسَدَ", "page": 3, "audio": null},
    ],
  ),

  // --- LESSON 7: Khari Harakat (Page 14 - 15) ---
  QaidaLessonModel(
    id: 7, lessonNumber: 7,
    titleEnglish: "Lesson 7: Vertical Movements",
    titleArabic: "الْحَرَكَاتُ الْقَائِمَةُ",
    totalPages: 2,
    words: [
      {"word_arabic": "هٰذَا", "word_name": "خَارَا فَتحَة", "page": 1, "audio": null},
      {"word_arabic": "ذٰلِكَ", "word_name": "ذَال خَارَا", "page": 2, "audio": null},
    ],
  ),

  // --- LESSON 8: Huroof Maddah o Leen (Page 16 - 18) ---
  QaidaLessonModel(
    id: 8, lessonNumber: 8,
    titleEnglish: "Lesson 8: Letters of Madd & Leen",
    titleArabic: "حُرُوفُ الْمَدَّ وَاللِّينِ",
    totalPages: 3,
    words: [
      {"word_arabic": "بَا", "word_name": "بَا أَلِف مَدّ", "page": 1, "audio": null},
      {"word_arabic": "بُو", "word_name": "بَا وَاو مَدّ", "page": 2, "audio": null},
      {"word_arabic": "بِي", "word_name": "بَا يَا مَدّ", "page": 3, "audio": null},
    ],
  ),

  // --- LESSON 9: Exercises of Madd, Leen & Khari Harakat (Page 19 - 21) ---
  QaidaLessonModel(
    id: 9, lessonNumber: 9,
    titleEnglish: "Lesson 9: Combined Long Vowels Exercises",
    titleArabic: "تَمْرِيناتٌ عَلَی الْمَدِّ وَاللِّينِ",
    totalPages: 3,
    words: [
      {"word_arabic": "آمَنَ", "word_name": "آمَنَ", "page": 1, "audio": null},
      {"word_arabic": "أُوْتِيَ", "word_name": "أُوْتِيَ", "page": 2, "audio": null},
      {"word_arabic": "جَاءَ", "word_name": "جَاءَ", "page": 3, "audio": null},
    ],
  ),

  // --- LESSON 10: Sukoon / Jazam (Page 22 - 24) ---
  QaidaLessonModel(
    id: 10, lessonNumber: 10,
    titleEnglish: "Lesson 10: Sukoon (Quiescence)",
    titleArabic: "السُّكُونُ (الْجَزْمُ)",
    totalPages: 3,
    words: [
      {"word_arabic": "أَبْ", "word_name": "هَمْزَة بَا فَتْحَ بَبْ", "page": 1, "audio": null},
      {"word_arabic": "أَتْ", "word_name": "هَمْزَة تَا فَتْحَ تَتْ", "page": 2, "audio": null},
      {"word_arabic": "أَثْ", "word_name": "هَمْزَة ثَا فَتْحَ ثَثْ", "page": 3, "audio": null},
    ],
  ),

  // --- LESSON 11: Exercises of Sukoon (Page 25 - 27) ---
  QaidaLessonModel(
    id: 11, lessonNumber: 11,
    titleEnglish: "Lesson 11: Exercises of Sukoon",
    titleArabic: "تَمْرِيناتٌ عَلَی السُّكُونِ",
    totalPages: 3,
    words: [
      {"word_arabic": "خَلَقْنَا", "word_name": "خَلَقْنَا", "page": 1, "audio": null},
      {"word_arabic": "مِنْ عِلْمٍ", "word_name": "مِنْ عِلْمٍ", "page": 2, "audio": null},
      {"word_arabic": "وَانْحَرْ", "word_name": "وَانْحَرْ", "page": 3, "audio": null},
    ],
  ),
];

// =========================================================================
// 1. DUAL CODE APP DESIGN - BOARD & BOOK INTEGRATED TAB
// =========================================================================
class QaidaIndexTab extends StatefulWidget {
  const QaidaIndexTab({super.key});

  @override
  State<QaidaIndexTab> createState() => _QaidaIndexTabState();
}

class _QaidaIndexTabState extends State<QaidaIndexTab> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController();

  List<FlatPageModel> _globalPages = [];
  int _currentPageIndex = 0;

  // Drawing States (Whiteboard Integration variables)
  final List<Offset?> _points = [];
  Color _selectedColor = const Color(0xffdc2626);
  double _strokeWidth = 6.0;
  bool _isWhiteboardActive = false; // Toggle tool layer over current word cells

  @override
  void initState() {
    super.initState();
    _flattenQaidaPages();
  }

  void _flattenQaidaPages() {
    List<FlatPageModel> tempPages = [];
    for (var lesson in completeNooraniQaida) {
      for (int p = 1; p <= lesson.totalPages; p++) {
        var pageWords = lesson.words.where((w) => (w['page'] ?? 1) == p).toList();
        if (pageWords.isNotEmpty) {
          tempPages.add(FlatPageModel(
            lesson: lesson,
            pageWithinLesson: p,
            words: pageWords,
          ));
        }
      }
    }
    setState(() {
      _globalPages = tempPages;
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

  String getArabicLessonNumber(int num) {
    List<String> arabicNumbers = ["الأَوَّل", "الثَّانِي", "الثَّالِث", "الرَّابِع", "الْخَامِس", "السَّادِس", "السَّابِع", "الثَّامِن", "التَّاسِع", "العَاشِر", "الحَادِي عَشَر"];
    return num <= arabicNumbers.length ? "اَلدَّرْسُ ${arabicNumbers[num - 1]}" : "اَلدَّرْسُ $num";
  }

  @override
  Widget build(BuildContext context) {
    if (_globalPages.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xff0f766e))));
    }

    final currentFlatPage = _globalPages[_currentPageIndex];
    final currentLesson = currentFlatPage.lesson;

    return Scaffold(
      backgroundColor: const Color(0xfffcfdfa),
      // Action button to trigger live canvas annotation mode toggle
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        title: const Text("Qutor Interactive Classroom", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isWhiteboardActive ? Icons.edit_off : Icons.border_color, color: Colors.white),
            onPressed: () => setState(() {
              _isWhiteboardActive = !_isWhiteboardActive;
              _points.clear(); // clear lines on mode toggle
            }),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bismillah
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),

            // 2. Adaptive Split Ribbon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
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
                        currentLesson.titleArabic,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
                        getArabicLessonNumber(currentLesson.lessonNumber),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Live Integrated Custom Painter Canvas Layer + Book Swiper
            Expanded(
              child: Stack(
                children: [
                  // Underlying structural book pages view
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _globalPages.length,
                    reverse: true, // Right to left flipping
                    onPageChanged: (index) => setState(() {
                      _currentPageIndex = index;
                      _points.clear(); // Auto-clean markings when moving pages
                    }),
                    itemBuilder: (context, pageIndex) {
                      final pageData = _globalPages[pageIndex];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16,),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: GridView.builder(
                            itemCount: pageData.words.length,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) {
                              final item = pageData.words[index];
                              return Container(
                                color: Colors.white,
                                child: InkWell(
                                  onTap: _isWhiteboardActive ? null : () => _playAudio(item['audio']),
                                  child: Stack(
                                    children: [
                                      if (item['word_name'] != null)
                                        Positioned(
                                          top: 4,
                                          left: 6,
                                          child: Text(
                                            item['word_name'],
                                            style: const TextStyle(color: Color(0xffdc2626), fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      Center(
                                        child: Text(
                                          item['word_arabic'],
                                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
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

                  // Transparent overlay canvas drawing layer for tracing over letters
                  if (_isWhiteboardActive)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16,),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              RenderBox renderBox = context.findRenderObject() as RenderBox;
                              _points.add(renderBox.globalToLocal(details.globalPosition));
                            });
                          },
                          onPanEnd: (details) => _points.add(null),
                          child: CustomPaint(
                            painter: OverlayWhiteboardPainter(points: _points, strokeColor: _selectedColor, width: _strokeWidth),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 4. Whiteboard Stroke settings overlay block when board tool is active
            if (_isWhiteboardActive)
              Container(
                color: const Color(0xff2d2d2d),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text("Width:", style: TextStyle(color: Colors.white, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 2.0, max: 20.0,
                        activeColor: Colors.teal,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.palette, color: Colors.amber),
                      onPressed: () => setState(() {
                        _selectedColor = (_selectedColor == Colors.red) ? Colors.blue : Colors.red;
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white),
                      onPressed: () => setState(() => _points.clear()),
                    ),
                  ],
                ),
              ),

            // 5. Global Navigation Controllers Block
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xff0f766e), size: 22),
                    onPressed: _currentPageIndex < _globalPages.length - 1
                        ? () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      "${(_currentPageIndex + 1).toString().padLeft(2, '0')} / ${_globalPages.length.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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

// Custom Painter specifically mapped for vector tracking over the Quran Grid layout
class OverlayWhiteboardPainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;
  final double width;

  OverlayWhiteboardPainter({required this.points, required this.strokeColor, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..isAntiAlias = true;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant OverlayWhiteboardPainter oldDelegate) => true;
}