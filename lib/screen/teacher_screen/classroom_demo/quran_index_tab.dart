import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http show get;

import '../../../utils/text.dart';

class QuranIndexTab extends StatefulWidget {
  const QuranIndexTab({super.key});

  @override
  State<QuranIndexTab> createState() => _QuranIndexTabState();
}

class _QuranIndexTabState extends State<QuranIndexTab> {
  bool _isLoading = true;
  final PageController _pageController = PageController();

  final int _wordsPerPage = 38;
  List<List<dynamic>> _quranPages = [];

  List<Map<String, dynamic>> _surahList = [];
  int? _selectedSurahNumber;

  String? _selectedWordId;

  @override
  void initState() {
    super.initState();
    _fetchAndProcessQuran();
    _pageController.addListener(() {
      if (_quranPages.isNotEmpty) {
        int currentPage = _pageController.page?.round() ?? 0;
        if (currentPage < _quranPages.length && _quranPages[currentPage].isNotEmpty) {
          int currentSurahNum = _quranPages[currentPage].first['surahNumber'];
          if (_selectedSurahNumber != currentSurahNum) {
            setState(() {
              _selectedSurahNumber = currentSurahNum;
            });
          }
        }
      }
    });
  }

  void _showFilter() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                children: [
                  Row(
                    children: [
                      TextWidget(text: "Surah", textSize: 14),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xff0f766e), width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedSurahNumber,
                              hint: const Text("سورہ منتخب کریں"),
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              onChanged: (int? newSurahNumber) {
                                if (newSurahNumber != null) {
                                  setDialogState(() {
                                    _selectedSurahNumber = newSurahNumber;
                                  });
                                  setState(() {
                                    _selectedSurahNumber = newSurahNumber;
                                  });

                                  final targetSurah = _surahList.firstWhere((s) => s['number'] == newSurahNumber);
                                  int targetPage = targetSurah['startPageIndex'];
                                  _pageController.jumpToPage(targetPage);
                                }
                              },
                              items: _surahList.map((surah) {
                                return DropdownMenuItem<int>(
                                  value: surah['number'],
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "${surah['number']}. ${surah['name']}",
                                      style: const TextStyle(
                                        fontFamily: 'QuranFont',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      TextWidget(text: "Ayah", textSize: 14),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xff0f766e), width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: null,
                              hint: const Text("آیت منتخب کریں"),
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              onChanged: (int? newAyahNumber) {
                                if (newAyahNumber != null && _selectedSurahNumber != null) {
                                  int targetPageIndex = -1;

                                  for (int i = 0; i < _quranPages.length; i++) {
                                    bool hasAyah = _quranPages[i].any((ayah) =>
                                    ayah['surahNumber'] == _selectedSurahNumber &&
                                        ayah['numberInSurah'] == newAyahNumber
                                    );

                                    if (hasAyah) {
                                      targetPageIndex = i;
                                      break;
                                    }
                                  }

                                  if (targetPageIndex != -1) {
                                    _pageController.jumpToPage(targetPageIndex);
                                  }
                                }
                              },
                              items: _selectedSurahNumber != null
                                  ? () {
                                final matchingPage = _quranPages.firstWhere(
                                      (page) => page.isNotEmpty && page.first['surahNumber'] == _selectedSurahNumber,
                                  orElse: () => [],
                                );

                                if (matchingPage.isEmpty) return <DropdownMenuItem<int>>[];

                                int totalAyahs = matchingPage.first['totalAyahs'] ?? 0;

                                return List.generate(
                                  totalAyahs,
                                      (index) => DropdownMenuItem<int>(
                                    value: index + 1,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "آیت ${index + 1}",
                                        style: const TextStyle(
                                          fontFamily: 'QuranFont',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }()
                                  : [],
                            ),
                          ),
                        ),
                      )
                    ]
                  )
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: TextWidget(text: 'Close', textColor: Color(0xff0f766e), textWeight: FontWeight.bold)
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAndProcessQuran() async {
    try {
      final response = await http.get(Uri.parse("https://api.alquran.cloud/v1/quran/quran-uthmani"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<List<dynamic>> finalPages = [];
        List<Map<String, dynamic>> tempSurahList = [];
        for (var surah in data['data']['surahs']) {
          List<dynamic> surahAyahs = List.from(surah['ayahs']);
          int totalAyahsInSurah = surahAyahs.length;
          int surahNumber = surah['number'];
          String surahName = surah['name'];

          int surahStartPageIndex = finalPages.length;
          tempSurahList.add({
            'number': surahNumber,
            'name': surahName,
            'startPageIndex': surahStartPageIndex,
          });

          if (surahAyahs.isNotEmpty) {
            if (surahNumber == 1) {
              surahAyahs.removeAt(0);
              totalAyahsInSurah = surahAyahs.length;
              for (int i = 0; i < surahAyahs.length; i++) {
                surahAyahs[i]['numberInSurah'] = i + 1;
              }
            }
            else if (surahNumber != 9) {
              String firstAyahText = surahAyahs[0]['text'] ?? "";

              if (firstAyahText.trim().startsWith("بِسْمِ")) {
                List<String> wordsList = firstAyahText.trim().split(RegExp(r'\s+'));
                if (wordsList.length >= 4) {
                  surahAyahs[0]['text'] = wordsList.sublist(4).join(" ").trim();
                }
              }
            }
          }

          List<dynamic> formattedAyahs = surahAyahs.map((ayah) {
            return {
              'text': ayah['text'],
              'surahName': surahName,
              'numberInSurah': ayah['numberInSurah'],
              'surahNumber': surahNumber,
              'totalAyahs': totalAyahsInSurah,
            };
          }).toList();

          if (totalAyahsInSurah <= 5) {
            finalPages.add(formattedAyahs);
          } else {
            List<dynamic> currentPage = [];
            int currentWordCount = 0;

            for (var ayah in formattedAyahs) {
              currentPage.add(ayah);
              String text = ayah['text'] ?? "";
              currentWordCount += text.split(' ').length;

              if (currentWordCount >= _wordsPerPage) {
                finalPages.add(List.from(currentPage));
                currentPage.clear();
                currentWordCount = 0;
              }
            }
            if (currentPage.isNotEmpty) {
              finalPages.add(currentPage);
            }
          }
        }

        // 🔥 FIXED: setState ke andar _surahList initialize karna lazmi tha
        setState(() {
          _quranPages = finalPages;
          _surahList = tempSurahList;
          if (_surahList.isNotEmpty) {
            _selectedSurahNumber = _surahList.first['number'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network Error: $e")));
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f4f0),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        title: const Text("Al-Quran Al-Kareem", style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _showFilter,
          )
        ],
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _selectedWordId = null;
          });
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)))
            : SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController,
              reverse: false,
              itemCount: _quranPages.length,
              itemBuilder: (context, pageIndex) {
                final pageAyahs = _quranPages[pageIndex];
                if (pageAyahs.isEmpty) return const SizedBox();

                final firstAyah = pageAyahs.first;
                final String currentSurahHeader = firstAyah['surahName'] ?? "";
                final int surahNumber = firstAyah['surahNumber'] ?? 0;
                final int numberInSurah = firstAyah['numberInSurah'] ?? 0;

                bool showTopBismillah = (numberInSurah == 1 && surahNumber != 9);

                List<InlineSpan> inlineSpans = [];

                for (var ayah in pageAyahs) {
                  String cleanText = ayah['text'] ?? "";
                  List<String> words = cleanText.split(RegExp(r'\s+'));
                  int ayahNo = ayah['numberInSurah'];

                  for (int i = 0; i < words.length; i++) {
                    String word = words[i];
                    if (word.isEmpty) continue;

                    String wordId = "$surahNumber-$ayahNo-$i-$word";
                    bool isSelected = _selectedWordId == wordId;

                    inlineSpans.add(
                      TextSpan(
                        text: "$word ",
                        style: TextStyle(
                          fontFamily: 'QuranFont',
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black,
                          height: 1.8,
                          leadingDistribution: TextLeadingDistribution.even,
                          background: isSelected
                              ? (Paint()
                            ..color = const Color(0xff0f766e)
                            ..style = PaintingStyle.fill
                            ..strokeWidth = 0)
                              : null,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            setState(() {
                              _selectedWordId = isSelected ? null : wordId;
                            });
                          },
                      ),
                    );
                  }

                  inlineSpans.add(
                    TextSpan(
                      text: " ﴿$ayahNo﴾ ",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'QuranFont',
                        color: const Color(0xff0f766e).withOpacity(0.8),
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xfffffdf9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xff854d0e), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, spreadRadius: 1)
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentSurahHeader,
                            style: const TextStyle(fontFamily: 'QuranFont', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              "صفحة ${pageIndex + 1}",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xff854d0e), thickness: 0.5),

                      if (showTopBismillah)
                        const Column(
                          children: [
                            SizedBox(height: 5),
                            Text(
                              "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'QuranFont',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 5),
                            Divider(color: Colors.black12, indent: 40, endIndent: 40, thickness: 0.5),
                          ],
                        ),

                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Text.rich(
                              TextSpan(children: inlineSpans),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}