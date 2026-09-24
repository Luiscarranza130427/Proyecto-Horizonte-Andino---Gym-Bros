import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/gym_session.dart';

void main() {
  final base = Uri.parse('http://10.0.2.2:8000/');
  String url(Object? ruta) => GymUser.resolveMediaUrl(ruta, base);

  test('las imágenes subidas desde el panel se sirven desde /storage', () {
    // Antes sólo se reconocían usuario/, empresas/, logos/ y banners/: una
    // imagen de ejercicio subida desde el panel daba 404 en la app.
    expect(
      url('ejercicios/0H2H60zMI36MyTk0yVLb0WaigZiNqdAv2ybAvVzC.webp'),
      'http://10.0.2.2:8000/storage/ejercicios/0H2H60zMI36MyTk0yVLb0WaigZiNqdAv2ybAvVzC.webp',
    );
    expect(
      url('banners-web/promo.webp'),
      'http://10.0.2.2:8000/storage/banners-web/promo.webp',
    );
  });

  test('normaliza las rutas históricas igual que la API', () {
    expect(
      url(r'\storage\app\public\ejercicios\trabajar-musculo.webp'),
      'http://10.0.2.2:8000/storage/ejercicios/trabajar-musculo.webp',
    );
    expect(
      url(r'C:\laragon\www\gym-bros\storage\app\public\usuario\x.jpg'),
      'http://10.0.2.2:8000/storage/usuario/x.jpg',
    );
    expect(
      url('/storage/logos/titan.webp'),
      'http://10.0.2.2:8000/storage/logos/titan.webp',
    );
  });

  test('respeta URLs absolutas y no expone rutas de otros discos', () {
    expect(
      url('http://192.168.1.5:8000/storage/ejercicios/a.webp'),
      'http://192.168.1.5:8000/storage/ejercicios/a.webp',
    );
    expect(url(r'D:\fotos\privada.jpg'), '');
    expect(url(''), '');
    expect(url(null), '');
  });
}
