import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
const _kBg            = Color(0xFF0A0E1A);
const _kSurface       = Color(0xFF111827);
const _kCard          = Color(0xFF161D2E);
const _kCardBorder    = Color(0xFF1E2A42);
const _kAccent        = Color(0xFF00C9FF);
const _kTextPrimary   = Color(0xFFF0F4FF);
const _kTextSecondary = Color(0xFF8899BB);
const _kSuccess       = Color(0xFF00E5A0);
const _kDanger        = Color(0xFFFF4D6A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _credencialCtrl = TextEditingController();
  final _senhaCtrl      = TextEditingController();

  bool    _enviando     = false;
  bool    _mostrarSenha = false;
  String? _erro;

  final _servico = ServicoAutenticacao();

  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim  = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entradaCtrl, curve: Curves.easeOutCubic));

    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _credencialCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _enviando = true);

    final resultado = await _servico.login(
      _credencialCtrl.text.trim(),
      _senhaCtrl.text,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    switch (resultado.status) {
      case StatusAutenticacao.sucesso:
        HapticFeedback.heavyImpact();
        await SessaoService.instance.setUsuario(resultado.usuario!);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');

      case StatusAutenticacao.primeiraSenha:
        await SessaoService.instance.setUsuario(resultado.usuario!);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/primeira_troca_senha');

      case StatusAutenticacao.credenciaisInvalidas:
      case StatusAutenticacao.erroDesconhecido:
        HapticFeedback.lightImpact();
        setState(() => _erro = resultado.mensagem);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 36),
                          _buildCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _kAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _kAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.water_drop_outlined,
              color: _kAccent, size: 34),
        ),
        const SizedBox(height: 18),
        const Text('Sistema de Água',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: 6),
        const Text('Faça login para continuar',
            style: TextStyle(fontSize: 13, color: _kTextSecondary)),
      ],
    );
  }

  // ── Card de formulário ────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Erro global
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: _erro != null ? _buildErroBanner() : const SizedBox.shrink(),
          ),

          _Campo(
            label: 'Credencial',
            hint: 'Email, telefone ou apelido',
            controller: _credencialCtrl,
            icone: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obrigatório.' : null,
          ),
          const SizedBox(height: 14),

          _CampoSenha(
            label: 'Senha',
            hint: 'Digite a sua senha',
            controller: _senhaCtrl,
            obscure: !_mostrarSenha,
            onToggle: () =>
                setState(() => _mostrarSenha = !_mostrarSenha),
            onFieldSubmitted: (_) => _login(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório.' : null,
          ),
          const SizedBox(height: 26),

          _buildBotaoEntrar(),
        ],
      ),
    );
  }

  // ── Erro banner ───────────────────────────────────────────────────────────

  Widget _buildErroBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kDanger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDanger.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: _kDanger, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_erro!,
                  style: const TextStyle(
                      fontSize: 12, color: _kDanger, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Botão entrar ──────────────────────────────────────────────────────────

  Widget _buildBotaoEntrar() {
    final activo = !_enviando;
    return GestureDetector(
      onTap: activo ? _login : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: activo
              ? const LinearGradient(
                  colors: [_kAccent, Color(0xFF0099CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: activo ? null : _kCardBorder,
          borderRadius: BorderRadius.circular(15),
          boxShadow: activo
              ? [BoxShadow(
                  color: _kAccent.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )]
              : null,
        ),
        child: Center(
          child: _enviando
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: _kBg, strokeWidth: 2.5))
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login_rounded, color: _kBg, size: 17),
                    SizedBox(width: 8),
                    Text('Entrar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kBg,
                          letterSpacing: -0.2,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================

class _Campo extends StatelessWidget {
  final String                     label;
  final String                     hint;
  final TextEditingController      controller;
  final IconData                   icone;
  final TextInputType              keyboardType;
  final TextInputAction            textInputAction;
  final String? Function(String?)? validator;

  const _Campo({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icone,
    this.keyboardType   = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 13, color: _kTextSecondary),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            filled: true,
            fillColor: _kSurface,
            prefixIcon: Icon(icone, color: _kTextSecondary, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kDanger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kDanger, width: 1.5),
            ),
            errorStyle:
                const TextStyle(color: _kDanger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _CampoSenha extends StatelessWidget {
  final String                     label;
  final String                     hint;
  final TextEditingController      controller;
  final bool                       obscure;
  final VoidCallback               onToggle;
  final String? Function(String?)? validator;
  final void Function(String)?     onFieldSubmitted;

  const _CampoSenha({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 13, color: _kTextSecondary),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            filled: true,
            fillColor: _kSurface,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: _kTextSecondary, size: 18),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _kTextSecondary,
                size: 18,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kDanger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kDanger, width: 1.5),
            ),
            errorStyle:
                const TextStyle(color: _kDanger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}