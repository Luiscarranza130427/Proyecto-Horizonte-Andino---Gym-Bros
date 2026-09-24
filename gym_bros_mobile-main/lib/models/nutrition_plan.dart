typedef Json = Map<String, dynamic>;

Json nutritionObject(Object? value) {
  if (value is! Json) {
    throw const FormatException('Se esperaba un objeto alimentario.');
  }
  return value;
}

List<T> nutritionList<T>(Object? value, T Function(Json) parse) {
  if (value is! List) {
    throw const FormatException('Se esperaba una lista alimentaria.');
  }
  return value.map((v) => parse(nutritionObject(v))).toList();
}

double nutritionNumber(Object? value) {
  final result = value is num ? value.toDouble() : double.tryParse('$value');
  if (result == null || !result.isFinite || result < 0) {
    throw const FormatException('Falta un valor nutricional válido.');
  }
  return result;
}

int nutritionId(Object? value) {
  final n = nutritionNumber(value);
  if (n < 1 || n != n.roundToDouble()) {
    throw const FormatException('Identificador inválido.');
  }
  return n.toInt();
}

String nutritionText(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Falta un dato del plan.');
  }
  return value;
}

String calendarDate(Object? value) {
  final text = nutritionText(value);
  final match = RegExp(r'^\d{4}-\d{2}-\d{2}(?=$|T| )').firstMatch(text);
  if (match == null) throw const FormatException('Fecha inválida.');
  final date = text.substring(0, 10);
  final parsed = DateTime.tryParse(date);
  if (parsed == null || formatCalendarDate(parsed) != date) {
    throw const FormatException('Fecha inválida.');
  }
  return date;
}

String formatCalendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
bool nutritionBool(Object? value) => switch (value) {
  true || 1 || '1' => true,
  false || 0 || '0' => false,
  _ => throw const FormatException('Estado inválido.'),
};

class Nutrients {
  Nutrients(Json j, {bool target = false})
    : calories = nutritionNumber(j['calorias']),
      protein = nutritionNumber(j['proteinas']),
      carbs = nutritionNumber(j['carbohidratos']),
      fat = nutritionNumber(j['grasas']),
      fiber = target && j['fibra'] == null ? null : nutritionNumber(j['fibra']);
  final double calories, protein, carbs, fat;
  final double? fiber;
}

class NutritionSummary {
  NutritionSummary(Json j)
    : id = nutritionId(j['id']),
      userId = nutritionId(j['id_usuarios']),
      name = nutritionText(j['nombre']);
  final int id, userId;
  final String name;
}

class NutritionSnapshot {
  NutritionSnapshot(Json j)
    : name = nutritionText(j['nombre']),
      baseQuantity = nutritionNumber(j['base_cantidad']),
      baseUnit = nutritionText(j['base_unidad']),
      preparation = nutritionText(j['estado_preparacion']),
      source = nutritionText(j['fuente']),
      nutrients = Nutrients(nutritionObject(j['nutrientes']));
  final String name, baseUnit, preparation, source;
  final double baseQuantity;
  final Nutrients nutrients;
}

class PlannedFood {
  PlannedFood(Json j)
    : id = nutritionId(j['id']),
      foodId = nutritionId(j['id_alimentos']),
      quantity = nutritionNumber(j['cantidad']),
      unit = nutritionText(j['unidad']),
      notes = j['notas'] as String?,
      snapshot = NutritionSnapshot(nutritionObject(j['detalle_nutricional']));
  final int id, foodId;
  final double quantity;
  final String unit;
  final String? notes;
  final NutritionSnapshot snapshot;
}

class PlannedMeal {
  PlannedMeal(Json j)
    : id = nutritionId(j['id']),
      name = nutritionText(j['nombre']),
      type = nutritionText(j['tipo']),
      order = nutritionId(j['orden']),
      time = nutritionText(j['hora_sugerida']),
      targets = Nutrients(nutritionObject(j['objetivos']), target: true),
      foods = nutritionList(j['alimentos'], PlannedFood.new),
      totals = Nutrients(nutritionObject(j['totales']));
  final int id, order;
  final String name, type, time;
  final Nutrients targets, totals;
  final List<PlannedFood> foods;
}

