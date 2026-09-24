import 'package:flutter/material.dart';

import '../models/nutrition_plan.dart';
import '../services/gym_api.dart';
import '../theme/app_theme.dart';
import 'gym_widgets.dart';

class FoodProfileSheet extends StatefulWidget {
  const FoodProfileSheet({
    super.key,
    required this.api,
    required this.userId,
    required this.isCurrent,
  });
  final GymApi api;
  final int userId;
  final bool Function() isCurrent;
  @override
  State<FoodProfileSheet> createState() => _FoodProfileSheetState();
}

class _FoodProfileSheetState extends State<FoodProfileSheet> {
  final _form = GlobalKey<FormState>();
  String? _existingReview;
  List<Json> _foods = [];
  final _allergies = <int>{}, _intolerances = <int>{};
  final _preferences = <int, String>{};
  final _flags = <String, bool?>{
    'embarazo': null,
    'lactancia': null,
    'requiere_plan_clinico': null,
    'apto_plan_general': null,
  };
  static const _labels = {
    'embarazo': 'Embarazo',
    'lactancia': 'Lactancia',
    'requiere_plan_clinico': 'Requiere plan clínico (según revisión)',
    'apto_plan_general': 'Apto para plan general (según revisión)',
  };
  String? _sex, _date, _error;
  bool _loading = true, _saving = false, _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object?>([
        widget.api.editableFoodProfile(widget.userId),

        widget.api.foodProfileCatalog(restrictions: false),
      ]);
      if (!mounted) return;
      final profile = values[0] as Json?;

      _foods = values[1] as List<Json>;
      _allergies.clear();
      _intolerances.clear();
      _preferences.clear();
      for (final food in _foods) {
        _preferences[food['id'] as int] = 'preferido';
      }
      if (profile != null) {
        _sex = profile['sexo_calculo'] as String?;
        if (!['masculino', 'femenino'].contains(_sex)) _sex = null;
        _existingReview = profile['revision_profesional'] as String?;
        _date = profile['revisado_en'] == null
            ? null
            : calendarDate(profile['revisado_en']);
        for (final key in _flags.keys) {
          _flags[key] = profile[key] == null
              ? null
              : nutritionBool(profile[key]);
        }
        for (final r in nutritionList(profile['restricciones'], (j) => j)) {
          final id = nutritionId(r['id_restricciones_alimentarias']);
          if (r['tipo'] == 'alergia') {
            _allergies.add(id);
          } else if (r['tipo'] == 'intolerancia') {
            _intolerances.add(id);
          } else {
            throw const FormatException('Tipo de restricción desconocido.');
          }
        }
        for (final p in nutritionList(profile['preferencias'], (j) => j)) {
          final id = nutritionId(p['id_alimentos']);
          final type = nutritionText(p['tipo']);
          if (!['preferido', 'rechazado'].contains(type)) {
            throw const FormatException('Preferencia desconocida.');
          }
          _preferences[id] = type;
          if (!_foods.any((v) => v['id'] == id)) {
            _foods.add({'id': id, 'nombre': 'Alimento registrado #$id'});
          }
        }
      }
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;

    if (!widget.isCurrent()) {
      setState(
        () => _error =
            'La sesión cambió. Cierra este formulario y vuelve a abrirlo.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.saveFoodProfile(widget.userId, {
        'sexo_calculo': _sex,
        ..._flags,
        if (_sex != 'femenino') 'embarazo': false,
        if (_sex != 'femenino') 'lactancia': false,
        if (_existingReview != null) 'revision_profesional': _existingReview,
        if (_date != null) 'revisado_en': _date,
        'alergias': _allergies.toList(),
        'intolerancias': _intolerances.toList(),
        'preferencias': [
          for (final p in _preferences.entries)
            {'id_alimentos': p.key, 'tipo': p.value},
        ],
      });
      if (mounted) Navigator.pop(context, true);
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
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('DATOS ALIMENTARIOS', style: AppText.title),
                  const SizedBox(height: 16),
                  if (_loading)
                    const LinearProgressIndicator()
                  else if (!_loaded) ...[
                    Text(_error!, style: AppText.body),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Reintentar consulta'),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: const InputDecoration(
                        labelText: 'Sexo para el cálculo',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'masculino',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'femenino',
                          child: Text('Femenino'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _sex = v),
                      validator: (v) =>
                          v == null ? 'Selecciona una opción.' : null,
                    ),
                    for (final key in _flags.keys.where(
                      (key) =>
                          _sex == 'femenino' ||
                          (key != 'embarazo' && key != 'lactancia'),
                    ))
                      Padding(
                        key: ValueKey(key),
                        padding: const EdgeInsets.only(top: 12),
                        child: DropdownButtonFormField<bool>(
                          initialValue: _flags[key],
                          isExpanded: true,
                          decoration: InputDecoration(labelText: _labels[key]),
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Sí')),
                            DropdownMenuItem(value: false, child: Text('No')),
                          ],
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _flags[key] = v),
                          validator: (v) =>
                              v == null ? 'Selecciona una opción.' : null,
                        ),
                      ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Preferencias e intolerancias'),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Desmarca los alimentos que no deseas incluir en tu plan.',
                            style: AppText.body,
                          ),
                        ),
                        if (_foods.isEmpty)
                          const Text('No hay alimentos en el catálogo.'),
                        LayoutBuilder(
                          builder: (context, constraints) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final food in _foods)
                                SizedBox(
                                  width: (constraints.maxWidth - 8) / 2,
                                  child: CheckboxListTile(
                                    key: ValueKey('food-choice-${food['id']}'),
                                    contentPadding: const EdgeInsets.all(4),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(food['nombre'] as String),
                                    value:
                                        _preferences[food['id']] != 'rechazado',
                                    onChanged: _saving
                                        ? null
                                        : (selected) => setState(() {
                                            _preferences[food['id']
                                                as int] = selected == true
                                                ? 'preferido'
                                                : 'rechazado';
                                          }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_error!, style: AppText.body),
                      ),
                    PrimaryButton(
                      label: _saving
                          ? 'Guardando…'
                          : 'Guardar datos alimentarios',
                      labelFontSize: 12,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
