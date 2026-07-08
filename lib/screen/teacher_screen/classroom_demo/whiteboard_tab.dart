import 'package:flutter/material.dart';

// Drawing Point Model to track individual strokes
class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class WhiteboardTab extends StatefulWidget {
  const WhiteboardTab({super.key});

  @override
  State<WhiteboardTab> createState() => _WhiteboardTabState();
}

class _WhiteboardTabState extends State<WhiteboardTab> {
  // Drawing States
  List<DrawingPoint?> _points = [];
  final List<List<DrawingPoint?>> _undoHistory = [];
  final List<List<DrawingPoint?>> _redoHistory = [];

  // Default Customization States (As per your UI image)
  Color _selectedColor = const Color(0xff0f766e);
  double _strokeWidth = 8.0;
  double _strokeAlpha = 1.0; // 1.0 means 100% opacity, image shows 0% but we use dynamic slider

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Whiteboard main canvas screen
      body: Column(
        children: [
          // 1. TOP DRAWING CANVAS (Interactive Drawing Area)
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  // Save for Undo before starting new stroke
                  _undoHistory.add(List.from(_points));
                  _redoHistory.clear(); // Clear redo on new action

                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  _points.add(DrawingPoint(
                    offset: renderBox.globalToLocal(details.globalPosition),
                    paint: Paint()
                      ..color = _selectedColor.withOpacity(_strokeAlpha)
                      ..strokeWidth = _strokeWidth
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true,
                  ));
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  _points.add(DrawingPoint(
                    offset: renderBox.globalToLocal(details.globalPosition),
                    paint: Paint()
                      ..color = _selectedColor.withOpacity(_strokeAlpha)
                      ..strokeWidth = _strokeWidth
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true,
                  ));
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(null); // Line break between strokes
                });
              },
              child: CustomPaint(
                painter: WhiteboardPainter(pointsList: _points),
                size: Size.infinite,
              ),
            ),
          ),

          // 2. BOTTOM CONTROLS PANEL (Exactly styled like your attached screenshot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            color: const Color(0xff2d2d2d), // Dark Grey control panel background
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Sliders for Stroke Width & Stroke Alpha
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stroke Width (${_strokeWidth.toInt()})",
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          Slider(
                            value: _strokeWidth,
                            min: 2.0,
                            max: 40.0,
                            activeColor: const Color(0xff0f766e),
                            inactiveColor: Colors.black,
                            onChanged: (val) => setState(() => _strokeWidth = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stroke Alpha (${(_strokeAlpha * 100).toInt()}%)",
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          Slider(
                            value: _strokeAlpha,
                            min: 0.0,
                            max: 1.0,
                            activeColor: const Color(0xff0f766e),
                            inactiveColor: Colors.black,
                            onChanged: (val) => setState(() => _strokeAlpha = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Row 2: Undo, Redo, and Clear All buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _undoHistory.isNotEmpty ? _undo : null,
                      child: Text(
                        "Undo ( ${_undoHistory.length} )",
                        style: TextStyle(color: _undoHistory.isNotEmpty ? Colors.white : Colors.grey, fontSize: 15),
                      ),
                    ),
                    TextButton(
                      onPressed: _redoHistory.isNotEmpty ? _redo : null,
                      child: Text(
                        "Redo ( ${_redoHistory.length} )",
                        style: TextStyle(color: _redoHistory.isNotEmpty ? Colors.white : Colors.grey, fontSize: 15),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text(
                        "Clear All",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Row 3: Color Chooser, Pencil Mode Indicator, & Target Alphabet Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Color Palette Button
                    GestureDetector(
                      onTap: _showColorPicker,
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text("Color", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),

                    // Active Tool Box (Pencil indicator)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff0f766e),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 28),
                    ),

                    // Arabic Letter preview target helper (e.g. ض)
                    const Text(
                      "ض",
                      style: TextStyle(
                        fontFamily: 'QuranFont',
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS LOGIC ---
  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(List.from(_points));
        _points = _undoHistory.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _undoHistory.add(List.from(_points));
        _points = _redoHistory.removeLast();
      });
    }
  }

  void _clearAll() {
    setState(() {
      _undoHistory.add(List.from(_points));
      _redoHistory.clear();
      _points.clear();
    });
  }

  void _showColorPicker() {
    List<Color> colors = [const Color(0xff0f766e), Colors.red, Colors.blue, Colors.black, Colors.orange, Colors.purple];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff2d2d2d),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 120,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              setState(() => _selectedColor = colors[index]);
              Navigator.pop(context);
            },
            child: CircleAvatar(backgroundColor: colors[index]),
          ),
        ),
      ),
    );
  }
}

// Custom Painter to efficiently render drawing strokes on board
class WhiteboardPainter extends CustomPainter {
  final List<DrawingPoint?> pointsList;
  WhiteboardPainter({required this.pointsList});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(
          pointsList[i]!.offset,
          pointsList[i + 1]!.offset,
          pointsList[i]!.paint,
        );
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        // Handle single isolated tap points
        canvas.drawCircle(
          pointsList[i]!.offset,
          pointsList[i]!.paint.strokeWidth / 2,
          pointsList[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) => true;
}