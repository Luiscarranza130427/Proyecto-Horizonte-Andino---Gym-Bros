import 'package:flutter/material.dart';

import '../models/gym_session.dart';
import '../services/gym_api.dart';
import '../theme/app_theme.dart';
import 'gym_widgets.dart';

class NewMeasurementsSheet extends StatefulWidget {
  const NewMeasurementsSheet({
    super.key,
    required this.user,
    this.profile,
    this.initialEvaluation,
    required this.onSubmit,
    required this.onSaved,
  });

  final GymUser user;
  final GymTrainingProfile? profile;
  final Map<String, dynamic>? initialEvaluation;
  final Future<GymProgress> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onSaved;

  @override
  State<NewMeasurementsSheet> createState() => _NewMeasurementsSheetState();
}

class _NewMeasurementsSheetState extends State<NewMeasurementsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _selections = <String, String?>{};
  bool _saving = false;
  String? _error;
  bool get _editing => widget.initialEvaluation != null;

  static const _measures = <String, String>{
    'peso': 'Peso (kg)',
    'altura': 'Altura (cm)',
    'porcentaje_grasa': 'Grasa corporal (%)',
    'masa_muscular': 'Masa muscular (kg)',
    'cintura': 'Cintura (cm)',
    'pecho': 'Pecho (cm)',
    'brazo': 'Brazo (cm)',
    'muslo': 'Muslo (cm)',
    'cadera': 'Cadera (cm)',
  };
  static const _numbers = <String, String>{
    'edad': 'Edad',
    'dias_semana': 'Días por semana',
    'tiempo_sesion_min': 'Tiempo por sesión (min)',
  };
  static const _choices = <String, Map<String, String>>{
    'nivel_experiencia': {
      '1a3meses': '1 a 3 meses',
      '4a8meses': '4 a 8 meses',
      '1ano': '1 año',
      'mas1ano': 'Más de 1 año',
      '2anos': '2 años',
      '3anos_mas': '3 años o más',
      '3anosamas': '3 años en adelante',
    },
    'actividad_diaria': {
      'sedentario': 'Sedentario',
      'activo_ligero': 'Actividad ligera',
      'moderadamente_activo': 'Moderadamente activo',
      'muy_activo': 'Muy activo',
    },
    'objetivo': {
      'perdida_peso': 'Pérdida de peso',
      'ganancia_muscular': 'Ganancia muscular',
      'resistencia': 'Resistencia',
      'recomposicion': 'Recomposición',
      'aumento_fuerza': 'Aumento de fuerza',
      'salud': 'Salud',
    },
    'restricciones': {
      'sin-restricciones': 'Sin restricciones',
      'manco': 'Limitación de una mano',
      'cojo': 'Dificultad al caminar',
      'paralitico': 'Parálisis',
      'movilidad-reducida': 'Movilidad reducida',
      'amputacion-de-extremidad': 'Amputación de extremidad',
      'silla-de-ruedas': 'Silla de ruedas',
      'uso-de-muletas': 'Uso de muletas',
      'uso-de-baston': 'Uso de bastón',
      'uso-de-andador': 'Uso de andador',
      'limitacion-de-brazos': 'Limitación de brazos',
      'limitacion-de-piernas': 'Limitación de piernas',
      'problemas-de-equilibrio': 'Problemas de equilibrio',
      'problemas-de-coordinacion': 'Problemas de coordinación',
      'lesion-reciente': 'Lesión reciente',
      'cirugia-reciente': 'Cirugía reciente',
      'dolor-musculoesqueletico': 'Dolor musculoesquelético',
      'limitacion-cardiovascular': 'Limitación cardiovascular',
      'limitacion-respiratoria': 'Limitación respiratoria',
      'discapacidad-visual': 'Discapacidad visual',
      'discapacidad-auditiva': 'Discapacidad auditiva',
    },
  };
  static const _choiceLabels = {
    'nivel_experiencia': 'Experiencia',
    'actividad_diaria': 'Actividad diaria',
    'objetivo': 'Objetivo',
    'restricciones': 'Restricciones',
  };

  @override
  void initState() {
    super.initState();
    for (final name in [..._measures.keys, ..._numbers.keys]) {
      _controllers[name] = TextEditingController();
    }
    for (final name in _measures.keys) {
      final value = widget.initialEvaluation?[name];
      if (value != null) _controllers[name]!.text = value.toString();
    }
    final birth = DateTime.tryParse(widget.user.birthDate);
    if (birth != null) {
      final now = DateTime.now();
      final age =
          now.year -
          birth.year -
          (now.month < birth.month ||
                  now.month == birth.month && now.day < birth.day
              ? 1
              : 0);
      if (age > 0) _controllers['edad']!.text = '$age';
    }
    final profile = widget.profile;
    final initial = {
      'nivel_experiencia': profile?.experience,
      'actividad_diaria': profile?.dailyActivity,
      'objetivo': profile?.goal,
      'restricciones': profile?.restrictions,
    };
    for (final entry in _choices.entries) {
      final value = initial[entry.key];
      _selections[entry.key] = entry.value.containsKey(value) ? value : null;
    }
    if (profile != null) {
      _controllers['dias_semana']!.text = '${profile.daysPerWeek}';
      _controllers['tiempo_sesion_min']!.text = '${profile.minutesPerSession}';
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateNumber(String key, String? input) {
    final text = (input ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return 'Campo obligatorio';
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return 'Ingresa un número válido';
    if (_numbers.containsKey(key)) {
      if (int.tryParse(text) == null) return 'Ingresa un número entero';
      final max = key == 'dias_semana'
          ? 6
          : key == 'tiempo_sesion_min'
          ? 180
          : 2147483647;
      final min = key == 'dias_semana' ? 2 : 1;
      if (value < min || value > max) {
        return 'Ingresa un valor entre $min y $max';
      }
    } else {
      if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
        return 'Usa hasta 2 decimales';
      }
      final allowsZero = key == 'porcentaje_grasa' || key == 'masa_muscular';
      final max = key == 'porcentaje_grasa'
          ? 100
          : key == 'altura'
          ? 999.99
          : 9999.99;
      if (value < 0 || (!allowsZero && value == 0) || value > max) {
        return 'Medida fuera del rango permitido';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final values = <String, dynamic>{
      if (!_editing) ...{
        'fecha_evaluacion': DateTime.now().toIso8601String().split('T').first,
        ..._selections,
      },
    };
    for (final entry in _controllers.entries) {
      if (_editing && !_measures.containsKey(entry.key)) continue;
      final text = entry.value.text.trim().replaceAll(',', '.');
      final value = _numbers.containsKey(entry.key)
          ? int.parse(text)
          : double.parse(text);
      if (!_editing ||
          value != double.tryParse('${widget.initialEvaluation?[entry.key]}')) {
        values[entry.key] = value;
      }
    }
    final days = widget.profile?.availableDays;
    if (!_editing &&
        days != null &&
        days.isNotEmpty &&
        days.length == values['dias_semana']) {
      values['eleccion_dias'] = days;
    }
    if (values.isEmpty) {
      setState(() {
        _saving = false;
        _error = 'Modifica al menos una medida para guardar los cambios.';
      });
      return;
    }
    try {
      await widget.onSubmit(values);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop();
      widget.onSaved();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is GymApiException
              ? error.message
              : 'No se pudo completar el registro. Inténtalo nuevamente.';
        });
      }
    }
  }

  Widget _numberField(String key, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('measurement-$key'),
      controller: _controllers[key],
      enabled: !_saving,
      keyboardType: TextInputType.numberWithOptions(
        decimal: _measures.containsKey(key),
      ),
      decoration: InputDecoration(labelText: label),
      validator: (value) => _validateNumber(key, value),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _editing
                      ? 'Editar últimas medidas'
                      : 'Registrar nuevas medidas',
                  style: AppText.title,
                ),
                const SizedBox(height: 14),
                Text(
                  _editing
                      ? 'Evaluación del ${widget.initialEvaluation!['fecha_evaluacion']}. Modifica las medidas que deseas corregir.'
                      : 'Completa todas las medidas para registrar tu evaluación.',
                  style: AppText.body,
                ),
                const SizedBox(height: 14),
                for (final entry in _measures.entries)
                  _numberField(entry.key, entry.value),
                if (!_editing) ...[
                  const Text('Perfil de entrenamiento', style: AppText.title),
                  const SizedBox(height: 12),
                  for (final entry in _choices.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('measurement-${entry.key}'),
                        initialValue: _selections[entry.key],
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: _choiceLabels[entry.key],
                        ),
                        items: entry.value.entries
                            .map(
                              (option) => DropdownMenuItem(
                                value: option.key,
                                child: Text(
                                  option.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                () => _selections[entry.key] = value,
                              ),
                        validator: (value) =>
                            value == null ? 'Selecciona una opción' : null,
                      ),
                    ),
                  for (final entry in _numbers.entries)
                    _numberField(entry.key, entry.value),
                ],
                if (_error != null) ...[
                  Text(
                    _error!,
                    key: const ValueKey('measurement-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  key: const ValueKey('save-measurements'),
                  label: _saving
                      ? 'Guardando...'
                      : _editing
                      ? 'Guardar cambios'
                      : 'Guardar medidas',
                  icon: Icons.save_outlined,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
