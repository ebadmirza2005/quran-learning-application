import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class QaidaIndexTab extends StatefulWidget {
  const QaidaIndexTab({super.key});

  @override
  State<QaidaIndexTab> createState() => _QaidaIndexTabState();
}

class _QaidaIndexTabState extends State<QaidaIndexTab> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController();

  final int _totalPages = 27;
  int _currentPageIndex = 0;

  final List<Offset?> _points = [];
  Color _selectedColor = const Color(0xffdc2626);
  double _strokeWidth = 6.0;
  bool _isWhiteboardActive = false;

  String getLessonHeaderArabic(int pageNum) {
    if (pageNum <= 2) return "حُرُوفُ الْهِجَاءِ الْمُفْرَدَةِ (Lesson 1)";
    if (pageNum <= 5) return "حُرُوفُ الْهِجَاءِ الْمُرَكَّبَةِ (Lesson 2)";
    if (pageNum == 6) return "حُرُوفُ الْمُقَطَّعَاتِ (Lesson 3)";
    if (pageNum <= 8) return "الْحَرَكَاتُ (Lesson 4)";
    if (pageNum <= 10) return "التَّنْوِينُ (Lesson 5)";
    if (pageNum <= 13) return "تَمْرِيناتٌ عَلَی الْحَرَكَاتِ (Lesson 6)";
    if (pageNum <= 15) return "الْحَرَكَاتُ الْقَائِمَةُ (Lesson 7)";
    if (pageNum <= 18) return "حُرُوفُ الْمَدَّ وَاللِّينِ (Lesson 8)";
    if (pageNum <= 21) return "تَمْرِيناتٌ مُتَنَوِّعَةٌ (Lesson 9-10)";
    if (pageNum <= 24) return "السُّكُونُ وَالْجَزْمُ (Lesson 11-13)";
    return "التَّشْدِيدُ وَمَاشَابَهَ (Lesson 14-17)";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffcfdfa),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        title: const Text("Qutor Interactive Qaida Classroom", style: TextStyle(fontSize: 16, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isWhiteboardActive ? Icons.edit_off : Icons.border_color, color: Colors.white),
            onPressed: () => setState(() {
              _isWhiteboardActive = !_isWhiteboardActive;
              _points.clear();
            }),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bismillah
            // const Padding(
            //   padding: EdgeInsets.symmetric(vertical: 8.0),
            //   child: Text(
            //     "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
            //     textAlign: TextAlign.center,
            //     style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            //   ),
            // ),

            const SizedBox(height: 10),

            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _totalPages,
                    reverse: true, // Book Style Flip
                    onPageChanged: (index) => setState(() {
                      _currentPageIndex = index;
                      _points.clear(); // New page clears the board lines automatically
                    }),
                    itemBuilder: (context, index) {
                      int pageNumber = index + 1;

                      return Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.55,
                          height: MediaQuery.of(context).size.height * 0.55,
                          margin: const EdgeInsets.symmetric(horizontal: 16, ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xff854d0e), width: 1.5),
                          ),
                          child: ClipRRect(
                            child: Image.asset(
                              'assets/qaida/page_$pageNumber.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback UI helper if asset file path is missing during testing
                                return Center(
                                  child: Text(
                                    "Qaida Page $pageNumber\n(Place image inside: assets/qaida/page_$pageNumber.png)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Transparent overlay board canvas for writing/tracing on top of book image
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
                          onPanEnd: (details) => _points.add(null), // Break stroke connection
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

            // 4. Custom Sliders Control Panel (Shows up only when drawing pen tool is active)
            if (_isWhiteboardActive)
              Container(
                color: const Color(0xff2d2d2d),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text("Pen Width:", style: TextStyle(color: Colors.white, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 2.0, max: 20.0,
                        activeColor: Colors.teal.shade400,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.circle, color: _selectedColor, size: 24),
                      onPressed: () => setState(() {
                        // Quick Toggle between essential checking colors
                        if (_selectedColor == Colors.red) {
                          _selectedColor = Colors.blue;
                        } else if (_selectedColor == Colors.blue) {
                          _selectedColor = Colors.green;
                        } else {
                          _selectedColor = Colors.red;
                        }
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white),
                      onPressed: () => setState(() => _points.clear()), // Clear single canvas state
                    ),
                  ],
                ),
              ),

            // 5. Global Book Page Navigation Controllers Block
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xff0f766e), size: 22),
                    onPressed: _currentPageIndex < _totalPages - 1
                        ? () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      "${(_currentPageIndex + 1).toString().padLeft(2, '0')} / ${_totalPages.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
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

// Vector Overlay Painter for smooth handwriting trace lines tracking
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