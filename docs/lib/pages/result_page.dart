import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/history_provider.dart';
import '../models/quiz_result.dart';
import 'exam_page.dart';

class ResultPage extends StatefulWidget {
  final String modeName;

  const ResultPage({super.key, required this.modeName});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    final quizProvider = context.read<QuizProvider>();
    final historyProvider = context.read<HistoryProvider>();

    final result = QuizResult(
      dateTime: DateTime.now(),
      totalQuestions: quizProvider.totalQuestions,
      correctAnswers: quizProvider.correctAnswersCount,
      mode: widget.modeName,
    );

    await historyProvider.addResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final score = quizProvider.correctAnswersCount;
        final total = quizProvider.totalQuestions;
        final accuracy = total > 0 ? (score / total * 100) : 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('結果'),
            backgroundColor: Colors.blue,
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  '試験結果',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.modeName,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score / $total',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '正答率: ${accuracy.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // 解説一覧
                Expanded(
                  child: ListView.builder(
                    itemCount: quizProvider.questions.length,
                    itemBuilder: (context, index) {
                      final question = quizProvider.questions[index];
                      final userAnswer = quizProvider.userAnswers[index];
                      final isCorrect = userAnswer.isCorrect;

                      return Card(
                        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                        child: ExpansionTile(
                          leading: Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            '問題 ${index + 1}: ${question.field}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isCorrect ? '正解' : '不正解',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '問題: ${question.text}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  // 正答・回答を記号(A/B/...)ではなく選択肢テキストで表示
                                  Text(
                                    '正答: ${question.correct.map((i) => '${String.fromCharCode(65 + i)}. ${question.choices[i]}').join(', ')}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'あなたの回答: ${userAnswer.selectedAnswers.map((i) => '${String.fromCharCode(65 + i)}. ${question.choices[i]}').join(', ')}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const Text(
                                    '解説:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (question.explanation.trim().isEmpty)
                                        ? '解説は準備中です。'
                                        : question.explanation,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                
                // 不正解のみ復習ボタン
                if (quizProvider.getIncorrectQuestions().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _reviewIncorrect(context, quizProvider),
                    icon: const Icon(Icons.replay),
                    label: const Text('不正解のみ復習'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                const SizedBox(height: 8),
                
                // ホームへ戻るボタン
                ElevatedButton.icon(
                  onPressed: () {
                    quizProvider.reset();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('ホームへ戻る'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _reviewIncorrect(BuildContext context, QuizProvider quizProvider) {
    final incorrectQuestions = quizProvider.getIncorrectQuestions();
    quizProvider.startQuiz(incorrectQuestions);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamPage(modeName: '${widget.modeName} - 復習'),
      ),
    );
  }
}
