import 'package:flutter/material.dart';

import '../models/gym_company.dart';
import '../models/gym_session.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({
    super.key,
    required this.routines,
    required this.sensations,
    required this.company,
    required this.onOpenSession,
    this.scrollController,
  });

  final List<GymRoutine> routines;
  final List<GymSensation> sensations;
  final GymCompany company;
  final ValueChanged<GymRoutine> onOpenSession;
  final ScrollController? scrollController;

  void _openRoutine(BuildContext context, GymRoutine routine) {
    final routineSensations = sensations
        .where((item) => item.routineId == routine.id)
        .toList(growable: false);

    showGymSheet(
      context,
      title: routine.name,
      actionLabel: 'Cerrar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(routine.description, style: AppText.body),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: '${routine.estimatedMinutes} MIN',
              ),
              _InfoChip(
                icon: Icons.calendar_view_week_rounded,
                label: '${routine.daysPerWeek} DÍAS/SEMANA',
              ),
              _InfoChip(
                icon: Icons.flag_outlined,
                label: routine.goal.replaceAll('_', ' ').toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DataLine(label: 'Inicio', value: routine.startDate),
          _DataLine(label: 'Fin', value: routine.endDate),
          _DataLine(
            label: 'Estado',
            value: routine.active ? 'Activa' : 'Inactiva',
          ),
          const Divider(color: AppColors.border, height: 30),
          Text(
            'SENSACIONES REGISTRADAS',
            style: AppText.label.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          if (routineSensations.isEmpty)
            Text('No hay registros para esta rutina.', style: AppText.body)
          else
            ...routineSensations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: GymCard(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.date, style: AppText.label),
                      const SizedBox(height: 7),
                      Text(
                        'Energía ${item.energy} · Dificultad ${item.difficulty} · Fatiga ${item.fatigue} · Dolor ${item.pain}',
                        style: AppText.body.copyWith(fontSize: 12),
                      ),
                      if (item.comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.comment, style: AppText.body),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenSession(routine);
            },
            icon: const Icon(Icons.fitness_center_rounded),
            label: const Text('VER EJERCICIOS POR SESIÓN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final secondary = _parseHexColor(
      company.primaryColorHex,
      fallback: Theme.of(context).colorScheme.surface,
    );
    return ResponsivePage(
      controller: scrollController,
      scrollViewKey: const ValueKey('routines-scroll'),
      children: [
        FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'TUS\n'),
                    TextSpan(
                      text: 'RUTINAS',
                      style: AppText.display.copyWith(color: accent),
                    ),
                  ],
                ),
                style: AppText.display,
              ),
              const SizedBox(height: 12),
              Text(
                'Rutinas asignadas a tu usuario desde la API.',
                style: AppText.body.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        if (routines.isEmpty)
          const _EmptyRoutine()
        else
          ...routines.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 60 + entry.key * 35),
                child: GymCard(
                  key: ValueKey('routine-${entry.value.id}'),
                  onTap: () => _openRoutine(context, entry.value),
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 128,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [secondary, accent.withValues(alpha: .7)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 18,
                                top: 18,
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: Colors.white.withValues(alpha: .22),
                                  size: 78,
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 15,
                                child: Text(
                                  entry.value.name.toUpperCase(),
                                  style: AppText.headline.copyWith(
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 14,
                                runSpacing: 7,
                                children: [
                                  _Meta(
                                    icon: Icons.schedule_rounded,
                                    text: '${entry.value.estimatedMinutes} MIN',
                                  ),
                                  _Meta(
                                    icon: Icons.calendar_month_rounded,
                                    text:
                                        '${entry.value.daysPerWeek} DÍAS/SEMANA',
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Color _parseHexColor(String hex, {Color fallback = AppColors.primary}) {
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length != 6) return fallback;
  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? fallback : Color(value);
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
          const SizedBox(width: 6),
          Text(label, style: AppText.label.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _DataLine extends StatelessWidget {
  const _DataLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body)),
          Text(value, style: AppText.label),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 5),
        Text(text, style: AppText.body.copyWith(fontSize: 12)),
      ],
    );
  }
}

class _EmptyRoutine extends StatelessWidget {
  const _EmptyRoutine();

  @override
  Widget build(BuildContext context) {
    return GymCard(
      child: Row(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay rutinas vinculadas a tu usuario.',
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}
