import 'package:flutter/material.dart';

import '../models/nutrition_plan.dart';
import '../theme/app_theme.dart';
import 'gym_widgets.dart';

class GenerateNutritionSheet extends StatefulWidget {
  const GenerateNutritionSheet({super.key, required this.generate});
  final Future<NutritionPlan> Function(NutritionGeneration) generate;
  @override
  State<GenerateNutritionSheet> createState() => _GenerateNutritionSheetState();
}

class _GenerateNutritionSheetState extends State<GenerateNutritionSheet> {
  DateTime _start = DateTime.now();
  int _days = 7, _meals = 3;
  bool _saving = false;
  String? _error;
  final _times = {
    'desayuno': '08:00',
    'media_manana': '10:30',
    'almuerzo': '13:00',
    'media_tarde': '16:30',
    'cena': '20:00',
  };
  Future<void> _submit() async {
    if (_saving) return;
    final input = NutritionGeneration(
      start: formatCalendarDate(_start),
      days: _days,
      meals: _meals,
      times: {
        for (final type in NutritionGeneration.types(_meals))
          type: _times[type]!,
      },
    );
    try {
      input.toJson();
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final plan = await widget.generate(input);
      if (mounted) Navigator.of(context).pop(plan);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickStart() async {
    final today = DateTime.parse(formatCalendarDate(DateTime.now()));
    final date = await showDatePicker(
      context: context,
      initialDate: _start.isBefore(today) ? today : _start,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (mounted && date != null) setState(() => _start = date);
  }

  Future<void> _pickTime(String type) async {
    final parts = _times[type]!.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (mounted && time != null) {
      setState(
        () => _times[type] =
            '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  static String _mealName(String type) => switch (type) {
    'media_manana' => 'Media mañana',
    'media_tarde' => 'Media tarde',
    _ => '${type[0].toUpperCase()}${type.substring(1)}',
  };

  /// 2026-09-24 → 24/09/2026, como se lee una fecha en Perú.
  static String _readableDate(DateTime date) {
    final parts = formatCalendarDate(date).split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Widget _daysField() => DropdownButtonFormField<int>(
    key: const ValueKey('nutrition-days'),
    initialValue: _days,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Duración (días)'),
    items: List.generate(
      14,
      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
    ),
    onChanged: _saving ? null : (v) => setState(() => _days = v!),
  );

  Widget _mealsField() => DropdownButtonFormField<int>(
    key: const ValueKey('nutrition-meals'),
    initialValue: _meals,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Comidas por día'),
    items: [
      3,
      4,
      5,
    ].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
    onChanged: _saving ? null : (v) => setState(() => _meals = v!),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final types = NutritionGeneration.types(_meals);
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  const Text('GENERAR PLAN ALIMENTARIO', style: AppText.title),
                  const SizedBox(height: 6),
                  const Text(
                    'Elige cuándo empieza, cuántos días dura y a qué hora '
                    'haces cada comida.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    key: const ValueKey('nutrition-start'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: _saving ? null : _pickStart,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de inicio',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        suffixIcon: Icon(Icons.edit_calendar_rounded),
                      ),
                      child: Text(
                        _readableDate(_start),
                        style: AppText.body.copyWith(color: AppColors.text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Lado a lado si caben; en pantallas estrechas, apilados.
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth >= 320
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _daysField()),
                              const SizedBox(width: 12),
                              Expanded(child: _mealsField()),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _daysField(),
                              const SizedBox(height: 14),
                              _mealsField(),
                            ],
                          ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'HORARIO DE COMIDAS',
                    style: AppText.label.copyWith(color: accent),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toca una comida para cambiar su hora.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (final (index, type) in types.indexed) ...[
                          if (index > 0)
                            const Divider(height: 1, color: AppColors.border),
                          InkWell(
                            key: ValueKey('meal-time-$type'),
                            onTap: _saving ? null : () => _pickTime(type),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_rounded,
                                    size: 18,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _mealName(type),
                                      style: AppText.body.copyWith(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _times[type]!,
                                      style: AppText.body.copyWith(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: AppText.body.copyWith(color: AppColors.text),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  PrimaryButton(
                    key: const ValueKey('submit-nutrition'),
                    label: 'Generar plan',
                    loading: _saving,
                    onPressed: _saving ? null : _submit,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
