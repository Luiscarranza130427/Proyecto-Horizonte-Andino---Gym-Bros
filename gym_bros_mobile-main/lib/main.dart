import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/gym_api.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymBrosApp());
}

class GymBrosApp extends StatelessWidget {
  const GymBrosApp({super.key, this.gymApi});

  final GymApi? gymApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYM-BROS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scrollBehavior: const GymScrollBehavior(),
      home: LoginScreen(gymApi: gymApi),
    );
  }
}
