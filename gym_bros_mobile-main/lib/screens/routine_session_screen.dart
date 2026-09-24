import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/exercise_video_dialog.dart';

import '../models/gym_session.dart';
import '../models/routine_session.dart';
import '../services/gym_api.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';

class RoutineSessionScreen extends StatefulWidget {
  const RoutineSessionScreen({
    super.key,
    required this.routine,
    required this.api,
    this.embedded = false,
    this.currentDate,
  });
  final GymRoutine routine;
  final GymApi api;
  final bool embedded;
  final DateTime Function()? currentDate;

  @override
  State<RoutineSessionScreen> createState() => _RoutineSessionScreenState();
}

class _RoutineSessionScreenState extends State<RoutineSessionScreen> {
  late int _day;
  late Future<RoutineSession> _session;

  @override
  void initState() {
    super.initState();
    final weekday = (widget.currentDate?.call() ?? DateTime.now()).weekday;
    _day = weekday <= widget.routine.daysPerWeek ? weekday : 1;
    _session = _load();
  }

  Future<RoutineSession> _load() => widget.api.fetchRoutineSession(
    userId: widget.routine.userId,
    routineId: widget.routine.id,
    day: _day,
  );

  void _selectDay(int day) {
    setState(() {
      _day = day;
      _session = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final selectedText = accent.computeLuminance() > .45
        ? Colors.black
        : Colors.white;
    final content = SafeArea(
      top: !widget.embedded,
      child: ListView(
        key: const ValueKey('routine-session-scroll'),
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Positioned.fill(
                bottom: 46,
                child: Image.network(
                  widget.api.mediaBaseUri
                      .resolve(widget.routine.bannerImagePath)
                      .toString(),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
              Positioned.fill(
                bottom: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .2),
                        Colors.black.withValues(alpha: .45),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0, .75, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 170.25),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xDD111111),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final count = widget.routine.daysPerWeek;
                          final width =
                              ((constraints.maxWidth - 6 * (count - 1)) / count)
                                  .clamp(72.0, constraints.maxWidth);
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (var day = 1; day <= count; day++) ...[
                                  if (day > 1) const SizedBox(width: 6),
                                  Semantics(
                                    key: ValueKey('session-day-$day'),
                                    button: true,
                                    selected: day == _day,
                                    child: Container(
                                      width: width,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: day == _day
                                            ? [
                                                BoxShadow(
                                                  color: accent.withValues(
                                                    alpha: .25,
                                                  ),
                                                  blurRadius: 12,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Material(
                                        color: day == _day
                                            ? accent
                                            : const Color(0xFF181818),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: day == _day
                                                ? accent
                                                : Colors.white.withValues(
                                                    alpha: .10,
                                                  ),
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () {
                                            if (day != _day) _selectDay(day);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              6,
                                              10,
                                              6,
                                              0,
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Día $day',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: day == _day
                                                        ? selectedText
                                                        : Colors.white70,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  day == _day
                                                      ? 'Activo'
                                                      : 'Pendiente',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 10,
                                                    color: day == _day
                                                        ? selectedText
                                                        : Colors.white60,
                                                  ),
                                                ),
                                                const SizedBox(height: 7),
                                                Container(
                                                  height: 3,
                                                  width: 36,
                                                  decoration: BoxDecoration(
                                                    color: day == _day
                                                        ? Colors.white
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: FutureBuilder<RoutineSession>(
              future: _session,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return GymCard(
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 34),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error is GymApiException
                              ? (snapshot.error as GymApiException).message
                              : 'No se pudo cargar la sesión.',
                          style: AppText.body,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('retry-session'),
                          onPressed: () => _selectDay(_day),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final session = snapshot.requireData;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'DÍA ${session.day} · ${session.exercises.length} EJERCICIOS',
                      style: AppText.title,
                    ),
                    const SizedBox(height: 20),
                    if (session.exercises.isEmpty)
                      GymCard(
                        child: Text(
                          'Todavía no hay ejercicios asignados a esta sesión.',
                          style: AppText.body,
                        ),
                      ),
                    for (final exercise in session.exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ExerciseCard(exercise: exercise),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rutina asignada',
          style: TextStyle(color: Colors.white),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: content,
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});
  final SessionExercise exercise;

  @override
  Widget build(BuildContext context) {
    final item = exercise;
    final accent = Theme.of(context).colorScheme.primary;
    return GymCard(
      key: ValueKey('session-exercise-${item.id}'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                if (item.imageUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          const Center(child: Text('Imagen no disponible')),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .85),
                          Colors.black.withValues(alpha: .15),
                          const Color(0xFF111111),
                        ],
                        stops: const [0, .7, 1],
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: item.imageUrl.isNotEmpty ? 270 : 130,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .22),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: accent,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.order}. ${item.name}',
                                    style: AppText.title.copyWith(fontSize: 19),
                                  ),
                                  if (item.type.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ejercicio de ${item.type}',
                                      style: AppText.body.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (item.muscle.isNotEmpty) _Tag(item.muscle),
                            if (item.level.isNotEmpty) _Tag(item.level),
                            if (item.type.isNotEmpty) _Tag(item.type),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.series.isNotEmpty)
                  Expanded(
                    child: _ExerciseMetric(
                      Icons.layers_outlined,
                      item.series,
                      'Series',
                    ),
                  ),
                if (item.repetitions.isNotEmpty)
                  Expanded(
                    child: _ExerciseMetric(
                      Icons.repeat_rounded,
                      item.repetitions,
                      'Repeticiones',
                    ),
                  ),
                if (item.restSeconds.isNotEmpty)
                  Expanded(
                    child: _ExerciseMetric(
                      Icons.timer_outlined,
                      '${item.restSeconds} s',
                      'Descanso',
                    ),
                  ),
                if (item.weight.isNotEmpty)
                  Expanded(
                    child: _ExerciseMetric(
                      Icons.monitor_weight_outlined,
                      item.weight,
                      'Peso (kg)',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ExpansionTile(
            key: PageStorageKey('exercise-info-${item.id}'),
            title: Text('Ver información del ejercicio', style: AppText.label),
            subtitle: Text(
              'Técnica, consejos y músculos trabajados',
              style: AppText.body.copyWith(fontSize: 10),
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF303030),
              child: Icon(Icons.info, color: Colors.white70),
            ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            iconColor: Theme.of(context).colorScheme.primary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white.withValues(alpha: .04),
            collapsedBackgroundColor: Colors.white.withValues(alpha: .04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: .1)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: .1)),
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.equipment.isNotEmpty)
                _Detail('EQUIPAMIENTO', item.equipment),
              if (item.description.isNotEmpty)
                _Detail('DESCRIPCIÓN', item.description),
              if (item.instructions.isNotEmpty)
                _Detail('CÓMO REALIZARLO', item.instructions),
              if (item.notes.isNotEmpty) _Detail('INDICACIONES', item.notes),
              if (item.muscleDescription.isNotEmpty)
                _Detail('GRUPO MUSCULAR', item.muscleDescription),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            key: ValueKey('view-exercise-${item.id}'),
            onPressed: () =>
                showExerciseVideo(context, name: item.name, url: item.videoUrl),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Ver ejercicio'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseMetric extends StatelessWidget {
  const _ExerciseMetric(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(height: 4),
      Text(
        value,
        textAlign: TextAlign.center,
        style: AppText.label.copyWith(fontSize: 14),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(fontSize: 9),
      ),
    ],
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.title, this.value);
  final String title, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .05),
            border: Border.all(
              color: Colors.white.withValues(alpha: .8),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.label.copyWith(fontSize: 11.7)),
              const SizedBox(height: 6),
              Text(value, style: AppText.body.copyWith(fontSize: 12.75)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: AppText.body.copyWith(
        fontSize: 12,
        color:
            Color.alphaBlend(
                  Theme.of(context).colorScheme.primary.withValues(alpha: .7),
                  Theme.of(context).scaffoldBackgroundColor,
                ).computeLuminance() >
                .45
            ? Colors.black
            : Colors.white,
      ),
    ),
  );
}
