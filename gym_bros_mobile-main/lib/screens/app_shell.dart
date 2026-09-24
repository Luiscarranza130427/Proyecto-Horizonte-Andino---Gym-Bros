import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/gym_session.dart';
import '../services/gym_api.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';
import '../widgets/edit_measurements_sheet.dart';
import '../widgets/new_measurements_sheet.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'routines_screen.dart';
import 'routine_session_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.session,
    this.hasAssignedSessionToday = false,
    this.gymApi,
  });

  final GymSessionData session;
  final bool hasAssignedSessionToday;
  final GymApi? gymApi;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey _shellKey = GlobalKey();
  late final PageController _pageController;
  late final List<ScrollController> _scrollControllers;
  late GymSessionData _session;
  late final GymApi _gymApi;
  int _index = 0;
  bool _attendancePromptShown = false;
  late int _unreadNotifications;

  BuildContext get _brandedContext => _shellKey.currentContext ?? context;
  Color get _brandBackground => Theme.of(_brandedContext).colorScheme.surface;
  Color get _brandAccent => Theme.of(_brandedContext).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _gymApi = widget.gymApi ?? GymApi();
    _session = widget.session;
    _pageController = PageController();
    _scrollControllers = List.generate(5, (_) => ScrollController());
    _unreadNotifications = _session.notifications
        .where((notification) => !notification.read)
        .length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAttendancePrompt();
    });
  }

  Future<void> _updateUser(GymUser updatedUser) async {
    final savedUser = await _gymApi.updateUserData(
      updatedUser,
      localPhotoPath: updatedUser.profilePhotoUrl,
    );
    if (!mounted) return;
    setState(() {
      _session = _session.copyWith(user: savedUser);
    });
  }

  Future<GymUser> _uploadProfilePhoto(String localPhotoPath) async {
    final savedUser = await _gymApi.uploadProfilePhoto(
      user: _session.user,
      localPhotoPath: localPhotoPath,
    );
    if (!mounted) return savedUser;
    setState(() {
      _session = _session.copyWith(user: savedUser);
    });
    return savedUser;
  }

  Future<GymProgress> _createEvaluation(Map<String, dynamic> values) async {
    final created = await _gymApi.createEvaluation(
      userId: _session.user.id,
      values: values,
    );
    if (!mounted) return created;
    setState(() {
      final progress = [..._session.progress, created]
        ..sort((a, b) => a.date.compareTo(b.date));
      _session = _session.copyWith(
        progress: progress,
        weightFatEvaluation: GymWeightFatEvaluation(
          userId: created.userId,
          evaluationId: created.id,
          date: created.date,
          weight: created.weight,
          bodyFat: created.bodyFat,
        ),
        trainingProfile: GymTrainingProfile.fromJson({
          ...values,
          'id_usuarios': created.userId,
          'id_evaluacion': created.id,
        }),
      );
    });
    return created;
  }

  // Las hojas se abren desde `_brandedContext` (dentro del Theme de la
  // empresa): con `context` heredaban el rojo por defecto en los botones.
  void _openNewEvaluation() {
    showModalBottomSheet<void>(
      context: _brandedContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => NewMeasurementsSheet(
        user: _session.user,
        profile: _session.trainingProfile,
        onSubmit: _createEvaluation,
        onSaved: () {
          Navigator.of(sheetContext).pop();
          if (mounted) {
            showAppMessage(
              _brandedContext,
              'Medidas registradas correctamente.',
            );
          }
        },
      ),
    );
  }

  void _openEditEvaluation() {
    showModalBottomSheet<void>(
      context: _brandedContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EditMeasurementsSheet(
        user: _session.user,
        load: () => _gymApi.fetchLatestEvaluation(_session.user.id),
        onSubmit: _updateLatestEvaluation,
        onSaved: () {
          Navigator.of(sheetContext).pop();
          if (mounted) {
            showAppMessage(
              _brandedContext,
              'Evaluación física actualizada correctamente.',
            );
          }
        },
      ),
    );
  }

  Future<GymProgress> _updateLatestEvaluation(
    Map<String, dynamic> values,
  ) async {
    final data = await _gymApi.updateLatestEvaluation(
      userId: _session.user.id,
      values: values,
    );
    final updated = GymProgress.fromJson(data);
    if (!mounted) return updated;
    setState(() {
      final progress = [
        ..._session.progress.where(
          (item) => !item.isEvaluation || item.id != updated.id,
        ),
        updated,
      ]..sort((a, b) => a.date.compareTo(b.date));
      _session = _session.copyWith(
        progress: progress,
        weightFatEvaluation: GymWeightFatEvaluation.fromJson({
          ...data,
          'id_evaluacion': updated.id,
        }),
        trainingProfile: GymTrainingProfile.fromJson({
          ...data,
          'id_evaluacion': updated.id,
        }),
      );
    });
    return updated;
  }

  void _openAssignedRoutine(GymRoutine routine) {
    final theme = Theme.of(_brandedContext);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: theme,
          child: RoutineSessionScreen(routine: routine, api: _gymApi),
        ),
      ),
    );
  }

  void _openRoutines() {
    _goTo(1);
  }

  Future<void> _generateRoutine() async {
    final routine = await _gymApi.generateRoutine(_session.user.id);
    if (!mounted) return;
    setState(() {
      _session = _session.copyWith(
        routines: [
          routine,
          ..._session.routines.where((item) => item.id != routine.id),
        ],
      );
    });
    _goTo(1);
    showAppMessage(_brandedContext, 'Nueva rutina generada correctamente.');
  }

  void _handleNavigation(int newIndex) {
    if (newIndex == 1) {
      _openRoutines();
      return;
    }
    _goTo(newIndex);
  }

  List<Widget> _buildPages() {
    return [
      HomeScreen(
        session: _session,
        onOpenRoutines: _openRoutines,
        onOpenAssignedRoutine: _openAssignedRoutine,
        onOpenNutrition: () => _goTo(2),
        onOpenProgress: () => _goTo(3),
        scrollController: _scrollControllers[0],
      ),
      if (_session.routines.where((routine) => routine.active).firstOrNull
          case final activeRoutine?)
        RoutineSessionScreen(
          key: ValueKey('routine-tab-${activeRoutine.id}'),
          routine: activeRoutine,
          api: _gymApi,
          embedded: true,
        )
      else
        RoutinesScreen(
          onOpenSession: _openAssignedRoutine,
          routines: _session.routines,
          sensations: _session.sensations,
          company: _session.company,
          scrollController: _scrollControllers[1],
        ),
      NutritionScreen(
        key: ValueKey('nutrition-user-${_session.user.id}'),
        userId: _session.user.id,
        api: _gymApi,
        scrollController: _scrollControllers[2],
      ),
      ProgressScreen(
        userName: _session.user.fullName,
        loadLatest: () => _gymApi.fetchLatestEvaluation(_session.user.id),
        onAddMeasurement: _openNewEvaluation,
        onEditMeasurement: _openEditEvaluation,
        onGenerateRoutine: _generateRoutine,
        loadGenerationStatus: () =>
            _gymApi.routineGenerationStatus(_session.user.id),
        revision: _session.weightFatEvaluation,
        progress: _session.progress,
        sensations: _session.sensations,
        companyColorHex: _session.company.secondaryColorHex,
        scrollController: _scrollControllers[3],
      ),
      ProfileScreen(
        session: _session,
        onUpdateUser: _updateUser,
        onUploadPhoto: _uploadProfilePhoto,
        onCreateEvaluation: _createEvaluation,
        onLoadLatestEvaluation: () =>
            _gymApi.fetchLatestEvaluation(_session.user.id),
        onUpdateLatestEvaluation: _updateLatestEvaluation,
        onOpenProgress: () => _goTo(3),
        onLogout: _confirmLogout,
        scrollController: _scrollControllers[4],
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goTo(int newIndex) {
    final targetScroll = _scrollControllers[newIndex];
    if (targetScroll.hasClients) {
      targetScroll.jumpTo(0);
    }
    if (newIndex == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = newIndex);
    _pageController.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOutCubic,
    );
  }

  String _formattedToday() {
    const weekdays = [
      'LUNES',
      'MARTES',
      'MIÉRCOLES',
      'JUEVES',
      'VIERNES',
      'SÁBADO',
      'DOMINGO',
    ];
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    final today = DateTime.now();
    return '${weekdays[today.weekday - 1]}, ${today.day} DE ${months[today.month - 1]}';
  }

  Future<void> _showAttendancePrompt() async {
    if (!mounted || _attendancePromptShown || !widget.hasAssignedSessionToday) {
      return;
    }
    _attendancePromptShown = true;
    final shouldRegister = await showDialog<bool>(
      context: _brandedContext,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _brandBackground.withValues(alpha: .98),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _brandAccent),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x77000000),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _brandBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.how_to_reg_rounded,
                        color: _brandAccent,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'REGISTRO DIARIO',
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formattedToday(),
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(
                      fontSize: 10,
                      color: _brandAccent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _brandBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: _brandAccent,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ENTRENAMIENTO ASIGNADO',
                            textAlign: TextAlign.center,
                            style: AppText.label.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '¿Ya llegaste al gimnasio?',
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Registra tu asistencia de hoy. Cuando conectemos la base de datos, este aviso solo aparecerá en tus días asignados.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  GymCard(
                    color: _brandBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: _brandAccent,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Horario asignado',
                            style: AppText.body.copyWith(fontSize: 13),
                          ),
                        ),
                        Text(
                          '6:00 PM',
                          style: AppText.label.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    key: const ValueKey('attendance-confirm'),
                    label: 'Registrar asistencia',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(dialogContext, true),
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    key: const ValueKey('attendance-later'),
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('AHORA NO'),
                  ),
                  Text(
                    'El registro de asistencia todavía no está conectado',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (shouldRegister != true || !mounted) return;
    HapticFeedback.mediumImpact();
    showAppMessage(
      _brandedContext,
      'El registro de asistencia aún no está disponible',
    );
  }

  void _openMenu() {
    const items = [
      (Icons.home_rounded, 'Inicio'),
      (Icons.fitness_center_rounded, 'Rutinas'),
      (Icons.restaurant_rounded, 'Nutrición'),
      (Icons.show_chart_rounded, 'Progreso'),
      (Icons.person_rounded, 'Perfil'),
    ];
    showGymSheet(
      _brandedContext,
      title: 'Explorar ${widget.session.company.name}',
      actionLabel: 'Cerrar menú',
      child: Column(
        children: List.generate(items.length, (itemIndex) {
          final item = items[itemIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GymCard(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              borderColor: _index == itemIndex
                  ? _brandAccent
                  : AppColors.border,
              onTap: () {
                Navigator.of(_brandedContext).pop();
                _handleNavigation(itemIndex);
              },
              child: Row(
                children: [
                  Icon(
                    item.$1,
                    color: _index == itemIndex
                        ? _brandAccent
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: AppText.label.copyWith(fontSize: 15),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _openNotifications() {
    showGymSheet(
      _brandedContext,
      title: 'Notificaciones',
      actionLabel: 'Marcar como leídas',
      child: Column(
        children: widget.session.notifications.map((notification) {
          final icon = switch (notification.type.toLowerCase()) {
            'rutina' => Icons.fitness_center_rounded,
            'alimentación' => Icons.restaurant_rounded,
            _ => Icons.info_outline_rounded,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GymCard(
              color: notification.read
                  ? _brandBackground
                  : Color.lerp(_brandBackground, _brandAccent, .18)!,
              borderColor: notification.read ? AppColors.border : _brandAccent,
              padding: const EdgeInsets.all(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: _brandAccent, size: 23),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title.toUpperCase(),
                          style: AppText.label.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        Text(notification.message, style: AppText.body),
                        const SizedBox(height: 7),
                        Text(
                          notification.sentAt,
                          style: AppText.label.copyWith(
                            color: _brandAccent,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ).then((_) {
      if (!mounted || _unreadNotifications == 0) return;
      setState(() => _unreadNotifications = 0);
      showAppMessage(_brandedContext, 'Notificaciones marcadas como leídas');
    });
  }

  Future<void> _confirmLogout() async {
    HapticFeedback.lightImpact();
    final shouldLogout = await showDialog<bool>(
      context: _brandedContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _brandBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('¿CERRAR SESIÓN?', style: AppText.title),
        content: Text('Volverás a la pantalla de acceso.', style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _brandAccent),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;
    // Revoca el token en la API y lo borra del almacenamiento seguro: antes
    // solo se navegaba al login y el token seguía válido hasta expirar.
    await _gymApi.logout();
    if (!mounted) return;
    await Navigator.of(_brandedContext).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.session.company;
    final backgroundColor = _parseCompanyColor(
      company.primaryColorHex,
      AppColors.background,
    );
    final accentColor = _parseCompanyColor(
      company.secondaryColorHex,
      AppColors.primary,
    );
    final baseTheme = Theme.of(context);
    final companyScheme = baseTheme.colorScheme.copyWith(
      primary: accentColor,
      secondary: accentColor,
      surface: backgroundColor,
      onPrimary: _contrastingText(accentColor),
      onSurface: _contrastingText(backgroundColor),
      outline: accentColor,
    );
    final companyTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      colorScheme: companyScheme,
      dialogTheme: DialogThemeData(backgroundColor: backgroundColor),
      bottomSheetTheme: baseTheme.bottomSheetTheme.copyWith(
        backgroundColor: backgroundColor,
        modalBackgroundColor: backgroundColor,
        dragHandleColor: accentColor,
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        fillColor: backgroundColor,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.4),
        ),
      ),
    );
    return Theme(
      data: companyTheme,
      child: Scaffold(
        key: _shellKey,
        extendBody: true,
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            AppHeader(
              onMenu: _openMenu,
              onLogo: () => _goTo(0),
              onAvatar: () => _goTo(4),
              onNotifications: _openNotifications,
              brandLogoUrl: company.logoUrl,
              profilePhotoUrl: _session.user.profilePhotoUrl,
              accentColor: accentColor,
              unreadNotifications: _unreadNotifications,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildPages(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: FrostedBottomNav(
          index: _index,
          onChanged: _handleNavigation,
        ),
      ),
    );
  }

  Color _parseCompanyColor(String hex, Color fallback) {
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6) return fallback;
    final value = int.tryParse('FF$normalized', radix: 16);
    return value == null ? fallback : Color(value);
  }

  Color _contrastingText(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
