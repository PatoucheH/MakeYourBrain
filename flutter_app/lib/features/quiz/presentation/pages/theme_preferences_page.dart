import 'package:flutter/material.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/theme_preferences_repository.dart';
import '../../data/models/theme_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import 'home_page.dart';

class ThemePreferencesPage extends StatefulWidget {
  const ThemePreferencesPage({super.key});

  @override
  State<ThemePreferencesPage> createState() => _ThemePreferencesPageState();
}

class _ThemePreferencesPageState extends State<ThemePreferencesPage> {
  final _quizRepo = QuizRepository();
  final _prefsRepo = ThemePreferencesRepository();
  final _authRepo = AuthRepository();
  
  List<ThemeModel> themes = [];
  Set<String> selectedThemeIds = {};
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  Future<void> loadThemes() async {
    try {
      final result = await _quizRepo.getThemes('en');
      setState(() {
        themes = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> savePreferences() async {
    if (selectedThemeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one theme')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final userId = _authRepo.getCurrentUserId()!;
      await _prefsRepo.savePreferences(userId, selectedThemeIds.toList());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Interests'),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        '🎯 What topics interest you?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select your favorite themes to get personalized quizzes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: themes.length,
                    itemBuilder: (context, index) {
                      final theme = themes[index];
                      final isSelected = selectedThemeIds.contains(theme.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: Text(
                            theme.icon,
                            style: const TextStyle(fontSize: 40),
                          ),
                          title: Text(
                            theme.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(theme.description),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedThemeIds.add(theme.id);
                                } else {
                                  selectedThemeIds.remove(theme.id);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedThemeIds.remove(theme.id);
                              } else {
                                selectedThemeIds.add(theme.id);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : savePreferences,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator()
                          : Text(
                              'Continue (${selectedThemeIds.length} selected)',
                              style: const TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}