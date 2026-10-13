import 'package:flutter/material.dart';
import 'package:tower_defence/match/match_controller.dart';
import 'package:tower_defence/view/match_screen.dart';

class KeepwardApp extends StatelessWidget {
  const KeepwardApp({super.key, this.controller, this.animate = true});

  final MatchController? controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    const parchment = Color(0xFFF3E6C8);
    const gold = Color(0xFFD7A441);
    const ink = Color(0xFF1B1408);
    return MaterialApp(
      title: 'Keepward',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12180F),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1B2416),
          primary: gold,
          onPrimary: ink,
          secondary: Color(0xFF7FA36A),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: parchment,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            color: parchment,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Roboto',
            color: gold,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: ink,
            disabledBackgroundColor: const Color(0xFF3C4632),
            disabledForegroundColor: const Color(0xFFB7AA90),
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: MatchScreen(controller: controller, animate: animate),
        ),
      ),
    );
  }
}
