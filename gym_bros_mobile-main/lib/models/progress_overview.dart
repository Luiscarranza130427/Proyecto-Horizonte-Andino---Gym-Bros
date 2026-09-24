/// Values from one physical evaluation. Missing measurements stay absent.
class ProgressOverview {
  ProgressOverview(this.data);
  final Map<String, dynamic> data;

  double? number(String key, {bool allowZero = false}) {
    final value = double.tryParse('${data[key]}'.replaceAll(',', '.'));
    if (value == null ||
        !value.isFinite ||
        value < 0 ||
        (!allowZero && value == 0)) {
      return null;
    }
    return value;
  }

  double? get weight => number('peso');
  double? get heightCm => number('altura');
  double? get bodyFat {
    final value = number('porcentaje_grasa', allowZero: true);
    return value != null && value <= 100 ? value : null;
  }

  double? get muscle => number('masa_muscular', allowZero: true);
  double? get bmi => weight != null && heightCm != null
      ? weight! / ((heightCm! / 100) * (heightCm! / 100))
      : null;
  // CDC adult categories apply from age 20; classify before display rounding.
  // https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html
  String? get bmiClassification {
    final value = bmi;
    if (value == null || !value.isFinite) return null;
    final age = number('edad');
    if (age == null) return 'Falta registrar la edad';
    if (age < 20) return 'Requiere valoración por edad';
    if (value < 18.5) return 'Bajo peso';
    if (value < 25) return 'Peso saludable';
    if (value < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  double? get fatKg =>
      weight != null && bodyFat != null ? weight! * bodyFat! / 100 : null;
  double? get leanKg => fatKg != null ? weight! - fatKg! : null;
  String get date => '${data['fecha_evaluacion'] ?? ''}'.split('T').first;
}