class NutritionDay {
  NutritionDay(Json j)
    : day = nutritionId(j['dia']),
      date = calendarDate(j['fecha']),
      meals = nutritionList(j['comidas'], PlannedMeal.new)
        ..sort((a, b) => a.order.compareTo(b.order)),
      totals = Nutrients(nutritionObject(j['totales']));
  final int day;
  final String date;
  final List<PlannedMeal> meals;
  final Nutrients totals;
}

class NutritionPlan {
  NutritionPlan(Json j)
    : id = nutritionId(j['id']),
      userId = nutritionId(j['id_usuarios']),
      evaluationId = nutritionId(j['id_evaluaciones_fisicas']),
      name = nutritionText(j['nombre']),
      goal = nutritionText(j['objetivo']),
      start = calendarDate(j['fecha_inicio']),
      end = calendarDate(j['fecha_fin']),
      active = nutritionBool(j['estado']),
      calculation = NutritionCalculation(nutritionObject(j['calculo'])),
      targets = Nutrients(
        nutritionObject(nutritionObject(j['calculo'])['objetivos']),
        target: true,
      ),
      days = nutritionList(j['dias'], NutritionDay.new)
        ..sort((a, b) => a.day.compareTo(b.day)),
      totals = Nutrients(nutritionObject(j['totales_plan'])),
      warnings = (j['advertencias'] as List).map(nutritionText).toList() {
    if (days.map((d) => d.day).toSet().length != days.length) {
      throw const FormatException('Días duplicados.');
    }
  }
  final int id, userId, evaluationId;
  final String name, goal, start, end;
  final bool active;
  final NutritionCalculation calculation;
  final Nutrients targets, totals;
  final List<NutritionDay> days;
  final List<String> warnings;
}

class NutritionCalculation {
  NutritionCalculation(Json j)
    : age = j['edad_calculo'] == null
          ? null
          : nutritionNumber(j['edad_calculo']),
      weight = j['peso_kg'] == null ? null : nutritionNumber(j['peso_kg']),
      height = j['altura_cm'] == null ? null : nutritionNumber(j['altura_cm']),
      sex = j['sexo_calculo'] as String?,
      meals = j['cantidad_comidas'] == null
          ? null
          : nutritionId(j['cantidad_comidas']);
  final double? age, weight, height;
  final String? sex;
  final int? meals;
}

class FoodProfile {
  FoodProfile(Json j)
    : userId = nutritionId(j['id_usuarios']),
      eligible = nutritionBool(j['apto_plan_general']),
      clinical = nutritionBool(j['requiere_plan_clinico']),
      review = j['revision_profesional'] as String?;
  final int userId;
  final bool eligible, clinical;
  final String? review;
}

class NutritionGeneration {
  NutritionGeneration({
    required this.start,
    required this.days,
    required this.meals,
    required this.times,
  });
  final String start;
  final int days, meals;
  final Map<String, String> times;
  static List<String> types(int meals) => switch (meals) {
    3 => ['desayuno', 'almuerzo', 'cena'],
    4 => ['desayuno', 'almuerzo', 'media_tarde', 'cena'],
    5 => ['desayuno', 'media_manana', 'almuerzo', 'media_tarde', 'cena'],
    _ => throw const FormatException('Selecciona 3, 4 o 5 comidas.'),
  };
  Json toJson({DateTime? now}) {
    final today = DateTime.parse(formatCalendarDate(now ?? DateTime.now()));
    final date = DateTime.parse(calendarDate(start));
    if (date.isBefore(today) ||
        date.isAfter(today.add(const Duration(days: 30)))) {
      throw const FormatException(
        'La fecha debe estar entre hoy y los próximos 30 días.',
      );
    }
    if (days < 1 || days > 14) {
      throw const FormatException('La duración debe ser de 1 a 14 días.');
    }
    final names = types(meals);
    if (times.length != names.length) {
      throw const FormatException('Completa todos los horarios.');
    }
    var previous = '';
    for (final type in names) {
      final time = times[type] ?? '';
      if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time) ||
          time.compareTo(previous) <= 0) {
        throw const FormatException(
          'Los horarios deben ser distintos, cronológicos y usar HH:mm.',
        );
      }
      previous = time;
    }
    return {
      'fecha_inicio': start,
      'duracion_dias': days,
      'cantidad_comidas': meals,
      'horarios': times,
    };
  }
}
