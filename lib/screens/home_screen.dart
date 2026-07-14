import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../widgets/child_profile_form.dart';
import 'reading_plan.dart';
import 'blooms_questions.dart';
import 'concept_roadmap.dart';
import 'self_analysis.dart';
import 'report_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _prefsKey = 'child_profile';

  ChildProfile _profile = ChildProfile();
  int _currentTab = 0;

  static const _tabs = [
    BottomNavigationBarItem(icon: Text('📅', style: TextStyle(fontSize: 20)), label: 'Reading Plan'),
    BottomNavigationBarItem(icon: Text('🧠', style: TextStyle(fontSize: 20)), label: "Bloom's"),
    BottomNavigationBarItem(icon: Text('🗺️', style: TextStyle(fontSize: 20)), label: 'Roadmap'),
    BottomNavigationBarItem(icon: Text('🧪', style: TextStyle(fontSize: 20)), label: 'Self Test'),
    BottomNavigationBarItem(icon: Text('📄', style: TextStyle(fontSize: 20)), label: 'Report'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      setState(() => _profile = ChildProfile.decode(saved));
    }
  }

  Future<void> _saveProfile(ChildProfile profile) async {
    setState(() => _profile = profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, profile.encode());
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return ReadingPlanScreen(profile: _profile);
      case 1:
        return BloomsQuestionsScreen(profile: _profile);
      case 2:
        return ConceptRoadmapScreen(profile: _profile);
      case 3:
        return SelfAnalysisScreen(profile: _profile);
      case 4:
        return ReportCardScreen(profile: _profile);
      default:
        return ReadingPlanScreen(profile: _profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📚 Family Library AI Companion', style: TextStyle(fontSize: 18)),
            Text(
              'Personalized learning for every child',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ChildProfileForm(
                  profile: _profile,
                  onProfileChanged: (updated) => setState(() => _profile = updated),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _saveProfile(_profile);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        items: _tabs,
        selectedFontSize: 11,
        unselectedFontSize: 11,
      ),
    );
  }
}
