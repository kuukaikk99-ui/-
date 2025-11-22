# くーの臨床工学技士国家試験対策

臨床工学技士国家試験（第34〜38回）の類似問題を習得するためのFlutter製クイズアプリです。

## 機能概要

### 出題モード
1. **年度別モード**
   - 第34〜38回を選択
   - 午前 / 午後を選択
   - 難易度別30問 または ミックス90問（全難易度）

2. **難易度モード**
   - 初級 / 中級 / 上級を選択
   - 午前 / 午後を選択
   - 全年度から30問をランダム出題

3. **総合試験モード**
   - 全年度から180問をランダム出題
   - 午前90問 + 午後90問

### その他の機能
- 問題ごとの詳細解説表示
- 不正解問題のみ復習機能
- 試験履歴の保存と閲覧
- 正答率の表示

## 技術仕様

- **Flutter**: 3.x以降
- **Dart**: null-safety対応
- **状態管理**: Provider
- **データ永続化**: SharedPreferences
- **アーキテクチャ**: Repository パターン

## プロジェクト構造

```
flutter_app/
├── lib/
│   ├── main.dart                    # アプリエントリーポイント
│   ├── models/                      # データモデル
│   │   ├── question.dart
│   │   ├── quiz_result.dart
│   │   └── user_answer.dart
│   ├── providers/                   # 状態管理
│   │   ├── quiz_provider.dart
│   │   └── history_provider.dart
│   ├── repositories/                # データアクセス層
│   │   └── question_repository.dart
│   └── pages/                       # 画面
│       ├── home_page.dart
│       ├── year_mode_page.dart
│       ├── difficulty_mode_page.dart
│       ├── comprehensive_mode_page.dart
│       ├── exam_page.dart
│       ├── result_page.dart
│       └── history_page.dart
├── assets/
│   └── questions.json               # 問題データ
├── test/
│   └── question_test.dart           # 単体テスト
├── pubspec.yaml
└── README.md
```

## セットアップ手順

### 前提条件
- Flutter SDK 3.0以降がインストールされていること
- Android Studio / VS Code などのIDE
- Androidエミュレータ または 実機

### インストール

1. **リポジトリのクローン（またはディレクトリへの移動）**
```bash
cd flutter_app
```

2. **依存パッケージのインストール**
```bash
flutter pub get
```

3. **コードの静的解析**
```bash
flutter analyze
```

4. **テストの実行**
```bash
flutter test
```

## 実行方法

### Android での実行

1. **エミュレータの起動 または 実機の接続**
```bash
flutter devices
```

2. **アプリの起動**
```bash
flutter run
```

### Web での実行

1. **Webサーバーの起動**
```bash
flutter run -d chrome
```

または

```bash
flutter run -d web-server
```

2. **ブラウザでアクセス**
   - デフォルトでは `http://localhost:XXXXX` で起動します

### リリースビルド

**Android APK**
```bash
flutter build apk --release
```

ビルドされたAPKは `build/app/outputs/flutter-apk/app-release.apk` に生成されます。

**Web**
```bash
flutter build web
```

ビルドされたファイルは `build/web/` に生成されます。

## 問題データ形式

`assets/questions.json` の形式:

```json
{
  "id": 1,
  "text": "問題文",
  "choices": ["A", "B", "C", "D", "E"],
  "correct": [1],
  "type": "single",
  "difficulty": "easy",
  "year": 34,
  "isMorning": true,
  "field": "医用機器安全管理学",
  "explanation": "解説文"
}
```

### フィールド説明
- `id`: 問題の一意なID
- `text`: 問題文
- `choices`: 選択肢の配列（5つ）
- `correct`: 正答のインデックス配列（0〜4）
- `type`: `"single"` (単一選択) または `"multiple"` (3つ選択)
- `difficulty`: `"easy"` (初級), `"normal"` (中級), `"hard"` (上級)
- `year`: 試験回数（34〜38）
- `isMorning`: 午前は `true`, 午後は `false`
- `field`: 分野名（9分野）
- `explanation`: 解説文

## テスト

単体テストを実行:
```bash
flutter test
```

カバレッジ付きで実行:
```bash
flutter test --coverage
```

## トラブルシューティング

### 依存関係のエラー
```bash
flutter clean
flutter pub get
```

### ビルドエラー
```bash
flutter doctor
```
を実行して環境を確認してください。

### 問題データが読み込めない
- `assets/questions.json` が存在するか確認
- `pubspec.yaml` の `assets` セクションが正しく設定されているか確認

## ライセンス

このプロジェクトは教育目的で作成されています。

## 開発者向け情報

### コーディング規約
- Dart の標準的なコーディング規約に準拠
- `flutter analyze` で警告が0になるように実装
- Provider を使用した状態管理
- Repository パターンによるデータアクセス層の分離

### 今後の拡張案
- オフラインモード対応
- 問題のブックマーク機能
- 学習進捗の可視化
- 分野別の統計表示
- 問題の難易度調整機能
