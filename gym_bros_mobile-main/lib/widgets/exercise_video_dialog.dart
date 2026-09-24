import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../theme/app_theme.dart';

/// Accepts only YouTube video URLs, never arbitrary embedded HTML or websites.
String? exerciseYoutubeId(String value) {
  final text = value.trim();
  final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
  if (uri == null || !['http', 'https'].contains(uri.scheme)) return null;
  final host = uri.host.toLowerCase();
  final parts = uri.pathSegments;
  String? id;
  if (host == 'youtu.be' && parts.length == 1) {
    id = parts.first;
  } else if (const {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  }.contains(host)) {
    if (uri.path == '/watch') {
      id = uri.queryParameters['v'];
    } else if (parts.length == 2 &&
        const {'embed', 'shorts', 'live'}.contains(parts.first)) {
      id = parts.last;
    }
  }
  return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id) ? id : null;
}

Future<void> showExerciseVideo(
  BuildContext context, {
  required String name,
  required String url,
}) => showDialog<void>(
  context: context,
  builder: (_) =>
      ExerciseVideoDialog(name: name, videoId: exerciseYoutubeId(url)),
);

class ExerciseVideoDialog extends StatefulWidget {
  const ExerciseVideoDialog({
    super.key,
    required this.name,
    required this.videoId,
  });
  final String name;
  final String? videoId;

  @override
  State<ExerciseVideoDialog> createState() => _ExerciseVideoDialogState();
}

class _ExerciseVideoDialogState extends State<ExerciseVideoDialog>
    with WidgetsBindingObserver {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _subscription;
  Timer? _loadTimeout;
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.videoId != null) _createPlayer();
  }

  void _createPlayer() {
    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        interfaceLanguage: 'es',
        captionLanguage: 'es',
        playsInline: true,
      ),
    );
    _controller = controller;
    _subscription = controller.stream.listen((value) {
      if (!mounted) return;
      if (value.hasError) {
        _loadTimeout?.cancel();
        setState(() {
          _error = switch (value.error) {
            YoutubeError.videoNotFound || YoutubeError.cannotFindVideo =>
              'El video no está disponible o es privado.',
            YoutubeError.notEmbeddable ||
            YoutubeError.sameAsNotEmbeddable ||
            YoutubeError.sameAsNotEmbeddable2 =>
              'Este video no permite reproducción dentro de la aplicación.',
            _ => 'No se pudo reproducir el video. Revisa tu conexión e inténtalo de nuevo.',
          };
        });
      } else if (value.playerState != PlayerState.unknown) {
        _loadTimeout?.cancel();
        if (!_ready) setState(() => _ready = true);
      }
    });
    _loadTimeout = Timer(const Duration(seconds: 25), () {
      if (mounted && !_ready) {
        setState(
          () => _error = 'El video tardó demasiado en cargar. Revisa tu conexión a Internet.',
        );
      }
    });
    unawaited(
      controller.loadVideoById(videoId: widget.videoId!).catchError((
        Object error,
      ) {
        if (mounted) {
          setState(
            () => _error =
                'No se pudo cargar el reproductor. Inténtalo de nuevo.',
          );
        }
        debugPrint('Exercise video initialization failed: $error');
      }),
    );
  }

  void _releasePlayer() {
    _loadTimeout?.cancel();
    unawaited(_subscription?.cancel());
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(
        controller.close().catchError((Object error) {
          debugPrint('Exercise video disposal failed: $error');
        }),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _ready) {
      unawaited(_controller?.pauseVideo());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releasePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invalid = widget.videoId == null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.name, style: AppText.title)),
                    IconButton(
                      key: const ValueKey('close-exercise-video'),
                      tooltip: 'Cerrar video',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              if (invalid || _error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.videocam_off_outlined, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        invalid
                            ? 'Este ejercicio aún no tiene un enlace válido de YouTube.'
                            : _error!,
                        style: AppText.body,
                        textAlign: TextAlign.center,
                      ),
                      if (!invalid)
                        TextButton.icon(
                          onPressed: () {
                            _releasePlayer();
                            setState(() {
                              _error = null;
                              _ready = false;
                              _createPlayer();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // The official embed requires a viewport of at least 200 x 200.
                    final height = math.max(
                      200.0,
                      constraints.maxWidth * 9 / 16,
                    );
                    return Column(
                      children: [
                        if (!_ready) const LinearProgressIndicator(),
                        YoutubePlayer(
                          key: ObjectKey(_controller),
                          controller: _controller!,
                          aspectRatio: constraints.maxWidth / height,
                          autoFullScreen: false,
                          enableFullScreenOnVerticalDrag: false,
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
