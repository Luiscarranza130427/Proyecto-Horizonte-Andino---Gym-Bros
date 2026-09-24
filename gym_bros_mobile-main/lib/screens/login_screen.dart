import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/gym_session.dart';
import '../services/gym_api.dart';
import '../theme/app_theme.dart';
import '../widgets/gym_widgets.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.gymApi});

  final GymApi? gymApi;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _forgotLoading = false;
  bool _showErrors = false;
  String? _errorMessage;

  late final GymApi _gymApi;

  @override
  void initState() {
    super.initState();
    _gymApi = widget.gymApi ?? GymApi();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _showErrors = true;
        _errorMessage = 'Completa el email o DNI y la contraseña.';
      });
      HapticFeedback.mediumImpact();
      return;
    }
    await _loadUserDataAndOpen(_emailController.text);
  }

  Future<void> _forgotPassword() async {
    if (_forgotLoading) return;
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    String? errorMessage;
    String? successMessage;
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF17191D),
          title: const Text('Recuperar contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Escribe tu correo y recibirás instrucciones para cambiar tu contraseña.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                enabled: !submitting && successMessage == null,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.primarySoft),
                ),
              ],
              if (successMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  successMessage!,
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: Text(successMessage == null ? 'Cancelar' : 'Cerrar'),
            ),
            if (successMessage == null)
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final email = controller.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(() {
                            errorMessage = 'Ingresa un correo válido.';
                          });
                          return;
                        }
                        setDialogState(() {
                          submitting = true;
                          errorMessage = null;
                        });
                        setState(() => _forgotLoading = true);
                        try {
                          final message = await _gymApi.forgotPassword(email);
                          if (!mounted) return;
                          setDialogState(() {
                            submitting = false;
                            successMessage = message;
                          });
                        } on GymApiException catch (error) {
                          if (!mounted) return;
                          setDialogState(() {
                            submitting = false;
                            errorMessage = error.message;
                          });
                        } finally {
                          if (mounted) setState(() => _forgotLoading = false);
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar'),
              ),
          ],
        ),
      ),
    );
    // Espera a que termine la animación de cierre antes de liberar el campo.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
  }

  Future<void> _loadUserDataAndOpen(String email) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _showErrors = false;
      _errorMessage = null;
    });
    // Permite que el estado de carga se pinte antes de iniciar la petición.
    await Future<void>.delayed(Duration.zero);

    try {
      await _gymApi.login(
        email: email.trim(),
        password: _passwordController.text,
      );
      final session = await _gymApi.fetchUserData(email);
      if (!mounted) return;
      await _openApp(session);
    } on GymApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showErrors = true;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showErrors = true;
        _errorMessage = 'No se pudo conectar con la laptop del backend. Revisa la red Wi-Fi.';
      });
    }
  }

  Future<void> _openApp(GymSessionData session) async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, animation, _) =>
            AppShell(session: session, gymApi: _gymApi),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Imagen de fondo fija al tamaño total de la pantalla (inmune al teclado)
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: const Image(
              image: AssetImage('assets/images/fondo_login.webp'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x72000000),
                    Color(0x55000000),
                    Color(0xA6000000),
                  ],
                  stops: [0, .52, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compact = width < 360 || constraints.maxHeight < 700;
                final keyboardVisible =
                    MediaQuery.viewInsetsOf(context).bottom > 0;
                final horizontalPadding = width < 360 ? 16.0 : 22.0;
                final availableWidth = math.max(
                  0.0,
                  width - horizontalPadding * 2,
                );
                final cardWidth = math.min(430.0, availableWidth);
                final logoWidth = math.min(340.0, width * .88);
                final socialSize = math.max(
                  0.0,
                  math.min(compact ? 36.0 : 40.0, (availableWidth - 56) / 5),
                );
                final contentMinHeight = math.max(
                  0.0,
                  constraints.maxHeight - (compact ? 16.0 : 26.0),
                );

                return SingleChildScrollView(
                  physics: keyboardVisible
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 8 : 14,
                    horizontalPadding,
                    compact ? 8 : 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: contentMinHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeSlideIn(
                              child: Hero(
                                tag: 'gym-bros-logo',
                                child: SizedBox(
                                  width: logoWidth,
                                  height: compact ? 125 : 155,
                                  child: SvgPicture.asset(
                                    'assets/images/logo_gymbros.svg',
                                    fit: BoxFit.contain,
                                    semanticsLabel: 'Logo GYM-BROS',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 14 : 22),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 90),
                              child: SizedBox(
                                width: cardWidth,
                                child: _LoginGlassCard(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  obscurePassword: _obscurePassword,
                                  showErrors: _showErrors,
                                  errorMessage: _errorMessage,
                                  loading: _loading,
                                  forgotLoading: _forgotLoading,
                                  compact: compact,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onChanged: (_) {
                                    if (_showErrors) {
                                      setState(() {
                                        _showErrors = false;
                                        _errorMessage = null;
                                      });
                                    }
                                  },
                                  onLogin: _loading ? null : _login,
                                  onForgotPassword: _forgotLoading
                                      ? null
                                      : _forgotPassword,
                                ),
                              ),
                            ),
                          ],
                        ),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 170),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: _SocialSection(iconSize: socialSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: .6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            color: AppColors.primarySoft,
                            backgroundColor: Colors.white.withValues(
                              alpha: .12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Validando tus datos',
                          textAlign: TextAlign.center,
                          style: AppText.headline.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Espera un momento…',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginGlassCard extends StatelessWidget {
  const _LoginGlassCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.showErrors,
    required this.errorMessage,
    required this.loading,
    required this.forgotLoading,
    required this.compact,
    required this.onTogglePassword,
    required this.onChanged,
    required this.onLogin,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool showErrors;
  final String? errorMessage;
  final bool loading;
  final bool forgotLoading;
  final bool compact;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onChanged;
  final VoidCallback? onLogin;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x12FFFFFF), Color(0x00000000), Color(0x05000000)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: .3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x52000000),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 24,
              compact ? 22 : 28,
              compact ? 18 : 24,
              compact ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BIENVENIDO DE NUEVO, BRO',
                  textAlign: TextAlign.center,
                  style: AppText.headline.copyWith(
                    fontSize: compact ? 21 : 25,
                    letterSpacing: -.5,
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 12),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 18 : 24),
                _GlassField(
                  controller: emailController,
                  hintText: 'Correo electrónico',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  error: showErrors && emailController.text.trim().isEmpty,
                  onChanged: onChanged,
                ),
                const SizedBox(height: 14),
                _GlassField(
                  controller: passwordController,
                  hintText: 'Contraseña',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  error: showErrors && passwordController.text.isEmpty,
                  onChanged: onChanged,
                  onSubmitted: (_) => onLogin?.call(),
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: forgotLoading ? null : onForgotPassword,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: showErrors
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            errorMessage ?? 'Revisa los datos ingresados.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.primarySoft,
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                SizedBox(height: compact ? 18 : 22),
                PrimaryButton(
                  key: const ValueKey('login-button'),
                  label: 'Iniciar sesión',
                  loading: loading,
                  onPressed: onLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassField extends StatefulWidget {
  const _GlassField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
    this.error = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String> onChanged;
  final bool error;

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _focusNode.hasFocus;
    final borderColor = widget.error
        ? AppColors.primary
        : active
        ? AppColors.primarySoft
        : Colors.white.withValues(alpha: .32);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF11151B).withValues(alpha: active ? .58 : .46),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: active ? 1.4 : 1),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .24),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.primarySoft,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: .58),
            fontFamily: 'Inter',
            fontSize: 15,
          ),
          prefixIcon: Icon(widget.prefixIcon, color: Colors.white70, size: 21),
          suffixIcon: widget.suffixIcon,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }
}

