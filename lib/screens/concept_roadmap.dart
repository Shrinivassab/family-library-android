import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/ai_service.dart';
import '../widgets/loading_widget.dart';

class ConceptRoadmapScreen extends StatefulWidget {
  final ChildProfile profile;

  const ConceptRoadmapScreen({super.key, required this.profile});

  @override
  State<ConceptRoadmapScreen> createState() => _ConceptRoadmapScreenState();
}

class _ConceptRoadmapScreenState extends State<ConceptRoadmapScreen> {
  bool _isLoading = false;
  String? _roadmap;
  String? _error;

  Future<void> _generateRoadmap() async {
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

Based on the uploaded book content, build a concept roadmap:
- List the core concepts covered in this book, in learning order
- For each concept, list 1-2 prerequisite concepts the child should
  already know
- For each concept, suggest 1 next concept to explore afterward
- Keep explanations short and age-appropriate
Respond in $language.
""";

    try {
      final result = await AIService.callGemma4(
        prompt,
        imageBase64: widget.profile.bookImageBase64,
      );
      setState(() {
        _roadmap = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not generate a concept roadmap. Please try again.';
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
            'Concept Roadmap',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateRoadmap,
            icon: const Icon(Icons.map),
            label: const Text('Generate Concept Roadmap'),
          ),
          const SizedBox(height: 16),
          if (_isLoading) const Expanded(child: LoadingWidget(message: 'Building roadmap...')),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (!_isLoading && _roadmap != null)
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_roadmap!, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}
