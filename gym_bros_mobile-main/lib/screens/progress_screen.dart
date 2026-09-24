import 'package:flutter/material.dart';

import '../models/gym_session.dart';
import '../models/progress_overview.dart';
import '../services/gym_api.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    required this.userName,
    required this.loadLatest,
    required this.progress,
    required this.sensations,
    this.onAddMeasurement,
    this.onEditMeasurement,
    this.onGenerateRoutine,
    this.loadGenerationStatus,
    this.companyColorHex = '',
    this.revision,
    this.scrollController,
  });
  final String userName;
  final Future<Map<String, dynamic>> Function() loadLatest;
  final List<GymProgress> progress;
  final List<GymSensation> sensations;
  final VoidCallback? onAddMeasurement;
  final VoidCallback? onEditMeasurement;
  final Future<void> Function()? onGenerateRoutine;
  final Future<Map<String, dynamic>> Function()? loadGenerationStatus;

  /// The company's `color_2`, used as a subtle visual accent for this page.
  final String companyColorHex;
  final Object? revision;
  final ScrollController? scrollController;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<Map<String, dynamic>> _latest;
  @override
  void initState() {
    super.initState();
    _latest = widget.loadLatest();
  }

  @override
  void didUpdateWidget(covariant ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) _latest = widget.loadLatest();
  }

  Future<void> _refresh() async {
    final request = widget.loadLatest();
    setState(() {
      _latest = request;
    });
    // FutureBuilder renders any loading error in the page.
    await request.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  @override
  Widget build(BuildContext context) {
    final accent = _parseCompanyColor(widget.companyColorHex, AppColors.border);
    final name = widget.userName.trim();
    final displayName = name.isEmpty
        ? ''
        : name.characters.first.toUpperCase() +
              name.characters.skip(1).toString();
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              gradient: LinearGradient(
                begin: const Alignment(-.9, -1),
                end: const Alignment(.8, 1),
                colors: [
                  AppColors.background,
                  AppColors.background,
                  const Color(0xFF0D0D0D),
                  AppColors.background,
                ],
                stops: const [0, .24, .58, 1],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -90,
                  width: 330,
                  height: 330,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: .01),
                          accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -160,
                  left: -120,
                  width: 360,
                  height: 360,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: .005),
                          accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _ProgressBackdropPainter()),
                ),
              ],
            ),
          ),
        ),
        RefreshIndicator(
          onRefresh: _refresh,
          child: ResponsivePage(
            controller: widget.scrollController,
            scrollViewKey: const ValueKey('progress-scroll'),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TU PROGRESO',
                          style: AppText.title.copyWith(
                            color: accent,
                            fontSize: 21,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayName,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onAddMeasurement,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.add_chart_rounded, size: 18),
                    label: Text(
                      'Nueva evaluación',
                      style: AppText.label.copyWith(
                        fontSize: 10,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FutureBuilder<Map<String, dynamic>>(
                future: _latest,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return GymCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            snapshot.error is GymApiException
                                ? snapshot.error.toString()
                                : 'No se pudo cargar tu evaluación.',
                            style: AppText.body,
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: 'Reintentar',
                            onPressed: _refresh,
                          ),
                        ],
                      ),
                    );
                  }
                  return _Dashboard(
                    overview: ProgressOverview(snapshot.data!),
                    accent: accent,
                    generationAction: widget.onGenerateRoutine == null
                        ? null
                        : _GenerateRoutineButton(
                            key: ValueKey(widget.revision),
                            load: widget.loadGenerationStatus!,
                            generate: widget.onGenerateRoutine!,
                          ),
                  );
                },
              ),
              // Keep the existing progress records separate from physical evaluations:
              // they have different IDs, units and persistence endpoints.
              if (widget.progress
                  .where((item) => !item.isEvaluation)
                  .isNotEmpty) ...[
                const SizedBox(height: 22),
                _ExpandableCard(
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(
                      side: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    collapsedShape: const RoundedRectangleBorder(
                      side: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    title: const Text(
                      'Registros de progreso',
                      style: AppText.label,
                    ),
                    children: widget.progress
                        .where((item) => !item.isEvaluation)
                        .toList()
                        .reversed
                        .map(
                          (item) => ListTile(
                            title: Text(item.date, style: AppText.label),
                            subtitle: Text(
                              '${item.weight} kg · ${item.bodyFat}% grasa',
                              style: AppText.body,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => showGymSheet(
                              context,
                              title: 'Medición ${item.date}',
                              actionLabel: 'Cerrar',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Peso: ${item.weight} kg',
                                    style: AppText.body,
                                  ),
                                  Text(
                                    'Grasa corporal: ${item.bodyFat} %',
                                    style: AppText.body,
                                  ),
                                  Text(
                                    'Masa muscular: ${item.muscleMass} kg',
                                    style: AppText.body,
                                  ),
                                  Text(
                                    'Cintura: ${item.waist} cm',
                                    style: AppText.body,
                                  ),
                                  if (item.notes.isNotEmpty)
                                    Text(item.notes, style: AppText.body),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (widget.sensations.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ExpandableCard(
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(
                      side: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    collapsedShape: const RoundedRectangleBorder(
                      side: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    title: const Text(
                      'Sensaciones registradas',
                      style: AppText.label,
                    ),
                    children: widget.sensations
                        .map(
                          (item) => ListTile(
                            title: Text(item.date, style: AppText.label),
                            subtitle: Text(
                              'Energía ${item.energy} · Fatiga ${item.fatigue}${item.comment.isEmpty ? '' : '\n${item.comment}'}',
                              style: AppText.body,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                key: const ValueKey('progress-edit-bottom'),
                label: 'Actualizar evaluación actual',
                icon: Icons.edit_outlined,
                outlined: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 6,
                ),
                labelFontSize: 12,
                onPressed: widget.onEditMeasurement,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .025)
      ..strokeWidth = 1;
    for (var i = -size.height; i < size.width; i += 72) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height * .42, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _parseCompanyColor(String hex, Color fallback) {
  final clean = hex.trim().replaceFirst('#', '');
  if (clean.length != 6 && clean.length != 8) return fallback;
  final value = int.tryParse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
  return value == null ? fallback : Color(value);
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.overview,
    required this.accent,
    this.generationAction,
  });
  final Widget? generationAction;
  final ProgressOverview overview;
  final Color accent;
  String amount(double value) => value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final data = overview;
    final indicators = <Widget>[
      if (data.bmi != null)
        _Metric(
          label: 'IMC',
          value: amount(data.bmi!),
          unit: 'kg/m²',
          icon: Icons.straighten_rounded,
          accent: accent,
          caption: data.bmiClassification,
        ),
      if (data.bodyFat != null)
        _Metric(
          label: 'Grasa corporal',
          value: amount(data.bodyFat!),
          unit: '%',
          icon: Icons.percent_rounded,
          accent: accent,
        ),
      if (data.muscle != null)
        _Metric(
          label: 'Masa muscular',
          value: amount(data.muscle!),
          unit: 'kg',
          icon: Icons.fitness_center_rounded,
          accent: accent,
        ),
      if (data.heightCm != null)
        _Metric(
          label: 'Altura',
          value: amount(data.heightCm!),
          unit: 'cm',
          icon: Icons.height_rounded,
          accent: accent,
        ),
    ];
    final measurements = <String, String>{
      'cintura': 'Cintura',
      'pecho': 'Pecho',
      'brazo': 'Brazo',
      'muslo': 'Muslo',
      'cadera': 'Cadera',
    };
    final available = measurements.entries
        .where((item) => data.number(item.key) != null)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.weight != null) ...[
          const Center(child: Text('PESO ACTUAL', style: AppText.label)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${amount(data.weight!)} kg',
              key: const ValueKey('current-weight'),
              style: AppText.display.copyWith(fontSize: 44),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Center(
          child: Text(
            'Última evaluación · ${data.date}',
            style: AppText.body.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        if (generationAction != null) ...[
          generationAction!,
          const SizedBox(height: 24),
        ],
        if (data.fatKg != null || data.muscle != null) ...[
          GymCard(
            radius: 12,
            color: Colors.black.withValues(alpha: .32),
            borderColor: Colors.white.withValues(alpha: .16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('COMPOSICIÓN CORPORAL', style: AppText.label),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.muscle != null)
                      _CompositionValue('Masa muscular', data.muscle!),
                    if (data.fatKg != null)
                      _CompositionValue('Grasa corporal', data.fatKg!),
                    if (data.leanKg != null)
                      _CompositionValue('Peso libre de grasa', data.leanKg!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _TwoColumns(children: indicators),
        if (available.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('MEDIDAS CORPORALES', style: AppText.label),
          const SizedBox(height: 12),
          _TwoColumns(
            children: available
                .map(
                  (entry) => _Metric(
                    label: entry.value,
                    value: amount(data.number(entry.key)!),
                    unit: 'cm',
                    icon: Icons.square_foot_rounded,
                    accent: accent,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _GenerateRoutineButton extends StatefulWidget {
  const _GenerateRoutineButton({
    super.key,
    required this.load,
    required this.generate,
  });
  final Future<Map<String, dynamic>> Function() load;
  final Future<void> Function() generate;
  @override
  State<_GenerateRoutineButton> createState() => _GenerateRoutineButtonState();
}

class _GenerateRoutineButtonState extends State<_GenerateRoutineButton> {
  Map<String, dynamic>? _status;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await widget.load();
      if (mounted) {
        setState(() {
          _status = status;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = null;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _generate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.generate();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        final error = _error;
        await _load();
        if (mounted) {
          setState(() {
            _busy = false;
            _error = error ?? _error;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PrimaryButton(
        label: 'Generar nueva rutina',
        icon: Icons.fitness_center_rounded,
        height: 50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        labelFontSize: 12,
        loading: _busy,
        onPressed: !_busy && _status?['permitido'] == true ? _generate : null,
      ),
      const SizedBox(height: 8),
      Text(
        _error ??
            (_status == null
                ? 'Consultando disponibilidad…'
                : '${_status!['generadas_mes']} generadas este mes. ${_status!['mensaje']}'),
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(fontSize: 12),
      ),
      if (_error != null && !_busy)
        TextButton(
          onPressed: _load,
          child: const Text('Consultar disponibilidad'),
        ),
    ],
  );
}

class _CompositionValue extends StatelessWidget {
  const _CompositionValue(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${value.toStringAsFixed(1)} kg', style: AppText.title),
        const SizedBox(height: 4),
        Text(label, style: AppText.body.copyWith(fontSize: 12)),
      ],
    ),
  );
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 260 ? 1 : 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: children
            .map(
              (child) => SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                child: child,
              ),
            )
            .toList(),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
    this.caption,
  });
  final String label, value, unit;
  final IconData icon;
  final Color accent;
  final String? caption;
  @override
  Widget build(BuildContext context) => GymCard(
    radius: 10,
    padding: const EdgeInsets.all(13),
    color: Colors.black.withValues(alpha: .28),
    borderColor: Colors.white.withValues(alpha: .16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 12),
        Text('$value $unit', style: AppText.title.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        Text(label, style: AppText.body.copyWith(fontSize: 12)),
        if (caption != null) ...[
          const SizedBox(height: 5),
          Text(caption!, style: AppText.body.copyWith(fontSize: 10)),
        ],
      ],
    ),
  );
}

class _ExpandableCard extends StatelessWidget {
  const _ExpandableCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => GymCard(
    padding: EdgeInsets.zero,
    color: Colors.black.withValues(alpha: .28),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: child,
    ),
  );
}
