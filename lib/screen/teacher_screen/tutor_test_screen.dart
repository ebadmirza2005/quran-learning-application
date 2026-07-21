import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tutor_home_screen.dart';

class TutorTestScreen extends StatefulWidget {
  const TutorTestScreen({super.key});

  @override
  State<TutorTestScreen> createState() => _TutorTestScreenState();
}

class _TutorTestScreenState extends State<TutorTestScreen> {
  final supabase = Supabase.instance.client;
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  final Map<String, String> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final List<dynamic> response = await supabase.from('screening_questions').select();

      setState(() {
        List<Map<String, dynamic>> fetchedQuestions = List<Map<String, dynamic>>.from(response);

        fetchedQuestions.shuffle();

        _questions = fetchedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Loading Questions: $e")),
        );
      }
    }
  }

  Future<void> _submitTest() async {
    if (_questions.isEmpty) return;

    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      String questionId = question['id']?.toString() ?? question['question_text'].toString();

      String correctAnswer = question['correct_option'].toString().trim().toUpperCase();
      String? userAnswer = _selectedAnswers[questionId]?.trim().toUpperCase();

      if (userAnswer == correctAnswer) {
        correctCount++;
      }
    }

    String currentTutorId = supabase.auth.currentUser!.id;

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.from('tutors').update({
        'last_test_attempt': DateTime.now().toIso8601String(),
        'test_score': correctCount,
        'verification_status': 'pending',
      }).eq('id', currentTutorId);

      if (mounted) {
        _showReviewPendingDialog(
          title: "Test Submitted Successfully! ⏳",
          message: "Your test has been submitted. Your results are currently under review and will be updated within 12 hours.",
        );

      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Submitting Test: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showReviewPendingDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0f766e),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
              },
              child: const Text("Got It", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xffd2dad2),
        body: Center(child: CircularProgressIndicator(color: Color(0xff0f766e))),
      );
    }
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xffd2dad2),
        appBar: AppBar(
          backgroundColor: const Color(0xff0f766e),
          foregroundColor: Colors.white,
          title: const Text("Screening Test"),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  "No questions available or internet issue.\nPlease check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0f766e)),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchQuestions();
                  },
                  child: const Text("Retry", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    String currentQuestionId = currentQuestion['id']?.toString() ?? currentQuestion['question_text'].toString();

    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: Text("Test Progress (${_currentIndex + 1}/${_questions.length})"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _questions.isEmpty ? 0 : (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.white30,
              color: const Color(0xff0f766e),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion['question_text'] ?? '',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildOptionTile('A', currentQuestion['option_a'] ?? '', currentQuestionId),
                            _buildOptionTile('B', currentQuestion['option_b'] ?? '', currentQuestionId),
                            _buildOptionTile('C', currentQuestion['option_c'] ?? '', currentQuestionId),
                            _buildOptionTile('D', currentQuestion['option_d'] ?? '', currentQuestionId),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text("Back", style: TextStyle(color: Colors.white)),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0f766e)),
                  onPressed: () {
                    if (!_selectedAnswers.containsKey(currentQuestionId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("First select an option before proceeding.")),
                      );
                      return;
                    }
                    if (_currentIndex < _questions.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      _submitTest();
                    }
                  },
                  child: Text(
                    _currentIndex == _questions.length - 1 ? "Submit Test" : "Next",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String optionKey, String optionText, String questionId) {
    bool isSelected = _selectedAnswers[questionId] == optionKey;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff0f766e).withOpacity(0.1) : Colors.transparent,
        border: Border.all(color: isSelected ? const Color(0xff0f766e) : Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        activeColor: const Color(0xff0f766e),
        title: Text(optionText),
        value: optionKey,
        groupValue: _selectedAnswers[questionId],
        onChanged: (value) => setState(() => _selectedAnswers[questionId] = value!),
      ),
    );
  }
}