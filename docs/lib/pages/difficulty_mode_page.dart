import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/question_repository.dart';
import '../providers/quiz_provider.dart';
import 'exam_page.dart';

class DifficultyModePage extends StatefulWidget {
  const DifficultyModePage({super.key});

  @override
  State<DifficultyModePage> createState() => _DifficultyModePageState();
}

class _DifficultyModePageState extends State<DifficultyModePage> {
  String? _selectedDifficulty;
  bool? _isMorning;

  final _repository = QuestionRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('難易度モード'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('難易度を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('初級'),
                  selected: _selectedDifficulty == 'easy',
                  onSelected: (selected) {
                    setState(() {
                      _selectedDifficulty = selected ? 'easy' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('中級'),
                  selected: _selectedDifficulty == 'normal',
                  onSelected: (selected) {
                    setState(() {
                      _selectedDifficulty = selected ? 'normal' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('上級'),
                  selected: _selectedDifficulty == 'hard',
                  onSelected: (selected) {
                    setState(() {
                      _selectedDifficulty = selected ? 'hard' : null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedDifficulty != null) ...[
              const Text('時間帯を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('午前'),
                      selected: _isMorning == true,
                      onSelected: (selected) {
                        setState(() {
                          _isMorning = selected ? true : null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('午後'),
                      selected: _isMorning == false,
                      onSelected: (selected) {
                        setState(() {
                          _isMorning = selected ? false : null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '※全年度から30問をランダム出題',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _canStart() ? _startQuiz : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('開始', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  bool _canStart() {
    return _selectedDifficulty != null && _isMorning != null;
  }

  Future<void> _startQuiz() async {
    if (!_canStart()) return;

    final quizProvider = context.read<QuizProvider>();
    
    try {
      final questions = await _repository.getQuestionsByDifficultyPeriod(
        difficulty: _selectedDifficulty!,
        isMorning: _isMorning!,
      );

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('問題が見つかりませんでした')),
          );
        }
        return;
      }

      final difficultyLabel = _selectedDifficulty == 'easy' ? '初級' : 
                              _selectedDifficulty == 'normal' ? '中級' : '上級';
      final modeName = '$difficultyLabel ${_isMorning! ? '午前' : '午後'}';

      quizProvider.startQuiz(questions);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamPage(modeName: modeName),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }
}
