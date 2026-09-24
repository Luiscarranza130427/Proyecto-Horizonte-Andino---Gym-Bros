class GymCompany {
  const GymCompany({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.manager = '',
    this.region = '',
    this.ruc = '',
    this.website = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.schedule = const [],
    this.active = false,
    this.primaryColorHex = '',
    this.secondaryColorHex = '',
    this.bannerUrls = const [],
    this.actionLinks = const [],
  });

  final int id;
  final String name;
  final String logoUrl;
  final String manager;
  final String region;
  final String ruc;
  final String website;
  final String address;
  final String phone;
  final String email;
  final List<String> schedule;
  final bool active;
  final String primaryColorHex;
  final String secondaryColorHex;
  final List<String> bannerUrls;
  final List<String> actionLinks;

  factory GymCompany.fromJson(
    Map<String, dynamic> json, {
    required Uri mediaBaseUri,
  }) {
    final id = json['id'];
    final name = json['nombre'];

    if (id is! num || name is! String || name.trim().isEmpty) {
      throw const FormatException('La empresa recibida no tiene id o nombre.');
    }

    return GymCompany(
      id: id.toInt(),
      name: name.trim(),
      logoUrl: _resolveLogoUrl(json['logo'], mediaBaseUri),
      manager: _text(json['nombre_gerente']),
      region: _text(json['region']),
      ruc: _text(json['ruc']),
      website: _text(json['enlace_web']),
      address: _text(json['direccion']),
      phone: _text(json['telefono']),
      email: _text(json['correo']),
      schedule: _scheduleFromJson(json),
      active: _boolean(json['estado']),
      primaryColorHex: _text(json['color_1']),
      secondaryColorHex: _text(json['color_2']),
      bannerUrls: _mediaList([
        json['banner_1'],
        json['banner_2'],
        json['banner_3'],
      ], mediaBaseUri),
      actionLinks: [
        _text(json['link_boton_1']),
        _text(json['link_boton_2']),
        _text(json['link_boton_3']),
      ].where((value) => value.isNotEmpty).toList(growable: false),
    );
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static bool _boolean(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return const {'1', 'true', 'activo'}.contains(_text(value).toLowerCase());
  }

  static List<String> _mediaList(List<Object?> values, Uri baseUri) {
    return values
        .map((value) => _resolveLogoUrl(value, baseUri))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _scheduleFromJson(Map<String, dynamic> json) {
    const days = <(String, String)>[
      ('lunes', 'Lunes'),
      ('martes', 'Martes'),
      ('miercoles', 'Miércoles'),
      ('jueves', 'Jueves'),
      ('viernes', 'Viernes'),
      ('sabado', 'Sábado'),
      ('domingo', 'Domingo'),
    ];

    return days
        .map((day) {
          final start = _formatTime(json['horario_inicio_${day.$1}']);
          final end = _formatTime(json['horario_fin_${day.$1}']);
          return start.isEmpty || end.isEmpty
              ? ''
              : '${day.$2} · $start – $end';
        })
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  static String _formatTime(Object? value) {
    final raw = _text(value);
    if (raw.isEmpty) return '';
    final parts = raw.split('.');
    if (parts.length == 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padRight(2, '0')}';
    }
    return raw;
  }

  static String _resolveLogoUrl(Object? value, Uri mediaBaseUri) {
    if (value is! String || value.trim().isEmpty) return '';

    var normalizedPath = value.trim().replaceAll('\\', '/');
    final parsed = Uri.tryParse(normalizedPath);
    if (parsed != null && parsed.hasScheme) return parsed.toString();

    if (normalizedPath.endsWith('.web')) {
      normalizedPath = '${normalizedPath}p';
    }

    final storageAppPublicIndex = normalizedPath.indexOf('storage/app/public/');
    if (storageAppPublicIndex != -1) {
      normalizedPath =
          'storage/${normalizedPath.substring(storageAppPublicIndex + 'storage/app/public/'.length)}';
    } else {
      final storageIndex = normalizedPath.indexOf('/storage/');
      if (storageIndex != -1) {
        normalizedPath = normalizedPath.substring(storageIndex + 1);
      } else if (!normalizedPath.startsWith('storage/')) {
        if (normalizedPath.startsWith('usuario/') ||
            normalizedPath.startsWith('usuarios/') ||
            normalizedPath.startsWith('empresas/') ||
            normalizedPath.startsWith('logos/') ||
            normalizedPath.startsWith('banners/')) {
          normalizedPath = 'storage/$normalizedPath';
        }
      }
    }

    while (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    return mediaBaseUri.resolve(normalizedPath).toString();
  }
}
