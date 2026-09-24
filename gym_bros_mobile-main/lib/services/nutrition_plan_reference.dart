import 'package:shared_preferences/shared_preferences.dart';

/// A plan reference belongs to both the API environment and the signed-in user.
class NutritionPlanReference {
  static String key(Uri api, int userId) =>
      'nutrition.plan.${Uri.encodeComponent(api.toString())}.user.$userId';

  Future<int?> read(Uri api, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key(api, userId));
  }

  Future<void> save(Uri api, int userId, int planId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(key(api, userId), planId)) {
      throw StateError(
        'No se pudo guardar la referencia del plan en el dispositivo.',
      );
    }
  }

  Future<void> invalidate(Uri api, int userId, int planId) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = key(api, userId);
    if (prefs.getInt(storageKey) == planId && !await prefs.remove(storageKey)) {
      throw StateError('No se pudo eliminar la referencia del plan anterior.');
    }
  }
}
