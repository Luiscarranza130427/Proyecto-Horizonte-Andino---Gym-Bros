import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/services/api_environment.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  test('El listado global nunca se consulta fuera de desarrollo', () async {
    if (ApiEnvironment.development) return;
    var calls = 0;
    final api = GymApi(
      apiBaseUri: Uri.parse('https://example.test/api/'),
      mediaBaseUri: Uri.parse('https://example.test/'),
      client: MockClient((r) async {
        calls++;
        return http.Response('{"data":[]}', 200);
      }),
    );
    await expectLater(
      api.nutritionPlans(7),
      throwsA(isA<NutritionApiException>()),
    );
    expect(calls, 0);
  });
  test('La configuración rechaza HTTP fuera de desarrollo', () {
    if (!ApiEnvironment.development &&
        !ApiEnvironment.configuredUrl.startsWith('https://')) {
      expect(() => ApiEnvironment.server, throwsStateError);
    }
  });
}
