import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/gym_session.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';
import '../widgets/new_measurements_sheet.dart';
import '../widgets/edit_measurements_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.session,
    required this.onLogout,
    required this.onOpenProgress,
    this.onCreateEvaluation,
    this.onLoadLatestEvaluation,
    this.onUpdateLatestEvaluation,
    this.onUpdateUser,
    this.onUploadPhoto,
    this.scrollController,
  });

  final GymSessionData session;
  final VoidCallback onLogout;
  final VoidCallback onOpenProgress;
  final Future<GymProgress> Function(Map<String, dynamic>)? onCreateEvaluation;
  final Future<Map<String, dynamic>> Function()? onLoadLatestEvaluation;
  final Future<GymProgress> Function(Map<String, dynamic>)?
  onUpdateLatestEvaluation;
  final Future<void> Function(GymUser)? onUpdateUser;
  final Future<GymUser> Function(String localPhotoPath)? onUploadPhoto;
  final ScrollController? scrollController;

  void _openChangeAvatar(BuildContext context) {
    final user = session.user;
    final accent = Theme.of(context).colorScheme.primary;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _ChangeAvatarSheet(
          user: user,
          accent: accent,
          onSave: (newPhotoUrl) async {
            final updatedUser = user.copyWith(profilePhotoUrl: newPhotoUrl);
            Navigator.of(modalContext).pop();
            try {
              final isLocalPhoto =
                  newPhotoUrl.isNotEmpty &&
                  !newPhotoUrl.startsWith('http') &&
                  !newPhotoUrl.startsWith('assets/');
              if (isLocalPhoto && onUploadPhoto != null) {
                await onUploadPhoto!(newPhotoUrl);
              } else if (newPhotoUrl != user.profilePhotoUrl &&
                  onUpdateUser != null) {
                await onUpdateUser!(updatedUser);
              }
              if (context.mounted) {
                showAppMessage(
                  context,
                  'Foto de perfil actualizada correctamente',
                );
              }
            } catch (e) {
              if (context.mounted) {
                showAppMessage(context, 'Aviso al guardar foto: $e');
              }
            }
          },
        );
      },
    );
  }

  void _openPersonalData(BuildContext context) {
    final user = session.user;
    final accent = Theme.of(context).colorScheme.primary;

    showGymSheet(
      context,
      title: 'Datos personales',
      actionLabel: 'Cerrar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header resumen de usuario
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _UserAvatar(
                  photoUrl: user.profilePhotoUrl,
                  size: 52,
                  showCameraIcon: false,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.toUpperCase(),
                        style: AppText.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.nickname.isNotEmpty
                            ? '@${user.nickname}'
                            : user.email,
                        style: AppText.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'SOCIO ACTIVO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tarjeta 1: Información Personal
          _SectionCard(
            title: 'INFORMACIÓN PERSONAL',
            icon: Icons.person_rounded,
            children: [
              _DataRow(
                label: 'Nombres y apellidos',
                value: user.fullName,
                icon: Icons.badge_outlined,
              ),
              _DataRow(
                label: 'Apodo / Nickname',
                value: user.nickname.isEmpty
                    ? 'No registrado'
                    : '@${user.nickname}',
                icon: Icons.alternate_email_rounded,
              ),
              _DataRow(
                label: 'Documento de identidad',
                value: '${user.documentType} · ${user.documentNumber}',
                icon: Icons.credit_card_rounded,
              ),
              _DataRow(
                label: 'Fecha de nacimiento',
                value: user.birthDate,
                icon: Icons.cake_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tarjeta 2: Contacto y Ubicación
          _SectionCard(
            title: 'CONTACTO Y UBICACIÓN',
            icon: Icons.contact_phone_rounded,
            children: [
              _DataRow(
                label: 'Correo electrónico',
                value: user.email,
                icon: Icons.email_outlined,
              ),
              _DataRow(
                label: 'Teléfono de contacto',
                value: user.phone,
                icon: Icons.phone_outlined,
              ),
              _DataRow(
                label: 'Dirección de residencia',
                value: user.address,
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botón de Edición
          PrimaryButton(
            key: const ValueKey('edit-personal-data'),
            label: 'Editar información',
            icon: Icons.edit_rounded,
            outlined: true,
            onPressed: () {
              Navigator.of(context).pop();
              _openEditPersonalData(context);
            },
          ),
        ],
      ),
    );
  }

  void _openEditPersonalData(BuildContext context) {
    final user = session.user;
    final accent = Theme.of(context).colorScheme.primary;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _EditPersonalDataSheet(
          user: user,
          accent: accent,
          onSave: (updatedUser) async {
            if (onUpdateUser != null) {
              await onUpdateUser!(updatedUser);
            }
          },
        );
      },
    );
  }

  void _openPhysicalEvaluation(BuildContext context) {
    final evaluation = session.progress.lastOrNull;
    final evaluationDate =
        session.weightFatEvaluation?.date ?? evaluation?.date;
    showGymSheet(
      context,
      title: 'Mi evaluación física',
      actionLabel: 'Cerrar',
      child: Column(
        children: [
          GymCard(
            onTap: () {
              Navigator.of(context).pop();
              onOpenProgress();
            },
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REGISTRO DE MEDIDAS',
                        style: AppText.label.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        evaluationDate == null
                            ? 'Todavía no tienes medidas registradas.'
                            : 'Últimas medidas registradas: $evaluationDate.',
                        style: AppText.body.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'La evaluación y el historial corporal se consultan en el módulo Progreso.',
                        style: AppText.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            key: const ValueKey('register-measurements'),
            label: 'Registrar nuevas medidas',
            icon: Icons.add_rounded,
            onPressed: onCreateEvaluation == null
                ? null
                : () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => NewMeasurementsSheet(
                        user: session.user,
                        profile: session.trainingProfile,
                        onSubmit: onCreateEvaluation!,
                        onSaved: () {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            showAppMessage(
                              context,
                              'Medidas registradas correctamente.',
                            );
                          }
                        },
                      ),
                    );
                  },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            key: const ValueKey('edit-measurements'),
            label: 'Editar últimas medidas',
            icon: Icons.edit_outlined,
            outlined: true,
            onPressed:
                onLoadLatestEvaluation == null ||
                    onUpdateLatestEvaluation == null
                ? null
                : () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => EditMeasurementsSheet(
                        user: session.user,
                        load: onLoadLatestEvaluation!,
                        onSubmit: onUpdateLatestEvaluation!,
                        onSaved: () {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            showAppMessage(
                              context,
                              'Evaluación física actualizada correctamente.',
                            );
                          }
                        },
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  void _openTrainingProfile(BuildContext context) {
    final profile = session.trainingProfile;
    String value(String text) => _formatTrainingValue(text);
    showGymSheet(
      context,
      title: 'Mi perfil de entrenamiento',
      actionLabel: 'Cerrar',
      child: Column(
        children: [
          _DataRow(
            label: 'Objetivo',
            value: value(profile?.goal ?? ''),
            icon: Icons.flag_outlined,
          ),
          _DataRow(
            label: 'Experiencia',
            value: value(profile?.experience ?? ''),
            icon: Icons.stairs_outlined,
          ),
          _DataRow(
            label: 'Actividad diaria',
            value: value(profile?.dailyActivity ?? ''),
            icon: Icons.directions_walk_rounded,
          ),
          _DataRow(
            label: 'Días disponibles',
            value: profile == null || profile.availableDays.isEmpty
                ? 'No registrado'
                : profile.availableDays.map(_formatTrainingValue).join(' · '),
            icon: Icons.calendar_month_outlined,
          ),
          _DataRow(
            label: 'Tiempo por sesión',
            value: profile == null || profile.minutesPerSession == 0
                ? 'No registrado'
                : '${profile.minutesPerSession} min',
            icon: Icons.timer_outlined,
          ),
          _DataRow(
            label: 'Restricciones',
            value: value(profile?.restrictions ?? ''),
            icon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            key: const ValueKey('edit-training-profile'),
            label: 'Editar perfil de entrenamiento',
            icon: Icons.edit_outlined,
            outlined: true,
            onPressed: () => showAppMessage(
              context,
              'El perfil de entrenamiento está esperando su endpoint.',
            ),
          ),
        ],
      ),
    );
  }

  void _openGym(BuildContext context) {
    final company = session.company;
    showGymSheet(
      context,
      title: company.name,
      actionLabel: 'Cerrar',
      child: Column(
        children: [
          SizedBox.square(
            dimension: 124,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: company.logoUrl.isEmpty
                  ? const _LogoFallback()
                  : Image.network(
                      company.logoUrl,
                      fit: BoxFit.contain,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, _, _) => const _LogoFallback(),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            company.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppText.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 22),
          if (company.manager.isNotEmpty)
            _DataRow(
              label: 'Gerente',
              value: company.manager,
              icon: Icons.admin_panel_settings_outlined,
            ),
          if (company.region.isNotEmpty)
            _DataRow(
              label: 'Región',
              value: company.region,
              icon: Icons.map_outlined,
            ),
          if (company.address.isNotEmpty)
            _DataRow(
              label: 'Dirección',
              value: company.address,
              icon: Icons.location_on_outlined,
            ),
          if (company.phone.isNotEmpty)
            _DataRow(
              label: 'Teléfono',
              value: company.phone,
              icon: Icons.phone_outlined,
            ),
          if (company.email.isNotEmpty)
            _DataRow(
              label: 'Correo',
              value: company.email,
              icon: Icons.email_outlined,
            ),
          if (company.website.isNotEmpty)
            _DataRow(
              label: 'Sitio web',
              value: company.website,
              icon: Icons.language_rounded,
            ),
          if (company.schedule.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 26),
            ...company.schedule.map(
              (line) => _DataRow(
                label: 'Horario',
                value: line,
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final membership = user.membershipStatus(DateTime.now());

    return ResponsivePage(
      controller: scrollController,
      scrollViewKey: const ValueKey('profile-scroll'),
      topPadding: 22,
      children: [
        FadeSlideIn(
          child: Column(
            children: [
              _UserAvatar(
                photoUrl: user.profilePhotoUrl,
                onCameraTap: () => _openChangeAvatar(context),
              ),
              const SizedBox(height: 20),
              Text(
                user.fullName.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: 23),
              ),
              const SizedBox(height: 7),
              Text(
                membership.title,
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                membership.message,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _ProfileTile(
          title: 'DATOS PERSONALES',
          description:
              'Consulta y edita tu información personal y de contacto.',
          icon: Icons.person_rounded,
          onTap: () => _openPersonalData(context),
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          key: const ValueKey('training-profile'),
          title: 'MI PERFIL DE ENTRENAMIENTO',
          description: 'Objetivo, experiencia, disponibilidad y restricciones.',
          icon: Icons.assignment_ind_outlined,
          onTap: () => _openTrainingProfile(context),
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          key: const ValueKey('physical-evaluation'),
          title: 'MI EVALUACIÓN FÍSICA',
          description: 'Registra o actualiza tus medidas corporales.',
          icon: Icons.health_and_safety_outlined,
          onTap: () => _openPhysicalEvaluation(context),
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          title: 'MI GIMNASIO',
          description: session.company.name,
          icon: Icons.store_rounded,
          onTap: () => _openGym(context),
        ),
        const SizedBox(height: 34),
        PrimaryButton(
          label: 'Cerrar sesión',
          outlined: true,
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ChangeAvatarSheet extends StatefulWidget {
  const _ChangeAvatarSheet({
    required this.user,
    required this.accent,
    required this.onSave,
  });

  final GymUser user;
  final Color accent;
  final ValueChanged<String> onSave;

  @override
  State<_ChangeAvatarSheet> createState() => _ChangeAvatarSheetState();
}

class _ChangeAvatarSheetState extends State<_ChangeAvatarSheet> {
  late String _selectedPhotoUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedPhotoUrl = widget.user.profilePhotoUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (image != null) {
        setState(() {
          _selectedPhotoUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'No se pudo cargar la imagen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'CAMBIAR FOTO DE PERFIL',
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona una foto desde tu galería o toma una nueva con tu cámara.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 22),

            // Preview del avatar seleccionado
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: widget.accent, width: 2.8),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: GymAvatarImage(
                  photoUrl: _selectedPhotoUrl,
                  fallbackSize: 60,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Botones de Imagen Local (Galería / Cámara)
            Text(
              'SELECCIONAR IMAGEN',
              style: AppText.label.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_rounded,
                            color: widget.accent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Galería',
                            style: AppText.label.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.camera),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: widget.accent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cámara',
                            style: AppText.label.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botón Guardar
            PrimaryButton(
              label: 'Guardar foto de perfil',
              icon: Icons.check_rounded,
              onPressed: () => widget.onSave(_selectedPhotoUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPersonalDataSheet extends StatefulWidget {
  const _EditPersonalDataSheet({
    required this.user,
    required this.accent,
    required this.onSave,
  });

  final GymUser user;
  final Color accent;
  final Future<void> Function(GymUser) onSave;

  @override
  State<_EditPersonalDataSheet> createState() => _EditPersonalDataSheetState();
}

class _EditPersonalDataSheetState extends State<_EditPersonalDataSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _docNumberController;
  late final TextEditingController _emailController;
  late String _documentType;

  /// Valor que acepta la API en `tipo_documento` → etiqueta visible. Antes se
  /// enviaba «Pasaporte» u «Otros» y la API respondía 422.
  static const _docTypes = {
    'DNI': 'DNI',
    'PASAPORTE': 'Pasaporte',
    'OTRO': 'Otro',
  };

  /// `usuarios.telefono` y `usuarios.numero_documento` son varchar(12).
  static const _maxLength = 12;

  static String _cleanPhone(String value) =>
      value.trim().replaceAll(RegExp(r'[\s-]'), '');

  static String? _validatePhone(String? value) {
    final phone = _cleanPhone(value ?? '');
    if (phone.isEmpty) return 'Ingresa tu teléfono';
    if (!RegExp(r'^\+?\d{6,}$').hasMatch(phone) || phone.length > _maxLength) {
      return 'Usa de 6 a $_maxLength dígitos';
    }
    return null;
  }

  String? _validateDocument(String? value) {
    final number = (value ?? '').trim();
    if (number.isEmpty) return 'Ingresa el número';
    if (_documentType == 'DNI') {
      return RegExp(r'^\d{8}$').hasMatch(number)
          ? null
          : 'El DNI tiene 8 dígitos';
    }
    return number.length < 5 || number.length > _maxLength
        ? 'De 5 a $_maxLength caracteres'
        : null;
  }

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstNameController = TextEditingController(text: u.firstName);
    _lastNameController = TextEditingController(text: u.lastName);
    _nicknameController = TextEditingController(text: u.nickname);
    _phoneController = TextEditingController(text: u.phone);
    _addressController = TextEditingController(text: u.address);
    _birthDateController = TextEditingController(text: u.birthDate);
    _docNumberController = TextEditingController(text: u.documentNumber);
    _emailController = TextEditingController(text: u.email);

    // Un valor fuera del catálogo haría fallar al DropdownButtonFormField.
    final storedType = u.documentType.trim().toUpperCase();
    _documentType = _docTypes.containsKey(storedType)
        ? storedType
        : (storedType.contains('PASAPORTE')
              ? 'PASAPORTE'
              : (storedType.contains('OTRO') || storedType.contains('EXTRANJ'))
              ? 'OTRO'
              : 'DNI');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _docNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    DateTime initial =
        DateTime.tryParse(_birthDateController.text.trim()) ??
        DateTime(2000, 1, 1);
    if (initial.isAfter(DateTime.now())) initial = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'SELECCIONA TU FECHA DE CUMPLEAÑOS',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.accent,
              onPrimary: Colors.white,
              surface: const Color(0xFF1F1F24),
              onSurface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xFF1B1B1E),
              headerBackgroundColor: widget.accent,
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _birthDateController.text = formatted;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    final updated = widget.user.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      phone: _cleanPhone(_phoneController.text),
      address: _addressController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      documentType: _documentType,
      documentNumber: _docNumberController.text.trim(),
      email: _emailController.text.trim(),
    );

    try {
      await widget.onSave(updated);
      if (mounted) {
        Navigator.of(context).pop();
        await showGymAlert(
          context,
          title: '¡Datos Guardados!',
          message: 'Tus datos personales fueron actualizados y guardados correctamente en la base de datos.',
          isError: false,
          buttonLabel: 'ENTENDIDO',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await showGymAlert(
          context,
          title: 'Error al Guardar',
          message: 'No se pudo guardar en la base de datos:\n\n$e',
          isError: true,
          buttonLabel: 'CERRAR',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'EDITAR DATOS PERSONALES',
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'Modifica tus datos de contacto y perfil de socio.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),

              // Sección: Datos Principales
              _buildFormSectionTitle('DATOS PERSONALES'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      controller: _firstNameController,
                      label: 'Nombres',
                      icon: Icons.person_outline_rounded,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Ingresa tus nombres'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFormField(
                      controller: _lastNameController,
                      label: 'Apellidos',
                      icon: Icons.badge_outlined,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Ingresa tus apellidos'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _nicknameController,
                label: 'Apodo / Nickname',
                icon: Icons.alternate_email_rounded,
                prefixText: '@',
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Ingresa tu apodo'
                    : null,
              ),
              const SizedBox(height: 12),

              // Selector de Fecha de Cumpleaños por Calendario
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake_outlined, color: widget.accent, size: 19),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Fecha de cumpleaños',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                color: Colors.white60,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _birthDateController.text.isEmpty
                                  ? 'Toca para seleccionar fecha en el calendario'
                                  : _birthDateController.text,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                color: _birthDateController.text.isEmpty
                                    ? Colors.white38
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: widget.accent,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sección: Documento de Identidad (Editable con selector de 3 opciones)
              _buildFormSectionTitle('DOCUMENTO DE IDENTIDAD'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: DropdownButtonFormField<String>(
                      initialValue: _documentType,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceHigh,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        labelStyle: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: widget.accent,
                            width: 1.4,
                          ),
                        ),
                      ),
                      items: _docTypes.entries.map((type) {
                        return DropdownMenuItem(
                          value: type.key,
                          child: Text(
                            type.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _documentType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: _buildFormField(
                      controller: _docNumberController,
                      label: 'Número de doc.',
                      icon: Icons.credit_card_rounded,
                      keyboardType: TextInputType.text,
                      validator: _validateDocument,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sección: Contacto (Editable)
              _buildFormSectionTitle('CONTACTO Y UBICACIÓN'),
              const SizedBox(height: 10),
              _buildFormField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!val.contains('@')) {
                    return 'Correo no válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _phoneController,
                label: 'Teléfono / WhatsApp',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _addressController,
                label: 'Dirección de residencia',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 28),

              // Botón Guardar Cambios
              PrimaryButton(
                loading: _isSaving,
                label: _isSaving ? 'Guardando en la BD...' : 'Guardar cambios',
                icon: Icons.save_rounded,
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: widget.accent,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12.5),
        prefixIcon: Icon(icon, color: Colors.white54, size: 19),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: widget.accent,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.accent, width: 1.4),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label.copyWith(fontSize: 13)),
                const SizedBox(height: 5),
                Text(description, style: AppText.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppText.label.copyWith(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'No registrado' : value,
                  style: AppText.body.copyWith(color: AppColors.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.storefront_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 46,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.photoUrl,
    this.size = 120,
    this.showCameraIcon = true,
    this.onCameraTap,
  });

  final String photoUrl;
  final double size;
  final bool showCameraIcon;
  final VoidCallback? onCameraTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.border, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: GymAvatarImage(photoUrl: photoUrl, fallbackSize: size * 0.5),
        ),
        if (showCameraIcon)
          Positioned(
            bottom: 0,
            left: 0,
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1B1B1E),
                    width: 2.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _formatTrainingValue(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return 'No registrado';
  final translated = switch (normalized) {
    '1ano' || '1_ano' || '1-año' => '1 año',
    'sin-restricciones' || 'sin_restricciones' => 'sin restricciones',
    'muy_activo' || 'muy-activo' => 'muy activo',
    'moderadamente_activo' || 'moderadamente-activo' => 'moderadamente activo',
    'poco_activo' || 'poco-activo' => 'poco activo',
    _ => normalized.replaceAll(RegExp(r'[_-]+'), ' '),
  };
  return translated[0].toUpperCase() + translated.substring(1);
}
