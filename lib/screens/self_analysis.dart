import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/ai_service.dart';
import '../services/camera_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import '../widgets/tab_header_band.dart';

class _MCQQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String bloomsLevel;
  final String topic;

  _MCQQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.bloomsLevel,
    required this.topic,
  });

  factory _MCQQuestion.fromJson(Map<String, dynamic> json) => _MCQQuestion(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        correctIndex: json['correctIndex'] as int,
        bloomsLevel: json['bloomsLevel'] as String,
        topic: json['topic'] as String? ?? json['bloomsLevel'] as String,
      );
}

class SelfAnalysisScreen extends StatefulWidget {
  final ChildProfile profile;

  const SelfAnalysisScreen({super.key, required this.profile});

  @override
  State<SelfAnalysisScreen> createState() => _SelfAnalysisScreenState();
}

enum _TestStage { setup, loading, inProgress, submitted }

class _SelfAnalysisScreenState extends State<SelfAnalysisScreen> {
  static const int _testDurationSeconds = 15 * 60;

  _TestStage _stage = _TestStage.setup;
  String? _weeklyContentBase64;
  String? _error;

  List<_MCQQuestion> _questions = [];
  List<int?> _selectedAnswers = [];
  int _currentIndex = 0;

  Timer? _timer;
  int _secondsRemaining = _testDurationSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _uploadWeeklyContent() async {
    final base64Image = await CameraService.pickFromGallery();
    if (base64Image != null) {
      setState(() => _weeklyContentBase64 = base64Image);
    }
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _stage = _TestStage.loading;
      _error = null;
    });

    final name = widget.profile.name.isEmpty ? 'the child' : widget.profile.name;
    final age = widget.profile.age;
    final grade = widget.profile.grade;
    final language = widget.profile.language;
    final imageToUse = _weeklyContentBase64 ?? widget.profile.bookImageBase64;

    final prompt = """
You are an educational AI for rural Indian students.
A child named $name, age $age, in $grade, prefers $language.

Based on the uploaded content, generate exactly 15 multiple choice
questions covering all levels of Bloom's Taxonomy (Remember, Understand,
Apply, Analyze, Evaluate, Create), at a difficulty appropriate for this age.

Respond with ONLY a JSON array (no markdown, no extra text) of 15 objects,
each with this exact shape:
{
  "question": "string",
  "options": ["string", "string", "string", "string"],
  "correctIndex": 0,
  "bloomsLevel": "Remember",
  "topic": "short topic name"
}
Questions and options must be written in $language.
""";

    try {
      final result = await AIService.callGemma4(prompt, imageBase64: imageToUse);
      final cleaned = result
          .replaceAll(RegExp(r'```json'), '')
          .replaceAll(RegExp(r'```'), '')
          .trim();
      final List<dynamic> parsed = jsonDecode(cleaned);
      final questions = parsed
          .map((q) => _MCQQuestion.fromJson(q as Map<String, dynamic>))
          .toList();

      if (questions.isEmpty) {
        throw Exception('No questions returned');
      }

      setState(() {
        _questions = questions;
        _selectedAnswers = List<int?>.filled(questions.length, null);
        _currentIndex = 0;
        _secondsRemaining = _testDurationSeconds;
        _stage = _TestStage.inProgress;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _error = 'Could not generate the test. Please try again.';
        _stage = _TestStage.setup;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _stage = _TestStage.submitted;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _selectAnswer(int optionIndex) {
    setState(() => _selectedAnswers[_currentIndex] = optionIndex);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _submitTest();
    }
  }

  void _submitTest() {
    _timer?.cancel();
    setState(() => _stage = _TestStage.submitted);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _TestStage.setup:
        return _buildSetup();
      case _TestStage.loading:
        return Column(
          children: [
            const TabHeaderBand(
              title: 'Self Analysis Test',
              description: '15 questions to check understanding and find weak spots.',
              icon: Icons.quiz,
            ),
            const Expanded(child: LoadingWidget(message: 'Creating your 15 questions...')),
          ],
        );
      case _TestStage.inProgress:
        return _buildTestInProgress();
      case _TestStage.submitted:
        return _buildResults();
    }
  }

  Widget _buildSetup() {
    return Column(
      children: [
        const TabHeaderBand(
          title: 'Self Analysis Test',
          description: '15 questions to check understanding and find weak spots.',
          icon: Icons.quiz,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _uploadWeeklyContent,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Weekly Content'),
                ),
                if (_weeklyContentBase64 != null) ...[
                  const SizedBox(height: 8),
                  const Text('Weekly content uploaded.', style: TextStyle(color: Colors.green)),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _generateQuestions,
                  icon: const Icon(Icons.quiz),
                  label: const Text('Generate 15 MCQ Questions'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.quiz,
                    message: 'Upload this week\'s content and tap Generate to start the self-analysis test.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestInProgress() {
    final question = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _questions.length - 1;
    final isTimeLow = _secondsRemaining < 120;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isTimeLow ? Colors.red : AppColors.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isTimeLow ? Colors.red : AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                question.question,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  return RadioListTile<int>(
                    title: Text(
                      '${String.fromCharCode(65 + index)}. ${question.options[index]}',
                    ),
                    value: index,
                    groupValue: _selectedAnswers[_currentIndex],
                    activeColor: AppColors.accentTeal,
                    onChanged: (value) {
                      if (value != null) _selectAnswer(value);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _nextQuestion,
            child: Text(isLastQuestion ? 'Submit Test' : 'Next Question'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    int score = 0;
    final Map<String, List<bool>> bloomsResults = {};

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final isCorrect = _selectedAnswers[i] == q.correctIndex;
      if (isCorrect) score++;
      bloomsResults.putIfAbsent(q.bloomsLevel, () => []).add(isCorrect);
    }

    final weakAreas = bloomsResults.entries
        .where((e) => e.value.where((c) => c).length / e.value.length < 0.5)
        .map((e) => e.key)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Score: $score / ${_questions.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Bloom's Level Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: bloomsResults.entries.map((e) {
                  final correct = e.value.where((c) => c).length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${e.key}: $correct / ${e.value.length}'),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (weakAreas.isNotEmpty) ...[
            const Text('Weak Areas to Revise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...weakAreas.map((area) => Text('• $area')),
            const SizedBox(height: 16),
          ],
          const Text('Answer Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(_questions.length, (i) {
            final q = _questions[i];
            final selected = _selectedAnswers[i];
            final isCorrect = selected == q.correctIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ${q.question}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        'Your answer: ${selected != null ? q.options[selected] : "Not answered"}',
                        style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
                      ),
                      if (!isCorrect)
                        Text('Correct answer: ${q.options[q.correctIndex]}',
                            style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
