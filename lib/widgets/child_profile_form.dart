import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/child_profile.dart';
import '../services/camera_service.dart';

class ChildProfileForm extends StatefulWidget {
  final ChildProfile profile;
  final ValueChanged<ChildProfile> onProfileChanged;

  const ChildProfileForm({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<ChildProfileForm> createState() => _ChildProfileFormState();
}

class _ChildProfileFormState extends State<ChildProfileForm> {
  late TextEditingController _nameController;
  static const List<String> _grades = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
  ];
  static const List<String> _languages = ['English', 'Tamil'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(ChildProfile Function(ChildProfile) mutate) {
    final updated = mutate(widget.profile);
    widget.onProfileChanged(updated);
  }

  Future<void> _uploadBook() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final base64Image = base64Encode(result.files.single.bytes!);
      _update((p) => ChildProfile(
            name: p.name,
            age: p.age,
            grade: p.grade,
            language: p.language,
            bookImageBase64: base64Image,
          ));
    }
  }

  Future<void> _takePhoto() async {
    final base64Image = await CameraService.takePhoto();
    if (base64Image != null) {
      _update((p) => ChildProfile(
            name: p.name,
            age: p.age,
            grade: p.grade,
            language: p.language,
            bookImageBase64: base64Image,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Child Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: "Child's Name",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _update((p) => ChildProfile(
                name: value,
                age: p.age,
                grade: p.grade,
                language: p.language,
                bookImageBase64: p.bookImageBase64,
              )),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: profile.age,
          decoration: const InputDecoration(
            labelText: 'Age',
            border: OutlineInputBorder(),
          ),
          items: [
            for (int age = 5; age <= 15; age++)
              DropdownMenuItem(value: age, child: Text('$age years')),
          ],
          onChanged: (value) {
            if (value == null) return;
            _update((p) => ChildProfile(
                  name: p.name,
                  age: value,
                  grade: p.grade,
                  language: p.language,
                  bookImageBase64: p.bookImageBase64,
                ));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: profile.grade,
          decoration: const InputDecoration(
            labelText: 'Class',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final grade in _grades)
              DropdownMenuItem(value: grade, child: Text(grade)),
          ],
          onChanged: (value) {
            if (value == null) return;
            _update((p) => ChildProfile(
                  name: p.name,
                  age: p.age,
                  grade: value,
                  language: p.language,
                  bookImageBase64: p.bookImageBase64,
                ));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: profile.language,
          decoration: const InputDecoration(
            labelText: 'Language',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final lang in _languages)
              DropdownMenuItem(value: lang, child: Text(lang)),
          ],
          onChanged: (value) {
            if (value == null) return;
            _update((p) => ChildProfile(
                  name: p.name,
                  age: p.age,
                  grade: p.grade,
                  language: value,
                  bookImageBase64: p.bookImageBase64,
                ));
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _uploadBook,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Book'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _takePhoto,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take Photo'),
        ),
        if (profile.bookImageBase64 != null) ...[
          const SizedBox(height: 16),
          const Text('Book Preview', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(profile.bookImageBase64!),
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('Preview unavailable (file may be a PDF)'),
            ),
          ),
        ],
      ],
    );
  }
}
