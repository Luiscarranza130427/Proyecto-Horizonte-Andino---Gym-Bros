import 'package:flutter/material.dart';

import '../models/gym_session.dart';
import '../services/gym_api.dart';
import '../theme/app_theme.dart';
import 'gym_widgets.dart';
import 'new_measurements_sheet.dart';

class EditMeasurementsSheet extends StatefulWidget {
  const EditMeasurementsSheet({
    super.key,
    required this.user,
    required this.load,
    required this.onSubmit,
    required this.onSaved,
  });

  final GymUser user;
  final Future<Map<String, dynamic>> Function() load;
  final Future<GymProgress> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onSaved;

  @override
  State<EditMeasurementsSheet> createState() => _EditMeasurementsSheetState();
}

class _EditMeasurementsSheetState extends State<EditMeasurementsSheet> {
  late Future<Map<String, dynamic>> _evaluation;

  @override
  void initState() {
    super.initState();
    _evaluation = widget.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _evaluation,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return NewMeasurementsSheet(
          user: widget.user,
          initialEvaluation: snapshot.data!,
          onSubmit: widget.onSubmit,
          onSaved: widget.onSaved,
        );
      }
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar últimas medidas', style: AppText.title),
              const SizedBox(height: 20),
              if (snapshot.hasError) ...[
                Text(
                  snapshot.error is GymApiException
                      ? snapshot.error.toString()
                      : 'No se pudo cargar la evaluación.',
                  style: AppText.body,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Reintentar',
                  onPressed: () {
                    final request = widget.load();
                    setState(() {
                      _evaluation = request;
                    });
                  },
                ),
              ] else
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    },
  );
}
