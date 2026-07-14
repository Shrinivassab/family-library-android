import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../widgets/loading_widget.dart';

class ReportCardScreen extends StatefulWidget {
  final ChildProfile profile;

  const ReportCardScreen({super.key, required this.profile});

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  bool _isLoading = false;
  bool _isExporting = false;
  String? _report;
  String? _error;

  Future<void> _generateReport() async {
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

Write a short, encouraging report card summary for the parents based on
the child's recent reading activity and the uploaded book content:
- Overall progress summary (2-3 sentences)
- Strengths (2-3 bullet points)
- Areas to improve (2-3 bullet points)
- One specific, actionable tip for the parent this week
Respond in $language, in a warm and supportive tone.
""";

    try {
      final result = await AIService.callGemma4(
        prompt,
        imageBase64: widget.profile.bookImageBase64,
      );
      setState(() {
        _report = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not generate the report card. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_report == null) return;
    setState(() => _isExporting = true);
    try {
      final file = await PdfService.generateTextReport(
        title: 'Report Card',
        body: _report!,
        childName: widget.profile.name.isEmpty ? 'Child' : widget.profile.name,
      );
      await PdfService.printOrShare(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
            'Report Card',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: const Icon(Icons.assessment),
                label: const Text('Generate Report Card'),
              ),
              const SizedBox(width: 12),
              if (_report != null)
                OutlinedButton.icon(
                  onPressed: _isExporting ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(_isExporting ? 'Exporting...' : 'Export PDF'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading) const Expanded(child: LoadingWidget(message: 'Generating report...')),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (!_isLoading && _report != null)
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_report!, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}
