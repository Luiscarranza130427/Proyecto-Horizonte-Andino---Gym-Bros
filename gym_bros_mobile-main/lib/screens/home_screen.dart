import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/gym_company.dart';
import '../models/gym_session.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.onOpenRoutines,
    required this.onOpenAssignedRoutine,
    required this.onOpenNutrition,
    required this.onOpenProgress,
    this.scrollController,
  });

  final GymSessionData session;
  final VoidCallback onOpenRoutines;
  final ValueChanged<GymRoutine> onOpenAssignedRoutine;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenProgress;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final company = session.company;
    final accent = Theme.of(context).colorScheme.primary;
    final nickname = session.user.nickname.isEmpty
        ? 'null'
        : session.user.nickname;
    final activeRoutine = session.routines
        .where((item) => item.active)
        .firstOrNull;
    final latestProgress = session.progress.lastOrNull;
    final weight =
        session.weightFatEvaluation?.weight ?? latestProgress?.weight;
    final bodyFat =
        session.weightFatEvaluation?.bodyFat ?? latestProgress?.bodyFat;

    return ResponsivePage(
      controller: scrollController,
      scrollViewKey: const ValueKey('home-scroll'),
      topPadding: 18,
      children: [
        FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOLA, $nickname',
                style: AppText.headline.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                'Es hora de romperla. Sin excusas.',
                style: AppText.body.copyWith(fontSize: 15, color: accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 50),
          child: _TrainingCalendarCard(session: session, accent: accent),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 90),
          child: _HeroBannersCarousel(
            session: session,
            onOpenRoutines: onOpenRoutines,
            onOpenAssignedRoutine: onOpenAssignedRoutine,
            onOpenNutrition: onOpenNutrition,
            onOpenProgress: onOpenProgress,
            accent: accent,
          ),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          delay: const Duration(milliseconds: 90),
          child: SectionHeading(
            title: 'RUTINA ASIGNADA',
            trailing: TextButton(
              onPressed: activeRoutine == null
                  ? onOpenRoutines
                  : () => onOpenAssignedRoutine(activeRoutine),
              child: const Text('VER DETALLE'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 130),
          child: activeRoutine == null
              ? const _EmptyApiCard(
                  icon: Icons.fitness_center_rounded,
                  message: 'No tienes una rutina activa asignada.',
                )
              : _RoutineSummary(
                  routine: activeRoutine,
                  onTap: () => onOpenAssignedRoutine(activeRoutine),
                  accent: accent,
                ),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          delay: const Duration(milliseconds: 170),
          child: SectionHeading(
            title: 'ÚLTIMO PROGRESO',
            trailing: TextButton(
              onPressed: onOpenProgress,
              child: const Text('VER HISTORIAL'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 210),
          child: weight == null || bodyFat == null
              ? const _EmptyApiCard(
                  icon: Icons.show_chart_rounded,
                  message: 'Todavía no tienes mediciones registradas.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 350;
                    return Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'PESO',
                            value: '${weight.toStringAsFixed(1)} KG',
                            icon: Icons.monitor_weight_outlined,
                            compact: compact,
                            accent: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'GRASA CORPORAL',
                            value: '${bodyFat.toStringAsFixed(1)} %',
                            icon: Icons.percent_rounded,
                            compact: compact,
                            accent: accent,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          child: _CompanyCard(
            company: company,
            accent: accent,
            onTap: () => _showCompanyDetails(context, company, accent),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showCompanyDetails(
    BuildContext context,
    GymCompany company,
    Color accent,
  ) {
    final schedule = company.schedule.isEmpty
        ? 'No registrado'
        : company.schedule.join('\n');
    showGymSheet(
      context,
      title: 'Tu Gimnasio',
      actionLabel: 'Cerrar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              image: const DecorationImage(
                image: AssetImage('assets/images/routine_iron.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color(0xDD0B0D12),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CompanyLogo(
                    company: company,
                    accent: accent,
                    size: 70,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 78),
                  child: Text(
                    company.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(fontSize: 19),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'HORARIOS DE ATENCIÓN',
            icon: Icons.schedule_rounded,
            accent: accent,
            child: Text(
              schedule,
              style: AppText.body.copyWith(
                fontSize: 13,
                height: 1.5,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'UBICACIÓN Y CONTACTO',
            icon: Icons.location_on_outlined,
            accent: accent,
            child: Column(
              children: [
                _CompanyDetail(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  value: company.address,
                  accent: accent,
                ),
                _CompanyDetail(
                  icon: Icons.map_outlined,
                  label: 'Región',
                  value: company.region,
                  accent: accent,
                ),
                _CompanyDetail(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: company.phone,
                  accent: accent,
                ),
                _CompanyDetail(
                  icon: Icons.email_outlined,
                  label: 'Correo Electrónico',
                  value: company.email,
                  accent: accent,
                ),
                if (company.website.isNotEmpty)
                  _CompanyDetail(
                    icon: Icons.language_rounded,
                    label: 'Sitio Web',
                    value: company.website,
                    accent: accent,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'DATOS ADMINISTRATIVOS',
            icon: Icons.badge_outlined,
            accent: accent,
            child: Column(
              children: [
                _CompanyDetail(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Gerente a Cargo',
                  value: company.manager,
                  accent: accent,
                ),
                _CompanyDetail(
                  icon: Icons.receipt_long_outlined,
                  label: 'RUC',
                  value: company.ruc,
                  accent: accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppText.label.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.company,
    required this.accent,
    required this.onTap,
  });

  final GymCompany company;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = company.name.isEmpty
        ? 'GYM-BROS INDUSTRIAL'
        : company.name.toUpperCase();
    final subtitle = company.region.isNotEmpty
        ? 'Horarios · ${company.region} · contacto'
        : 'Horarios · ubicación · contacto';

    final surfaceColor = _parseHexColor(
      company.primaryColorHex,
      const Color(0xFF2563EB),
    );
    final primaryColor = _parseHexColor(
      company.secondaryColorHex,
      const Color(0xFF111827),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme
            .copyWith(surface: surfaceColor, primary: primaryColor),
      ),
      child: Material(
        key: const ValueKey('linked-company'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.9),
                width: 1.2,
              ),
              image: const DecorationImage(
                image: AssetImage('assets/images/routine_iron.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color(0xDC0B0D12),
                  BlendMode.darken,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({
    required this.company,
    required this.accent,
    required this.size,
  });

  final GymCompany company;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: company.logoUrl.isEmpty
            ? _LogoFallback(color: accent)
            : Image.network(
                company.logoUrl,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => _LogoFallback(color: accent),
              ),
      ),
    );
  }
}

class _CompanyDetail extends StatelessWidget {
  const _CompanyDetail({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppText.label.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'No registrado' : value,
                  style: AppText.body.copyWith(
                    color: AppColors.text,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseHexColor(String hex, Color fallback) {
  if (hex.isEmpty) return fallback;
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) {
    final val = int.tryParse('FF$clean', radix: 16);
    if (val != null) return Color(val);
  } else if (clean.length == 8) {
    final val = int.tryParse(clean, radix: 16);
    if (val != null) return Color(val);
  }
  return fallback;
}

class _RoutineSummary extends StatelessWidget {
  const _RoutineSummary({
    required this.routine,
    required this.onTap,
    required this.accent,
  });

  final GymRoutine routine;
  final VoidCallback onTap;
  final Color accent;

  String get _durationLabel {
    final minutes = routine.estimatedMinutes;
    if (minutes <= 0) return 'Duración no indicada';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min por sesión';
    final hourLabel = hours == 1 ? '1 hora' : '$hours horas';
    return '$hourLabel${remainder == 0 ? '' : ' $remainder min'} por sesión';
  }

  @override
  Widget build(BuildContext context) {
    return GymCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: accent.withValues(alpha: .16),
            child: Icon(Icons.fitness_center_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name.toUpperCase(),
                  style: AppText.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '${routine.daysPerWeek} días/semana · $_durationLabel',
                  style: AppText.body.copyWith(fontSize: 12),
                ),
                if (routine.goal.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    routine.goal.replaceAll('_', ' ').toUpperCase(),
                    style: AppText.label.copyWith(color: accent, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.compact,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      padding: EdgeInsets.all(compact ? 12 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 23),
          const SizedBox(height: 18),
          Text(
            label,
            style: AppText.label.copyWith(
              fontSize: compact ? 8 : 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.title.copyWith(fontSize: 21)),
          ),
        ],
      ),
    );
  }
}

class _EmptyApiCard extends StatelessWidget {
  const _EmptyApiCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppText.body)),
        ],
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Icon(Icons.storefront_rounded, color: color, size: 48),
    );
  }
}

class _TrainingCalendarCard extends StatefulWidget {
  const _TrainingCalendarCard({required this.session, required this.accent});

  final GymSessionData session;
  final Color accent;

  @override
  State<_TrainingCalendarCard> createState() => _TrainingCalendarCardState();
}

class _TrainingCalendarCardState extends State<_TrainingCalendarCard> {
  bool _isExpanded = false;
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late final Set<String> _trainingDates;

  static const _monthsSpanish = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _weekdaysSpanish = [
    'Dom',
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
  ];

  @override
  void initState() {
    super.initState();
    _trainingDates = _extractTrainingDates();
    final initialDate = _resolveInitialDate();
    _selectedDate = initialDate;
    _displayedMonth = DateTime(initialDate.year, initialDate.month, 1);
  }

  Set<String> _extractTrainingDates() {
    final dates = <String>{};
    final attendance = DateTime.tryParse(widget.session.user.weeklyAttendance);
    if (attendance != null) {
      dates.add(_dateKey(attendance));
    }
    for (final p in widget.session.progress) {
      final d = DateTime.tryParse(p.date);
      if (d != null) dates.add(_dateKey(d));
    }
    for (final s in widget.session.sensations) {
      final d = DateTime.tryParse(s.date);
      if (d != null) dates.add(_dateKey(d));
    }
    return dates;
  }

  DateTime _resolveInitialDate() {
    final attendance = DateTime.tryParse(widget.session.user.weeklyAttendance);
    if (attendance != null) return attendance;
    final lastProgress = widget.session.progress.lastOrNull;
    if (lastProgress != null) {
      final d = DateTime.tryParse(lastProgress.date);
      if (d != null) return d;
    }
    return DateTime.now();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  void _onSelectDay(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (date.month != _displayedMonth.month ||
          date.year != _displayedMonth.year) {
        _displayedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _monthsSpanish[_displayedMonth.month - 1];
    final monthYearLabel = '$monthName ${_displayedMonth.year}'.toUpperCase();

    return GymCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: widget.accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: widget.accent,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CALENDARIO DE ENTRENAMIENTO',
                          style: AppText.label.copyWith(
                            fontSize: 11.5,
                            letterSpacing: 0.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          monthYearLabel,
                          style: AppText.body.copyWith(
                            fontSize: 11,
                            color: AppColors.primarySoft,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: _buildCalendarBody(context),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBody(BuildContext context) {
    final monthName = _monthsSpanish[_displayedMonth.month - 1];
    final year = _displayedMonth.year;
    final firstDayWeekday =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;
    final daysInCurrentMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final daysInPrevMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      0,
    ).day;

    final totalCells = ((firstDayWeekday + daysInCurrentMonth + 6) ~/ 7) * 7;
    final selectedKey = _dateKey(_selectedDate);
    final hasSelectedTraining = _trainingDates.contains(selectedKey);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16191F).withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white70,
                    size: 26,
                  ),
                  onPressed: _previousMonth,
                ),
                Text(
                  '$monthName $year',
                  style: AppText.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 26,
                  ),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _weekdaysSpanish
                .map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(totalCells ~/ 7, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    late final int dayNumber;
                    late final bool isCurrentMonth;
                    late final DateTime cellDate;

                    if (cellIndex < firstDayWeekday) {
                      dayNumber =
                          daysInPrevMonth - firstDayWeekday + cellIndex + 1;
                      isCurrentMonth = false;
                      cellDate = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month - 1,
                        dayNumber,
                      );
                    } else if (cellIndex <
                        firstDayWeekday + daysInCurrentMonth) {
                      dayNumber = cellIndex - firstDayWeekday + 1;
                      isCurrentMonth = true;
                      cellDate = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month,
                        dayNumber,
                      );
                    } else {
                      dayNumber =
                          cellIndex -
                          (firstDayWeekday + daysInCurrentMonth) +
                          1;
                      isCurrentMonth = false;
                      cellDate = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month + 1,
                        dayNumber,
                      );
                    }

                    final cellKey = _dateKey(cellDate);
                    final isSelected = cellKey == selectedKey;
                    final hasTraining = _trainingDates.contains(cellKey);
                    final isToday = cellKey == _dateKey(DateTime.now());

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onSelectDay(cellDate),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        widget.accent,
                                        widget.accent.withValues(alpha: 0.85),
                                      ],
                                    )
                                  : null,
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: widget.accent.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1.4,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: widget.accent.withValues(
                                          alpha: 0.38,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : isCurrentMonth
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : isCurrentMonth
                                        ? AppColors.text
                                        : Colors.white24,
                                  ),
                                ),
                                if (hasTraining)
                                  Positioned(
                                    bottom: 3,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.white
                                            : widget.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasSelectedTraining
                  ? widget.accent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasSelectedTraining
                    ? widget.accent.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasSelectedTraining
                      ? Icons.check_circle_rounded
                      : Icons.event_note_rounded,
                  size: 15,
                  color: hasSelectedTraining
                      ? widget.accent
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 7),
                Text(
                  hasSelectedTraining
                      ? '${_selectedDate.day} de ${_monthsSpanish[_selectedDate.month - 1]}: Sesión registrada'
                      : '${_selectedDate.day} de ${_monthsSpanish[_selectedDate.month - 1]}, ${_selectedDate.year}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasSelectedTraining
                        ? Colors.white
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBannersCarousel extends StatefulWidget {
  const _HeroBannersCarousel({
    required this.session,
    required this.onOpenRoutines,
    required this.onOpenAssignedRoutine,
    required this.onOpenNutrition,
    required this.onOpenProgress,
    required this.accent,
  });

  final GymSessionData session;
  final VoidCallback onOpenRoutines;
  final ValueChanged<GymRoutine> onOpenAssignedRoutine;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenProgress;
  final Color accent;

  @override
  State<_HeroBannersCarousel> createState() => _HeroBannersCarouselState();
}

class _HeroBannersCarouselState extends State<_HeroBannersCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  static const int _totalSlides = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _totalSlides;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _resetTimer() {
    _autoScrollTimer?.cancel();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openWhatsApp() {
    final company = widget.session.company;
    final phone = company.phone.isNotEmpty ? company.phone : '+51 976123456';
    showAppMessage(
      context,
      'Contactando a ${company.name.isEmpty ? 'Gym Bros' : company.name} por WhatsApp ($phone)...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRoutine = widget.session.routines
        .where((item) => item.active)
        .firstOrNull;

    return Column(
      children: [
        SizedBox(
          height: 265,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _resetTimer();
            },
            children: [
              // Slide 0: Rutina del día
              _buildRoutineSlide(activeRoutine),
              // Slide 1: Banner 1 (Solo imagen + WhatsApp)
              _buildImageBannerSlide(bannerIndex: 0),
              // Slide 2: Banner 2 (Solo imagen + WhatsApp)
              _buildImageBannerSlide(bannerIndex: 1),
              // Slide 3: Banner 3 (Solo imagen + WhatsApp)
              _buildImageBannerSlide(bannerIndex: 2),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Indicadores tipo rectangulitos con bordes redondos
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalSlides, (index) {
            final isSelected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              width: isSelected ? 24 : 8,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.accent
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRoutineSlide(GymRoutine? routine) {
    final routineTitle = routine?.name.toUpperCase() ?? 'RUTINA DEL DÍA';
    final routineMinutes = routine?.estimatedMinutes ?? 60;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: routine == null
            ? widget.onOpenRoutines
            : () => widget.onOpenAssignedRoutine(routine),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.85),
              width: 1.2,
            ),
            image: const DecorationImage(
              image: AssetImage('assets/images/workout_day.jpg'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.25, 0.95],
                      ),
                    ),
                  ),
                ),
                // Contenido de la rutina a la izquierda
                Positioned(
                  left: 16,
                  right: 64,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        routineTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headline.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primarySoft,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$routineMinutes MIN · DURACIÓN TOTAL',
                            style: AppText.body.copyWith(
                              fontSize: 11.5,
                              color: AppColors.primarySoft,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón rojo posicionado abajo a la derecha
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageBannerSlide({required int bannerIndex}) {
    final bannerUrls = widget.session.company.bannerUrls;
    final hasUrl =
        bannerIndex < bannerUrls.length && bannerUrls[bannerIndex].isNotEmpty;
    final bannerUrl = hasUrl ? bannerUrls[bannerIndex] : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: _openWhatsApp,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E212B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Solo imagen o placeholder
                if (bannerUrl.isNotEmpty)
                  Image.network(
                    bannerUrl,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, _, _) => _buildBannerPlaceholder(),
                  )
                else
                  _buildBannerPlaceholder(),

                // Acción de WhatsApp abajo a la derecha.
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF078006),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF078006)
                              .withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/social_whatsapp.svg',
                          width: 17,
                          height: 17,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Contactar ahora',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: const Color(0xFF161922),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 60,
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension _LastOrNullExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
