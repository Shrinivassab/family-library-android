import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/ai_service.dart';
import '../widgets/loading_widget.dart';

class BloomsQuestionsScreen extends StatefulWidget {
  final ChildProfile profile;

  const BloomsQuestionsScreen({super.key, required this.profile});

  @override
  State<BloomsQuestionsScreen> createState() => _BloomsQuestionsScreenState();
}

class _BloomsQuestionsScreenState extends State<BloomsQuestionsScreen> {
  bool _isLoading = false;
  String? _questions;
  String? _error;

  Future<void> _generateQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final name = widget.profile.name.isEmpty ? 'the child' : widget.profile.name;
    final age = widget.profile.age;
    final grade = widget.profile.grade;
    final language = widget.profile.language;

    final prompt = """
You are an educational AI for rural Indian students.
A child named $name, age $age, in $grade, prefers $language.

Based on the uploaded book content, generate questions covering
all 6 levels of Bloom's Taxonomy:
1. Remember - 2 questions
2. Understand - 2 questions
3. Apply - 2 questions
4. Analyze - 2 questions
5. Evaluate - 1 question
6. Create - 1 question

Label each question clearly with its Bloom's level.
Respond in $language.
""";

    try {
      final result = await AIService.callGemma4(
        prompt,
        imageBase64: widget.profile.bookImageBase64,
      );
      setState(() {
        _questions = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not generate questions. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bloom's Taxonomy Questions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateQuestions,
            icon: const Icon(Icons.psychology),
            label: const Text('Generate Questions'),
          ),
          const SizedBox(height: 16),
          if (_isLoading) const Expanded(child: LoadingWidget(message: 'Generating questions...')),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (!_isLoading && _questions != null)
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_questions!, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}
