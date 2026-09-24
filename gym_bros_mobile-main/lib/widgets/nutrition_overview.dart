import 'package:flutter/material.dart';

import '../models/nutrition_plan.dart';
import '../theme/app_theme.dart';
import 'gym_widgets.dart';

class NutritionBanner extends StatelessWidget {
  const NutritionBanner({super.key, required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, error, stack) =>
                const ColoredBox(color: Color(0xff151b1b)),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: .85),
                  Colors.black.withValues(alpha: .12),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Come mejor',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Logra más',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Planes personalizados\npara un mejor tú',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class NutritionOverview extends StatelessWidget {
  const NutritionOverview({super.key, required this.plan});
  final NutritionPlan plan;
  String amount(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
  @override
  Widget build(BuildContext context) {
    final c = plan.calculation;
    final facts = <(IconData, String, String)>[
      if (c.age != null)
        (Icons.cake_outlined, 'Edad', '${amount(c.age!)} años'),
      if (c.sex != null && c.sex!.isNotEmpty)
        (
          Icons.person_outline,
          'Sexo',
          '${c.sex![0].toUpperCase()}${c.sex!.substring(1)}',
        ),
      if (c.weight != null)
        (Icons.monitor_weight_outlined, 'Peso', '${amount(c.weight!)} kg'),
      if (c.height != null) (Icons.height, 'Altura', '${amount(c.height!)} cm'),
      (Icons.flag_outlined, 'Objetivo', plan.goal.replaceAll('_', ' ')),
      if (c.meals != null)
        (Icons.restaurant_outlined, 'Comidas al día', '${c.meals} comidas'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GymCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: ExpansionTile(
            key: ValueKey('nutrition-facts-${plan.id}'),
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'Tus datos',
              style: AppText.title.copyWith(fontSize: 15),
            ),
            children: [
              const Text(
                'Datos utilizados para generar este plan',
                style: AppText.body,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in facts)
                      SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: _InfoTile(icon: f.$1, label: f.$2, value: f.$3),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GymCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: ExpansionTile(
            key: ValueKey('nutrition-targets-${plan.id}'),
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'Recomendación diaria',
              style: AppText.title.copyWith(fontSize: 15),
            ),
            children: [
              const Text(
                'Objetivos de tu plan alimentario',
                style: AppText.body,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 420 ? 4 : 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in <(IconData, String, String)>[
                        (
                          Icons.local_fire_department,
                          'Energía',
                          '${amount(plan.targets.calories)} kcal',
                        ),
                        (
                          Icons.egg_alt_outlined,
                          'Proteínas',
                          '${amount(plan.targets.protein)} g',
                        ),
                        (
                          Icons.grain,
                          'Carbohidratos',
                          '${amount(plan.targets.carbs)} g',
                        ),
                        (
                          Icons.water_drop_outlined,
                          'Grasas',
                          '${amount(plan.targets.fat)} g',
                        ),
                      ])
                        SizedBox(
                          width:
                              (constraints.maxWidth - 8 * (columns - 1)) /
                              columns,
                          child: _InfoTile(
                            icon: f.$1,
                            label: f.$2,
                            value: f.$3,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .035),
      border: Border.all(color: Colors.white.withValues(alpha: .13)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(height: 8),
        Text(label, style: AppText.body.copyWith(fontSize: 12)),
        Text(value, style: AppText.label.copyWith(fontSize: 14)),
      ],
    ),
  );
}
