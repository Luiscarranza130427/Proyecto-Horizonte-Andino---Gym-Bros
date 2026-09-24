import 'package:flutter/material.dart';

import '../models/nutrition_plan.dart';
import '../services/gym_api.dart';
import '../services/nutrition_plan_reference.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';
import '../widgets/generate_nutrition_sheet.dart';
import '../widgets/food_profile_sheet.dart';
import '../widgets/nutrition_overview.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({
    super.key,
    required this.userId,
    required this.api,
    this.scrollController,
  });
  final int userId;
  final GymApi api;
  final ScrollController? scrollController;
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _references = NutritionPlanReference();
  NutritionPlan? _plan;
  FoodProfile? _profile;
  int? _selectedId;
  int _day = 0,
      _epoch = 0,
      _detailRequest = 0,
      _listRequest = 0,
      _profileRequest = 0;
  bool _listing = true,
      _loading = false,
      _profileLoading = true,
      _formOpen = false;
  String? _listError, _detailError, _profileError;

  @override
  void initState() {
    super.initState();
    _loadList();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant NutritionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.api != widget.api) {
      _epoch++;

      _plan = null;
      _profile = null;
      _selectedId = null;
      _detailError = null;
      _loading = false;
      _day = 0;
      _formOpen = false;

      _loadList();
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _epoch++;

    super.dispose();
  }

  Future<void> _loadList() async {
    final epoch = _epoch, request = ++_listRequest;
    setState(() {
      _listing = true;
      _listError = null;
    });
    try {
      final id = await _references.read(widget.api.apiBaseUri, widget.userId);
      if (!mounted || epoch != _epoch || request != _listRequest) return;
      if (id != null) await _select(id);
    } catch (e) {
      if (mounted && epoch == _epoch && request == _listRequest) {
        setState(() => _listError = e.toString());
      }
    } finally {
      if (mounted && epoch == _epoch && request == _listRequest) {
        setState(() => _listing = false);
      }
    }
  }

  Future<void> _loadProfile() async {
    final epoch = _epoch, request = ++_profileRequest;
    setState(() {
      _profileLoading = true;
      _profileError = null;
      _profile = null;
    });
    try {
      final result = await widget.api.foodProfile(widget.userId);
      if (mounted && epoch == _epoch && request == _profileRequest) {
        setState(() => _profile = result);
      }
    } catch (e) {
      if (mounted && epoch == _epoch && request == _profileRequest) {
        setState(() => _profileError = e.toString());
      }
    } finally {
      if (mounted && epoch == _epoch && request == _profileRequest) {
        setState(() => _profileLoading = false);
      }
    }
  }

  Future<void> _select(int id) async {
    final epoch = _epoch, request = ++_detailRequest;
    final userId = widget.userId, api = widget.api;
    setState(() {
      _selectedId = id;
      _loading = true;
      _detailError = null;
      _plan = null;
    });
    try {
      final result = await api.nutritionPlan(userId, id);
      if (!mounted || epoch != _epoch || request != _detailRequest) return;
      _showPlan(result);
    } catch (e) {
      if (mounted && epoch == _epoch && request == _detailRequest) {
        if (e is NutritionApiException && e.status == 404) {
          setState(() {
            _selectedId = null;
            _plan = null;
            _detailError = null;
          });
          try {
            await _references.invalidate(api.apiBaseUri, userId, id);
          } catch (storageError) {
            if (mounted && epoch == _epoch) {
              setState(() => _listError = storageError.toString());
            }
          }
        } else {
          setState(() => _detailError = e.toString());
        }
      }
    } finally {
      if (mounted && epoch == _epoch && request == _detailRequest) {
        setState(() => _loading = false);
      }
    }
  }

  void _showPlan(NutritionPlan plan) {
    final todayIndex = plan.days.indexWhere(
      (d) => d.date == formatCalendarDate(DateTime.now()),
    );
    setState(() {
      _plan = plan;
      _selectedId = plan.id;
      _day = todayIndex < 0 ? 0 : todayIndex;
      _detailError = null;
    });
  }

  Future<void> _editFoodProfile() async {
    if (_formOpen) return;
    final epoch = _epoch;
    setState(() => _formOpen = true);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodProfileSheet(
        api: widget.api,
        userId: widget.userId,
        isCurrent: () => mounted && epoch == _epoch,
      ),
    );
    if (!mounted || epoch != _epoch) return;
    setState(() => _formOpen = false);
    if (saved == true) {
      _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos alimentarios guardados.')),
      );
    }
  }

  Future<void> _generate() async {
    if (_formOpen) return;
    final epoch = _epoch, userId = widget.userId, api = widget.api;
    setState(() => _formOpen = true);
    final plan = await showModalBottomSheet<NutritionPlan>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => GenerateNutritionSheet(
        generate: (input) {
          if (!mounted || epoch != _epoch) {
            throw const NutritionApiException(
              'La sesión cambió. Abre el formulario desde tu perfil actual.',
            );
          }
          return api.generateNutrition(userId, input).then((plan) async {
            try {
              await _references.save(api.apiBaseUri, userId, plan.id);
            } catch (e) {
              if (mounted && epoch == _epoch) {
                setState(
                  () => _listError =
                      'Plan generado, pero no se pudo guardar su referencia: $e',
                );
              }
            }
            return plan;
          });
        },
      ),
    );
    if (!mounted || epoch != _epoch) return;
    setState(() => _formOpen = false);
    if (plan != null && plan.userId == widget.userId) {
      ++_detailRequest;
      _loading = false;
      _showPlan(plan);
    }
  }

  Widget _error(String message, VoidCallback retry) => GymCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: AppText.body),
        TextButton(onPressed: retry, child: const Text('Reintentar consulta')),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return ResponsivePage(
      controller: widget.scrollController,
      scrollViewKey: const ValueKey('nutrition-scroll'),
      children: [
        NutritionBanner(
          url: widget.api.mediaBaseUri
              .resolve('storage/panel_rutinas/comida-banner.webp')
              .toString(),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: FilledButton.icon(
                key: const ValueKey('new-nutrition'),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Generar plan alimentario',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
                icon: const Icon(Icons.restaurant_menu, size: 16),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _formOpen ? null : _generate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                key: const ValueKey('edit-food-profile'),
                onPressed: _formOpen ? null : _editFoodProfile,
                icon: const Icon(Icons.edit_note, size: 16),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _profile == null
                        ? 'Agregar datos alimentarios'
                        : 'Editar datos alimentarios',
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_profileLoading)
          const LinearProgressIndicator()
        else if (_profileError != null)
          _error(_profileError!, _loadProfile),
        const SizedBox(height: 20),
        if (_listing)
          const LinearProgressIndicator()
        else if (_listError != null)
          _error(_listError!, _loadList)
        else if (_selectedId == null)
          const Text('Sin plan disponible', style: AppText.body),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_detailError != null)
          _error(_detailError!, () => _select(_selectedId!))
        else if (plan != null) ...[
          NutritionOverview(plan: plan),
          const SizedBox(height: 16),
          Text(plan.name, style: AppText.title.copyWith(fontSize: 17)),
          Text(plan.goal.replaceAll('_', ' '), style: AppText.body),
          Text('${plan.start} — ${plan.end}', style: AppText.body),
          if (!plan.active) const Text('Plan inactivo', style: AppText.body),
          const SizedBox(height: 16),
          if (plan.days.isEmpty)
            const Text(
              'Este plan no contiene días publicados.',
              style: AppText.body,
            )
          else ...[
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.days[_day].date ==
                                formatCalendarDate(DateTime.now())
                            ? 'Tu plan de hoy'
                            : 'Tu plan del día',
                        style: AppText.label,
                      ),
                      Text(
                        'Día ${plan.days[_day].day} de ${plan.days.length} · ${plan.days[_day].date}',
                        style: AppText.body.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      key: const ValueKey('nutrition-day-selector'),
                      value: _day,
                      style: AppText.label.copyWith(fontSize: 13),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: [
                        for (var i = 0; i < plan.days.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text('Día ${plan.days[i].day}'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _day = value);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.days[_day].meals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MealSummary(meal),
              ),
            ),
            _DailyTotals(day: plan.days[_day], targets: plan.targets),
          ],
          if (plan.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            GymCard(
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text('Advertencias del plan'),
                children: plan.warnings
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(w, style: AppText.body),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

String nutritionAmount(double v) => v.toStringAsFixed(1);
String _nutrients(Nutrients n) =>
    '${nutritionAmount(n.calories)} kcal · Proteínas ${nutritionAmount(n.protein)} g · Carbohidratos ${nutritionAmount(n.carbs)} g · Grasas ${nutritionAmount(n.fat)} g${n.fiber == null ? '' : ' · Fibra ${nutritionAmount(n.fiber!)} g'}';

class _DailyTotals extends StatelessWidget {
  const _DailyTotals({required this.day, required this.targets});
  final NutritionDay day;
  final Nutrients targets;
  @override
  Widget build(BuildContext context) => GymCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PLANIFICADO / OBJETIVO DIARIO', style: AppText.label),
        const SizedBox(height: 10),
        for (final row in [
          ('Energía', day.totals.calories, targets.calories, 'kcal'),
          ('Proteínas', day.totals.protein, targets.protein, 'g'),
          ('Carbohidratos', day.totals.carbs, targets.carbs, 'g'),
          ('Grasas', day.totals.fat, targets.fat, 'g'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${row.$1}: ${nutritionAmount(row.$2)} / ${nutritionAmount(row.$3)} ${row.$4}',
              style: AppText.body,
            ),
          ),
        Text(
          'Fibra planificada: ${nutritionAmount(day.totals.fiber!)} g',
          style: AppText.body,
        ),
      ],
    ),
  );
}

class _MealSummary extends StatelessWidget {
  const _MealSummary(this.meal);
  final PlannedMeal meal;
  @override
  Widget build(BuildContext context) {
    final icon = switch (meal.type) {
      'desayuno' => Icons.wb_sunny_outlined,
      'media_manana' => Icons.coffee_outlined,
      'almuerzo' => Icons.restaurant,
      'media_tarde' => Icons.apple,
      'cena' => Icons.nightlight_outlined,
      _ => Icons.restaurant_menu,
    };
    return GymCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(
              meal.time.length >= 5 ? meal.time.substring(0, 5) : meal.time,
              style: AppText.label.copyWith(fontSize: 11),
            ),
          ],
        ),
        title: Text(meal.name, style: AppText.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            for (final food in meal.foods)
              Text(
                '• ${food.snapshot.name} · ${nutritionAmount(food.quantity)} ${food.unit}',
                style: AppText.body.copyWith(fontSize: 12),
              ),
            const SizedBox(height: 8),
            Text(
              '${nutritionAmount(meal.totals.calories)} kcal',
              style: AppText.label.copyWith(fontSize: 13),
            ),
          ],
        ),
        children: [_MealCard(meal)],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard(this.meal);
  final PlannedMeal meal;
  @override
  Widget build(BuildContext context) => GymCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(meal.name, style: AppText.title.copyWith(fontSize: 18)),
        Text(meal.time, style: AppText.body),
        const SizedBox(height: 10),
        ...meal.foods.map(
          (food) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.snapshot.name, style: AppText.label),
                Text(
                  'Porción: ${nutritionAmount(food.quantity)} ${food.unit}',
                  style: AppText.body,
                ),
                Text(
                  _nutrients(food.snapshot.nutrients),
                  style: AppText.body.copyWith(fontSize: 12),
                ),
                ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Notas y detalle nutricional'),
                  children: [
                    if (food.notes?.isNotEmpty == true)
                      Text(food.notes!, style: AppText.body),
                    Text(
                      'Preparación: ${food.snapshot.preparation}\nFuente: ${food.snapshot.source}\nBase de referencia: ${nutritionAmount(food.snapshot.baseQuantity)} ${food.snapshot.baseUnit}\nLos nutrientes mostrados corresponden a la porción guardada.',
                      style: AppText.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Text(
          'Total planificado: ${_nutrients(meal.totals)}',
          style: AppText.body.copyWith(fontSize: 12),
        ),
      ],
    ),
  );
}
