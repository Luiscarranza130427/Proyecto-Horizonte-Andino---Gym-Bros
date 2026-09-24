import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF111111);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceHigh = Color(0xFF292929);
  static const surfaceHighest = Color(0xFF353535);
  static const primary = Color(0xFFC42B34);
  static const primarySoft = Color(0xFFFFB4AA);
  static const text = Color(0xFFF4F1F0);
  static const textMuted = Color(0xFFB8B8B8);
  static const border = Color(0xFF393939);
  static const success = Color(0xFF62D58B);
}

abstract final class AppText {
  static const display = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 42,
    height: 1.02,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.4,
    color: AppColors.text,
  );

  static const headline = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.7,
    color: AppColors.text,
  );

  static const title = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.text,
  );

  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.45,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primarySoft,
        surface: AppColors.surface,
        error: Color(0xFFFF6B6B),
        onPrimary: Colors.white,
        onSurface: AppColors.text,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Inter',
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppText.body.copyWith(color: const Color(0xFF858585)),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),
    );
  }
}

class GymScrollBehavior extends MaterialScrollBehavior {
  const GymScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
