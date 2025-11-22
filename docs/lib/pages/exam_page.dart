import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import 'result_page.dart';

class ExamPage extends StatefulWidget {
  final String modeName;

  const ExamPage({super.key, required this.modeName});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final question = quizProvider.currentQuestion;
        
        if (question == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.modeName),
            backgroundColor: Colors.blue,
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 進捗表示
                LinearProgressIndicator(
                  value: (quizProvider.currentQuestionIndex + 1) / quizProvider.totalQuestions,
                ),
                const SizedBox(height: 8),
                Text(
                  '問題 ${quizProvider.currentQuestionIndex + 1} / ${quizProvider.totalQuestions}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // 問題情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '分野: ${question.field}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        question.type == 'single' ? '【単一選択】正答を1つ選んでください' : '【複数選択】正答を3つ選んでください',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 問題文
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        
                        // 選択肢
                        ...List.generate(question.choices.length, (index) {
                          final choice = question.choices[index];
                          final label = String.fromCharCode(65 + index); // A, B, C, D, E
                          final isSelected = quizProvider.currentSelectedAnswers.contains(index);
                          final isCorrectAnswer = question.correct.contains(index);

                          // フィードバック表示時の色分け
                          Color? tileColor;
                          if (_showFeedback) {
                            if (isCorrectAnswer) {
                              tileColor = Colors.green.shade100;
                            } else if (isSelected) {
                              tileColor = Colors.red.shade100;
                            }
                          }

                          if (question.type == 'single') {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: RadioListTile<int>(
                                title: Row(
                                  children: [
                                    Expanded(child: Text('$label. $choice')),
                                    if (_showFeedback && isCorrectAnswer)
                                      const Icon(Icons.check_circle, color: Colors.green),
                                    if (_showFeedback && isSelected && !isCorrectAnswer)
                                      const Icon(Icons.cancel, color: Colors.red),
                                  ],
                                ),
                                value: index,
                                groupValue: quizProvider.currentSelectedAnswers.isNotEmpty 
                                    ? quizProvider.currentSelectedAnswers[0] 
                                    : null,
                                onChanged: _showFeedback ? null : (value) {
                                  if (value != null) {
                                    quizProvider.toggleAnswer(value);
                                  }
                                },
                              ),
                            );
                          } else {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CheckboxListTile(
                                title: Row(
                                  children: [
                                    Expanded(child: Text('$label. $choice')),
                                    if (_showFeedback && isCorrectAnswer)
                                      const Icon(Icons.check_circle, color: Colors.green),
                                    if (_showFeedback && isSelected && !isCorrectAnswer)
                                      const Icon(Icons.cancel, color: Colors.red),
                                  ],
                                ),
                                value: isSelected,
                                onChanged: _showFeedback ? null : (value) {
                                  quizProvider.toggleAnswer(index);
                                },
                              ),
                            );
                          }
                        }),
                        
                        // フィードバック表示
                        if (_showFeedback)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isCorrect ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: _isCorrect ? Colors.green : Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isCorrect ? '正解です！' : '不正解です',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 解答確定 / 次へボタン
                if (!_showFeedback)
                  ElevatedButton(
                    onPressed: quizProvider.currentSelectedAnswers.isNotEmpty
                        ? () => _checkAnswer(quizProvider)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueGrey.shade300,
                    ),
                    child: const Text(
                      '解答を確定',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _handleNext(context, quizProvider),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      quizProvider.currentQuestionIndex == quizProvider.totalQuestions - 1
                          ? '結果を見る'
                          : '次へ',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkAnswer(QuizProvider quizProvider) {
    final question = quizProvider.currentQuestion!;
    final userAnswers = List<int>.from(quizProvider.currentSelectedAnswers)..sort();
    final correctAnswers = List<int>.from(question.correct)..sort();
    
    setState(() {
      _isCorrect = userAnswers.length == correctAnswers.length &&
          userAnswers.every((answer) => correctAnswers.contains(answer));
      _showFeedback = true;
    });
  }

  void _handleNext(BuildContext context, QuizProvider quizProvider) {
    final isLast = quizProvider.currentQuestionIndex == quizProvider.totalQuestions - 1;
    
    setState(() {
      _showFeedback = false;
      _isCorrect = false;
    });
    
    quizProvider.nextQuestion();

    if (isLast) {
      // 結果画面へ遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(modeName: widget.modeName),
        ),
      );
    }
  }
}
