import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/question_repository.dart';
import '../providers/quiz_provider.dart';
import '../models/question.dart';
import 'exam_page.dart';

class RangeModePage extends StatefulWidget {
  const RangeModePage({super.key});

  @override
  State<RangeModePage> createState() => _RangeModePageState();
}

class _RangeModePageState extends State<RangeModePage> {
  bool? _isMorning; // true=午前, false=午後, null=未選択
  bool _isBoth = true; // 初期は午前+午後
  int _count = 30;

  final _repository = QuestionRepository();

  final _countOptions = const [10, 20, 30, 60, 90, 180];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('横断ランダム（第34〜38回）'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                label: const Center(child: Text('午前+午後（混在）')),
                selected: _isBoth,
                onSelected: (selected) {
                  setState(() {
                    _isBoth = selected;
                    if (selected) {
                      _isMorning = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('出題数を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _count,
              isExpanded: true,
              items: _countOptions
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('$c 問'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _count = v);
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _startQuiz,
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

  Future<void> _startQuiz() async {
    final quizProvider = context.read<QuizProvider>();
    try {
      final List<Question> questions = await _repository.getQuestionsByYearRangeRandom(
        startYear: 34,
        endYear: 38,
        isMorning: _isBoth ? null : _isMorning,
        count: _count,
      );

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
        final modeName = '第34〜38回 横断ランダム${_isBoth ? '' : _isMorning == true ? '（午前）' : '（午後）'}';
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
