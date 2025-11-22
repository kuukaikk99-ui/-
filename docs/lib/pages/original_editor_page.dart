import 'package:flutter/material.dart';
import '../models/question.dart';
import '../repositories/original_question_repository.dart';
import '../constants/fields.dart';

class OriginalEditorPage extends StatefulWidget {
  final Question? existing;
  const OriginalEditorPage({super.key, this.existing});

  @override
  State<OriginalEditorPage> createState() => _OriginalEditorPageState();
}

class _OriginalEditorPageState extends State<OriginalEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  final _explainCtrl = TextEditingController();
  final List<TextEditingController> _choiceCtrls =
      List.generate(5, (_) => TextEditingController());

  String _type = 'single';
  String _difficulty = 'normal';
  String _field = allowedFields.first;
  final Set<int> _correctSet = {};
  final _repo = OriginalQuestionRepository();

  List<String> get _fields => allowedFields;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final q = widget.existing!;
      _textCtrl.text = q.text;
      _explainCtrl.text = q.explanation;
      for (int i = 0; i < _choiceCtrls.length && i < q.choices.length; i++) {
        _choiceCtrls[i].text = q.choices[i];
      }
      _type = q.type;
      _difficulty = q.difficulty;
      _field = allowedFields.contains(q.field) ? q.field : allowedFields.first;
      _correctSet.addAll(q.correct);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _explainCtrl.dispose();
    for (final c in _choiceCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'single' && _correctSet.length != 1) {
      _showSnack('単一選択は正答を1つ選んでください');
      return;
    }
    if (_type == 'multiple' && _correctSet.length != 3) {
      _showSnack('複数選択は正答を3つ選んでください');
      return;
    }

    final q = Question(
      id: widget.existing?.id ?? -1,
      text: _textCtrl.text.trim(),
      choices: _choiceCtrls.map((c) => c.text.trim()).toList(),
      correct: _correctSet.toList()..sort(),
      type: _type,
      difficulty: _difficulty,
      year: 0,
      isMorning: false,
      field: _field,
      explanation: _explainCtrl.text.trim(),
    );

    if (widget.existing == null) {
      await _repo.add(q);
    } else {
      await _repo.update(q);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '問題を編集' : '問題を作成'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: '保存',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _textCtrl,
              decoration: const InputDecoration(labelText: '問題文'),
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty) ? '問題文を入力してください' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _field,
                    decoration: const InputDecoration(labelText: '分野'),
                    items: _fields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (v) => setState(() => _field = v ?? _field),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(labelText: '難易度'),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('初級')),
                      DropdownMenuItem(value: 'normal', child: Text('中級')),
                      DropdownMenuItem(value: 'hard', child: Text('上級')),
                    ],
                    onChanged: (v) => setState(() => _difficulty = v ?? _difficulty),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'single', label: Text('単一選択')),
                ButtonSegment(value: 'multiple', label: Text('複数選択(3)')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _correctSet.clear();
              }),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 36,
                      child: _type == 'single'
                          ? Radio<int>(
                              value: i,
                              groupValue: _correctSet.isNotEmpty ? _correctSet.first : null,
                              onChanged: (v) => setState(() {
                                _correctSet
                                  ..clear()
                                  ..add(i);
                              }),
                            )
                          : Checkbox(
                              value: _correctSet.contains(i),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  if (_correctSet.length < 3) _correctSet.add(i);
                                } else {
                                  _correctSet.remove(i);
                                }
                              }),
                            ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _choiceCtrls[i],
                        decoration: InputDecoration(labelText: '選択肢 ${String.fromCharCode(65 + i)}'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? '選択肢を入力' : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            TextFormField(
              controller: _explainCtrl,
              decoration: const InputDecoration(labelText: '解説'),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('保存する'),
            )
          ],
        ),
      ),
    );
  }
}
