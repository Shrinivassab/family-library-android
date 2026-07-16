import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/ai_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import '../widgets/tab_header_band.dart';

class ReadingPlanScreen extends StatefulWidget {
  final ChildProfile profile;

  const ReadingPlanScreen({super.key, required this.profile});

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  bool _isLoading = false;
  String? _plan;
  String? _error;

  Future<void> _generatePlan() async {
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
A child named $name, age $age, in $grade,
prefers $language.

Generate a 7-day personalized reading plan:
- Day 1 through Day 7 with daily activities
- 3 quiz questions at right difficulty
- 3 vocabulary words suitable for this age
- Tips for parents
Respond in $language.
""";

    try {
      final result = await AIService.callGemma4(
        prompt,
        imageBase64: widget.profile.bookImageBase64,
      );
      setState(() {
        _plan = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not generate a reading plan. Please try again.';
        _isLoading = false;
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Creating your reading plan...');
    }
    if (_plan != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(_plan!, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
      );
    }
    return const EmptyState(
      icon: Icons.auto_stories,
      message: "Add your child's details and tap Generate to create a 7-day reading plan.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TabHeaderBand(
          title: 'Reading Plan',
          description: 'A personalized 7-day plan with quizzes and vocabulary.',
          icon: Icons.auto_stories,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generatePlan,
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('Generate 7-Day Reading Plan'),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