class _SocialSection extends StatelessWidget {
  const _SocialSection({required this.iconSize});

  final double iconSize;

  static const _networks = [
    ('Instagram', 'assets/images/social_instagram.svg'),
    ('Facebook', 'assets/images/social_facebook.svg'),
    ('TikTok', 'assets/images/social_tiktok.svg'),
    ('WhatsApp', 'assets/images/social_whatsapp.svg'),
    ('YouTube', 'assets/images/social_youtube.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'SÍGUENOS EN NUESTRAS REDES SOCIALES',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_networks.length, (index) {
            final network = _networks[index];
            return Padding(
              padding: EdgeInsets.only(
                right: index == _networks.length - 1 ? 0 : 11,
              ),
              child: _SocialLogoButton(
                name: network.$1,
                asset: network.$2,
                size: iconSize * 0.62,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SocialLogoButton extends StatefulWidget {
  const _SocialLogoButton({
    required this.name,
    required this.asset,
    required this.size,
  });

  final String name;
  final String asset;
  final double size;

  @override
  State<_SocialLogoButton> createState() => _SocialLogoButtonState();
}

class _SocialLogoButtonState extends State<_SocialLogoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.name,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          showAppMessage(context, '${widget.name} · enlace próximamente');
        },
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.82 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isPressed ? 3.0 : 0.0, 0),
            padding: const EdgeInsets.all(4),
            child: SvgPicture.asset(
              widget.asset,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                _isPressed ? Colors.white : const Color(0xFF9E9E9E),
                BlendMode.srcIn,
              ),
              semanticsLabel: widget.name,
            ),
          ),
        ),
      ),
    );
  }
}
