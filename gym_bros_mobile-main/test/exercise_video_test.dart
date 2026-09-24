import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/widgets/exercise_video_dialog.dart';

void main() {
  test('acepta URLs completas y extrae solo IDs válidos de YouTube', () {
    for (final url in [
      'https://www.youtube.com/watch?v=abcdefghijk&feature=shared',
      'https://youtu.be/abcdefghijk?si=example',
      'https://youtube.com/shorts/abcdefghijk',
      'https://m.youtube.com/watch?v=abcdefghijk',
      'https://www.youtube-nocookie.com/embed/abcdefghijk',
      'www.youtube.com/live/abcdefghijk',
    ]) {
      expect(exerciseYoutubeId(url), 'abcdefghijk', reason: url);
    }
    for (final url in [
      '',
      'https://videos.test/press-banca',
      'https://youtube.com.evil.test/watch?v=abcdefghijk',
      'https://youtube.com/watch?v=short',
      'javascript:alert(1)',
      'https://youtu.be/abcdefghijk/other',
      'https://youtube.com/playlist?list=example',
    ]) {
      expect(exerciseYoutubeId(url), isNull, reason: url);
    }
  });

  testWidgets('enlace ausente muestra popup cerrable sin crear reproductor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showExerciseVideo(
                context,
                name: 'Press banca',
                url: 'https://videos.test/press-banca',
              ),
              child: const Text('Ver ejercicio'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ver ejercicio'));
    await tester.pumpAndSettle();
    expect(find.text('Press banca'), findsOneWidget);
    expect(
      find.text('Este ejercicio aún no tiene un enlace válido de YouTube.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('close-exercise-video')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseVideoDialog), findsNothing);
    expect(find.text('Ver ejercicio'), findsOneWidget);
  });
}
