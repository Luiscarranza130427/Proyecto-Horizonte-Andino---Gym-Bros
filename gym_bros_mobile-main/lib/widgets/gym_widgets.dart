import 'dart:io' as io;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class GymAvatarImage extends StatelessWidget {
  const GymAvatarImage({
    super.key,
    required this.photoUrl,
    this.fallbackSize = 27,
    this.fallbackIcon = Icons.person_outline_rounded,
    this.fallbackColor = AppColors.textMuted,
    this.backgroundColor,
  });

  final String photoUrl;
  final double fallbackSize;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;

    Widget fallback() => ColoredBox(
      color: bgColor,
      child: Icon(fallbackIcon, color: fallbackColor, size: fallbackSize),
    );

    final cleanUrl = photoUrl.trim();
    if (cleanUrl.isEmpty) {
      return fallback();
    }

    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }

    if (!kIsWeb &&
        !cleanUrl.startsWith('http://') &&
        !cleanUrl.startsWith('https://')) {
      final file = io.File(cleanUrl);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }

    return Image.network(
      cleanUrl,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback(),
    );
  }
}

const _pageMaxWidth = 620.0;

double responsivePadding(double width) {
  if (width < 360) return 16;
  if (width < 430) return 20;
  return 24;
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.children,
    this.topPadding = 28,
    this.bottomPadding = 124,
    this.controller,
    this.scrollViewKey,
  });

  final List<Widget> children;
  final double topPadding;
  final double bottomPadding;
  final ScrollController? controller;
  final Key? scrollViewKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = responsivePadding(constraints.maxWidth);
        return SingleChildScrollView(
          key: scrollViewKey,
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            padding,
            topPadding,
            padding,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.onMenu,
    required this.onLogo,
    required this.onAvatar,
    required this.onNotifications,
    required this.brandLogoUrl,
    this.profilePhotoUrl = '',
    this.accentColor = AppColors.primary,
    this.unreadNotifications = 0,
  });

  final VoidCallback onMenu;
  final VoidCallback onLogo;
  final VoidCallback onAvatar;
  final VoidCallback onNotifications;
  final String brandLogoUrl;
  final String profilePhotoUrl;
  final Color accentColor;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.primary)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Menú',
                  onPressed: onMenu,
                  icon: Icon(Icons.menu_rounded, color: scheme.primary),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onLogo,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: SizedBox(
                        width: 140,
                        height: 65,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: brandLogoUrl.isEmpty
                              ? Icon(
                                  Icons.storefront_rounded,
                                  color: accentColor,
                                  size: 32,
                                )
                              : Image.network(
                                  brandLogoUrl,
                                  fit: BoxFit.contain,
                                  webHtmlElementStrategy:
                                      WebHtmlElementStrategy.prefer,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.storefront_rounded,
                                    color: accentColor,
                                    size: 32,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      key: const ValueKey('notifications-button'),
                      tooltip: 'Notificaciones',
                      onPressed: onNotifications,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadNotifications',
                            style: AppText.label.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Abrir perfil',
                  child: GestureDetector(
                    onTap: onAvatar,
                    child: Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipOval(
                        child: GymAvatarImage(
                          photoUrl: profilePhotoUrl,
                          fallbackSize: 27,
                        ),
                      ),
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
}

class GymCard extends StatelessWidget {
  const GymCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = AppColors.border,
    this.color,
    this.radius = 16,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
    );
    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.loading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.contentPadding,
    this.labelFontSize = 14,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool loading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? contentPadding;
  final double labelFontSize;
  final double height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fgColor =
        widget.foregroundColor ?? (widget.outlined ? accent : Colors.white);
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: widget.outlined
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: .18),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: SizedBox(
            height: widget.height,
            child: widget.outlined
                ? OutlinedButton(
                    onPressed: widget.onPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fgColor,
                      side: BorderSide(color: accent, width: 1.6),
                      shape: const StadiumBorder(),
                      padding: widget.contentPadding,
                    ),
                    child: _content,
                  )
                : FilledButton(
                    onPressed: widget.onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: fgColor,
                      shape: const StadiumBorder(),
                      padding: widget.contentPadding,
                    ),
                    child: _content,
                  ),
          ),
        ),
      ),
    );
  }

  Widget get _content {
    if (widget.loading) {
      return const SizedBox(
        width: 21,
        height: 21,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon case final icon?) ...[
          Icon(icon, size: 22),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppText.label.copyWith(
              fontSize: widget.labelFontSize,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title.toUpperCase(), style: AppText.title)),
        ?trailing,
      ],
    );
  }
}

class RedProgressBar extends StatelessWidget {
  const RedProgressBar({super.key, required this.value, this.color});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) => LinearProgressIndicator(
          value: animatedValue,
          minHeight: 8,
          backgroundColor: Theme.of(context).colorScheme.surface,
          valueColor: AlwaysStoppedAnimation(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, .045),
      end: Offset.zero,
    ).animate(curve);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class FrostedBottomNav extends StatelessWidget {
  const FrostedBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.fitness_center_rounded, 'Rutinas'),
    (Icons.restaurant_rounded, 'Nutrición'),
    (Icons.show_chart_rounded, 'Progreso'),
    (Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: .94),
            border: Border(top: BorderSide(color: scheme.primary)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              height: 72,
              child: Row(
                children: List.generate(_items.length, (itemIndex) {
                  final active = itemIndex == index;
                  final item = _items[itemIndex];
                  return Expanded(
                    child: Semantics(
                      selected: active,
                      button: true,
                      label: item.$2,
                      child: InkWell(
                        onTap: () => onChanged(itemIndex),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 230),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? scheme.primary.withValues(alpha: .2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  scale: active ? 1.08 : 1,
                                  duration: const Duration(milliseconds: 230),
                                  child: Icon(
                                    item.$1,
                                    size: 23,
                                    color: active
                                        ? scheme.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.$2.toUpperCase(),
                                    maxLines: 1,
                                    style: AppText.label.copyWith(
                                      fontSize: 9.5,
                                      letterSpacing: .2,
                                      color: active
                                          ? scheme.primary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showGymSheet(
  BuildContext context, {
  required String title,
  required Widget child,
  String actionLabel = 'Listo',
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(22, 8, 22, bottom + 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title.toUpperCase(), style: AppText.title),
              const SizedBox(height: 18),
              child,
              const SizedBox(height: 22),
              PrimaryButton(
                label: actionLabel,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showAppMessage(BuildContext context, String message) {
  HapticFeedback.selectionClick();
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppText.body.copyWith(color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
}

Future<void> showGymAlert(
  BuildContext context, {
  required String title,
  required String message,
  bool isError = false,
  String buttonLabel = 'ENTENDIDO',
  VoidCallback? onConfirm,
}) {
  HapticFeedback.mediumImpact();
  final accent = isError
      ? const Color(0xFFEF4444)
      : Theme.of(context).colorScheme.primary;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: 16, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(
                  fontSize: 13,
                  color: isError ? Colors.white70 : AppColors.text,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: buttonLabel,
                icon: isError ? Icons.close_rounded : Icons.check_rounded,
                backgroundColor: accent,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onConfirm?.call();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
