import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/history_provider.dart';
import 'providers/player_status_provider.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..loadHistory()),
        ChangeNotifierProvider(create: (_) => PlayerStatusProvider()),
      ],
      child: Builder(
        builder: (context) {
          final base = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          );

          return MaterialApp(
            title: 'くーの臨床工学技士国家試験対策',
            theme: base.copyWith(
              textTheme: base.textTheme,
              appBarTheme: base.appBarTheme.copyWith(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                titleTextStyle: base.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              listTileTheme: base.listTileTheme.copyWith(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final num clamped = (media.textScaleFactor * 1.2).clamp(1.0, 1.6);
              final double newScale = clamped.toDouble();
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(newScale)),
                child: child!,
              );
            },
            home: const HomePage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
