import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/question_repository.dart';
import '../providers/quiz_provider.dart';
import 'exam_page.dart';

class ComprehensiveModePage extends StatelessWidget {
  const ComprehensiveModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('総合試験モード'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.assessment, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              '総合試験モード',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '第34〜38回すべてからランダムに180問を出題します。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '午前90問 + 午後90問',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _startQuiz(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('開始', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _startQuiz(BuildContext context) async {
    final quizProvider = context.read<QuizProvider>();
    final repository = QuestionRepository();

    try {
      final questions = await repository.getComprehensiveQuestions();

      if (questions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('問題が見つかりませんでした')),
          );
        }
        return;
      }

      quizProvider.startQuiz(questions);
      
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExamPage(modeName: '総合試験'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }
}
