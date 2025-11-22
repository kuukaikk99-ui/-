import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/question_repository.dart';
import '../providers/quiz_provider.dart';
import '../models/question.dart';
import 'exam_page.dart';

class YearModePage extends StatefulWidget {
  const YearModePage({super.key});

  @override
  State<YearModePage> createState() => _YearModePageState();
}

class _YearModePageState extends State<YearModePage> {
  int? _selectedYear;
  bool? _isMorning; // true=午前, false=午後, null=未選択
  bool _isBoth = false; // 午前+午後の180問モード

  final _repository = QuestionRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('年度別モード'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('年度を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [34, 35, 36, 37, 38].map((year) {
                return ChoiceChip(
                  label: Text('第$year回'),
                  selected: _selectedYear == year,
                  onSelected: (selected) {
                    setState(() {
                      _selectedYear = selected ? year : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_selectedYear != null) ...[
              const Text('時間帯を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ChoiceChip(
                  label: const Center(child: Text('午前')),
                  selected: _isMorning == true && !_isBoth,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _isMorning = true;
                        _isBoth = false;
                      } else {
                        _isMorning = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ChoiceChip(
                  label: const Center(child: Text('午後')),
                  selected: _isMorning == false && !_isBoth,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _isMorning = false;
                        _isBoth = false;
                      } else {
                        _isMorning = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ChoiceChip(
                  label: const Center(child: Text('午前+午後 (180問)')),
                  selected: _isBoth,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _isBoth = true;
                        _isMorning = null;
                      } else {
                        _isBoth = false;
                      }
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
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
    if (_selectedYear == null) {
      return false;
    }
    // 午前/午後のいずれか、または180問モードが選択されていればOK
    return _isBoth || _isMorning != null;
  }

  Future<void> _startQuiz() async {
    if (!_canStart()) return;

    final quizProvider = context.read<QuizProvider>();
    
    try {
      List<Question> questions;
      String modeName;

      if (_isBoth) {
        // 午前+午後の180問モード
        final amQuestions = await _repository.getQuestionsByYearPeriodMixed(
          year: _selectedYear!,
          isMorning: true,
        );
        final pmQuestions = await _repository.getQuestionsByYearPeriodMixed(
          year: _selectedYear!,
          isMorning: false,
        );
        questions = [...amQuestions, ...pmQuestions];
        questions.shuffle();
        modeName = '第$_selectedYear回 午前+午後';
      } else {
        // 年度+時間帯の全問題を対象(34午前は90問)
        questions = await _repository.getQuestionsByYearPeriodMixed(
          year: _selectedYear!,
          isMorning: _isMorning!,
        );
        modeName = '第$_selectedYear回 ${_isMorning! ? '午前' : '午後'}';
      }

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('問題が見つかりませんでした')),
          );
        }
        return;
      }

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
