import re
import json
import sys
from pathlib import Path

def parse_markdown_question(text, question_id, year, difficulty, is_morning):
    """Markdownから問題を抽出してJSON形式に変換"""
    
    # 分野を抽出
    field_match = re.search(r'\(分野:(.+?)\)', text)
    field = field_match.group(1) if field_match else '医学概論'
    
    # 問題文を抽出
    question_match = re.search(r'【問題】\n(.+?)(?=\n\n【選択肢】)', text, re.DOTALL)
    if not question_match:
        return None
    question_text = question_match.group(1).strip()
    
    # 選択肢を抽出
    choices_match = re.search(r'【選択肢】\n(.+?)(?=\n\n【正答】)', text, re.DOTALL)
    if not choices_match:
        return None
    choices_text = choices_match.group(1).strip()
    choices = []
    for line in choices_text.split('\n'):
        line = line.strip()
        if line and re.match(r'^[A-E]\.', line):
            choice = re.sub(r'^[A-E]\.\s*', '', line)
            choices.append(choice)
    
    # 正答を抽出
    answer_match = re.search(r'【正答】\n(.+?)(?=\n\n【解説】)', text, re.DOTALL)
    if not answer_match:
        return None
    answer_text = answer_match.group(1).strip()
    
    # 正答の処理
    correct_indices = []
    answer_letters = re.findall(r'[A-E]', answer_text)
    for letter in answer_letters:
        idx = ord(letter) - ord('A')
        correct_indices.append(idx)
    
    # 解説を抽出
    explanation_match = re.search(r'【解説】\n(.+?)(?=\n---|\Z)', text, re.DOTALL)
    explanation = explanation_match.group(1).strip() if explanation_match else ''

    # 問題タイプの判定とアプリ仕様への調整（複数選択は最大3）
    original_correct_len = len(correct_indices)
    question_type = 'single' if original_correct_len == 1 else 'multiple'
    adjustment_note = ''
    if question_type == 'multiple' and original_correct_len > 3:
        original_letters = [chr(i + ord('A')) for i in sorted(set(correct_indices))]
        # 先頭3つに調整
        correct_indices = sorted(correct_indices)[:3]
        trimmed_letters = [chr(i + ord('A')) for i in correct_indices]
        adjustment_note = (
            f"\n【注記】本問は元データで正答が{original_correct_len}個（{"、".join(original_letters)}）ありましたが、\n"
            f"アプリ仕様（複数選択は最大3）に合わせ、先頭3つ（{"、".join(trimmed_letters)}）に自動調整しています。"
        )
        explanation = (explanation + adjustment_note).strip()
    
    # 難易度マッピング
    difficulty_map = {'初級': 'easy', '中級': 'normal', '上級': 'hard'}
    
    return {
        'id': question_id,
        'text': question_text,
        'choices': choices,
        'correct': sorted(correct_indices),
        'type': question_type,
        'difficulty': difficulty_map.get(difficulty, 'normal'),
        'year': year,
        'isMorning': is_morning,
        'field': field,
        'explanation': explanation
    }

def process_file(file_path, year, difficulty, is_morning, start_id):
    """Markdownファイルを処理してJSON配列を返す"""
    content = Path(file_path).read_text(encoding='utf-8')
    
    # 【問題】で分割
    questions_raw = re.split(r'\n---\n', content)
    questions = []
    
    current_id = start_id
    for q_text in questions_raw:
        if '【問題】' in q_text:
            q_json = parse_markdown_question(q_text, current_id, year, difficulty, is_morning)
            if q_json and len(q_json['choices']) == 5:
                questions.append(q_json)
                current_id += 1
    
    return questions, current_id

def main():
    base_dir = Path(r'C:\Users\kuuka\OneDrive\ドキュメント\くーの臨床工学技士国家試験対策')

    files_config = [
        # 第34回
        ('第34回_類似問題_初級_午前30問.md', 34, '初級', True),
        ('第34回_類似問題_初級_午後30問.md', 34, '初級', False),
        ('第34回_類似問題_中級_午前30問.md', 34, '中級', True),
        ('第34回_類似問題_中級_午後30問.md', 34, '中級', False),
        ('第34回_類似問題_上級_午前30問.md', 34, '上級', True),
        ('第34回_類似問題_上級_午後30問.md', 34, '上級', False),
        # 第35回
        ('第35回_類似問題_初級_午前30問.md', 35, '初級', True),
        ('第35回_類似問題_初級_午後30問.md', 35, '初級', False),
        ('第35回_類似問題_中級_午前30問.md', 35, '中級', True),
        ('第35回_類似問題_中級_午後30問.md', 35, '中級', False),
        ('第35回_類似問題_上級_午前30問.md', 35, '上級', True),
        ('第35回_類似問題_上級_午後30問.md', 35, '上級', False),
    ]

    all_questions = []
    year_counts = {}
    current_id = 1000  # サンプル問題(12問)と被らないように1000から開始

    for file_name, year, difficulty, is_morning in files_config:
        file_path = base_dir / file_name
        if file_path.exists():
            questions, current_id = process_file(file_path, year, difficulty, is_morning, current_id)
            all_questions.extend(questions)
            year_counts[year] = year_counts.get(year, 0) + len(questions)
            print(f'Processed: {file_name} -> {len(questions)} questions')
        else:
            print(f'File not found: {file_name}')

    # 既存のquestions.jsonを読み込み
    output_path = base_dir / 'flutter_app' / 'assets' / 'questions.json'
    existing_questions = []
    if output_path.exists():
        with open(output_path, 'r', encoding='utf-8') as f:
            existing_questions = json.load(f)

    # サンプル問題(id < 1000)は残す
    sample_questions = [q for q in existing_questions if q['id'] < 1000]

    # 統合
    final_questions = sample_questions + all_questions

    # 保存
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_questions, f, ensure_ascii=False, indent=2)

    print(f'\nTotal questions saved: {len(final_questions)}')
    print(f'  - Sample questions: {len(sample_questions)}')
    for y in sorted(year_counts.keys()):
        print(f'  - Year {y} questions: {year_counts[y]}')

if __name__ == '__main__':
    main()
