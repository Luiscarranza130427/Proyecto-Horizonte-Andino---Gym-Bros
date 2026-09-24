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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GENERAR PLAN ALIMENTARIO', style: AppText.title),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final today = DateTime.parse(
                            formatCalendarDate(DateTime.now()),
                          );
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _start.isBefore(today)
                                ? today
                                : _start,
                            firstDate: today,
                            lastDate: today.add(const Duration(days: 30)),
                          );
                          if (mounted && date != null) {
                            setState(() => _start = date);
                          }
                        },
                  child: Text('Inicio: ${formatCalendarDate(_start)}'),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _days,
                  decoration: const InputDecoration(
                    labelText: 'Duración (días)',
                  ),
                  items: List.generate(
                    14,
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: _saving ? null : (v) => setState(() => _days = v!),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _meals,
                  decoration: const InputDecoration(
                    labelText: 'Comidas por día',
                  ),
                  items: [3, 4, 5]
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _meals = v!),
                ),
                const SizedBox(height: 12),
                for (final type in NutritionGeneration.types(_meals))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(switch (type) {
                      'media_manana' => 'Media mañana',
                      'media_tarde' => 'Media tarde',
                      _ => '${type[0].toUpperCase()}${type.substring(1)}',
                    }),
                    trailing: Text(_times[type]!),
                    onTap: _saving
                        ? null
                        : () async {
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
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              );
                            }
                          },
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_error!, style: AppText.body),
                  ),
                PrimaryButton(
                  key: const ValueKey('submit-nutrition'),
                  label: 'Generar plan',
                  loading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
