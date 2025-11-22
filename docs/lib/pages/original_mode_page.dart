import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/quiz_provider.dart';
import '../repositories/original_question_repository.dart';
import 'exam_page.dart';
import 'original_editor_page.dart';

class OriginalModePage extends StatefulWidget {
  const OriginalModePage({super.key});

  @override
  State<OriginalModePage> createState() => _OriginalModePageState();
}

class _OriginalModePageState extends State<OriginalModePage> {
  final _repo = OriginalQuestionRepository();
  List<Question> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.load();
    if (!mounted) return;
    setState(() {
      _questions = list;
      _loading = false;
    });
  }

  Future<void> _startQuiz({required int count}) async {
    if (_questions.isEmpty) return;
    final list = List<Question>.from(_questions)..shuffle();
    final selected = count > 0 ? list.take(count).toList() : list;
    context.read<QuizProvider>().startQuiz(selected);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExamPage(modeName: '【オリジナル問題】'),
      ),
    );
  }

  Future<void> _delete(int id) async {
    await _repo.delete(id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('オリジナル問題'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '問題を追加',
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const OriginalEditorPage()),
              );
              if (added == true) {
                _load();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('登録数: ${_questions.length} 問',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      FilledButton.icon(
                        onPressed: _questions.isNotEmpty
                            ? () => _startQuiz(count: 0)
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('全問で開始'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _questions.length >= 30
                            ? () => _startQuiz(count: 30)
                            : null,
                        child: const Text('ランダム30問'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: _questions.isEmpty
                      ? const Center(child: Text('まだオリジナル問題がありません。右上の＋から作成してください。'))
                      : ListView.separated(
                          itemCount: _questions.length,
                          separatorBuilder: (_, __) => const Divider(height: 0),
                          itemBuilder: (context, index) {
                            final q = _questions[index];
                            return ListTile(
                              title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text('分野: ${q.field} / 種別: ${q.type == 'single' ? '単一' : '複数'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: '編集',
                                    onPressed: () async {
                                      final updated = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OriginalEditorPage(existing: q),
                                        ),
                                      );
                                      if (updated == true) _load();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: '削除',
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('削除しますか？'),
                                          content: const Text('この問題を削除します。取り消せません。'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
                                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('削除')),
                                          ],
                                        ),
                                      );
                                      if (ok == true) _delete(q.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const OriginalEditorPage()),
          );
          if (added == true) {
            _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('問題を追加'),
      ),
    );
  }
}
