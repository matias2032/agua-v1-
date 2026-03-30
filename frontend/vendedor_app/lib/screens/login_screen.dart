// lib/screens/login_screen.dart
//
// LoginScreen — AquaStore
// Melhorias:
//   - Mensagens de erro humanizadas (sem stack técnico exposto)
//   - Banner de erro compacto com truncagem inteligente
//   - Detecção específica de SocketException / timeout / 401
//   - Botão "Ver detalhes" para quem quiser o erro técnico

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta
// ─────────────────────────────────────────────────────────────────────────────

const _kBg            = Color(0xFF0A0E1A);
const _kSurface       = Color(0xFF111827);
const _kCard          = Color(0xFF161D2E);
const _kCardBorder    = Color(0xFF1E2A42);
const _kAccent        = Color(0xFF00C9FF);
const _kAccentDeep    = Color(0xFF0099CC);
const _kTextPrimary   = Color(0xFFF0F4FF);
const _kTextSecondary = Color(0xFF8899BB);
const _kSuccess       = Color(0xFF00E5A0);
const _kDanger        = Color(0xFFFF4D6A);
const _kWarning       = Color(0xFFFFB547);

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de erro
// ─────────────────────────────────────────────────────────────────────────────

/// Converte um erro técnico numa mensagem amigável para o utilizador.
/// Guarda o erro original em [technicalDetail] para quem quiser ver.
class _ErroAmigavel {
  final String titulo;
  final String subtitulo;
  final String? technicalDetail;
  final _TipoErro tipo;

  const _ErroAmigavel({
    required this.titulo,
    required this.subtitulo,
    this.technicalDetail,
    required this.tipo,
  });
}

enum _TipoErro { credenciais, conexao, timeout, servidor, desconhecido }

_ErroAmigavel _parseErro(String raw) {
  final lower = raw.toLowerCase();

  // Sem conexão / servidor recusou
  if (lower.contains('socketexception') ||
      lower.contains('connection refused') ||
      lower.contains('computador remoto recusou') ||
      lower.contains('errno = 1225') ||
      lower.contains('errno = 111') ||
      lower.contains('network is unreachable') ||
      lower.contains('failed host lookup')) {
    return _ErroAmigavel(
      titulo: 'Servidor inacessível',
      subtitulo: 'Não foi possível ligar ao servidor. '
          'Verifique se o servidor está activo e na mesma rede.',
      technicalDetail: raw,
      tipo: _TipoErro.conexao,
    );
  }

  // Timeout
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return _ErroAmigavel(
      titulo: 'Tempo limite excedido',
      subtitulo: 'O servidor demorou demasiado a responder. '
          'Verifique a sua ligação e tente novamente.',
      technicalDetail: raw,
      tipo: _TipoErro.timeout,
    );
  }

  // Credenciais inválidas (401 / 403)
  if (lower.contains('credenciais') ||
      lower.contains('inválid') ||
      lower.contains('unauthorized') ||
      lower.contains('401') ||
      lower.contains('403')) {
    return _ErroAmigavel(
      titulo: 'Credenciais inválidas',
      subtitulo: 'Utilizador ou senha incorrectos. '
          'Verifique os seus dados e tente novamente.',
      technicalDetail: raw,
      tipo: _TipoErro.credenciais,
    );
  }

  // Erro 5xx
  if (lower.contains('500') ||
      lower.contains('502') ||
      lower.contains('503') ||
      lower.contains('internal server')) {
    return _ErroAmigavel(
      titulo: 'Erro no servidor',
      subtitulo: 'O servidor encontrou um problema interno. '
          'Tente novamente em instantes.',
      technicalDetail: raw,
      tipo: _TipoErro.servidor,
    );
  }

  // Genérico — mostra algo razoável mas não o stack completo
  return _ErroAmigavel(
    titulo: 'Erro inesperado',
    subtitulo: 'Não foi possível efectuar o login. Tente novamente.',
    technicalDetail: raw,
    tipo: _TipoErro.desconhecido,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

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

  bool           _enviando     = false;
  bool           _mostrarSenha = false;
  _ErroAmigavel? _erro;
  bool           _mostrarDetalhe = false;

  final _servico = ServicoAutenticacao();

  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _credencialCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // ── Lógica de login ────────────────────────────────────────────────────────

  Future<void> _login() async {
    setState(() { _erro = null; _mostrarDetalhe = false; });
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _enviando = true);

    try {
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
          setState(() {
            _erro = _parseErro(resultado.mensagem ?? 'Erro desconhecido');
          });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _enviando = false;
        _erro = _parseErro(e.toString());
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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

  // ── Logo ───────────────────────────────────────────────────────────────────

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
                blurRadius: 24, spreadRadius: 2,
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

  // ── Card ───────────────────────────────────────────────────────────────────

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
          // Banner de erro
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: _erro != null
                ? _buildErroBanner()
                : const SizedBox.shrink(),
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

  // ── Banner de erro humanizado ──────────────────────────────────────────────

  Widget _buildErroBanner() {
    if (_erro == null) return const SizedBox.shrink();

    // Cor e ícone segundo o tipo de erro
    final Color cor;
    final IconData icone;
    switch (_erro!.tipo) {
      case _TipoErro.conexao:
        cor = _kWarning;
        icone = Icons.wifi_off_rounded;
      case _TipoErro.timeout:
        cor = _kWarning;
        icone = Icons.timer_off_rounded;
      case _TipoErro.servidor:
        cor = _kDanger;
        icone = Icons.dns_rounded;
      case _TipoErro.credenciais:
        cor = _kDanger;
        icone = Icons.lock_outline_rounded;
      default:
        cor = _kDanger;
        icone = Icons.warning_amber_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do erro
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icone, color: cor, size: 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _erro!.titulo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _erro!.subtitulo,
                          style: TextStyle(
                            fontSize: 12,
                            color: cor.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão fechar
                  GestureDetector(
                    onTap: () => setState(() {
                      _erro = null;
                      _mostrarDetalhe = false;
                    }),
                    child: Icon(Icons.close_rounded,
                        size: 16,
                        color: cor.withOpacity(0.6)),
                  ),
                ],
              ),
            ),

            // Botão "Ver detalhes técnicos" (opcional)
            if (_erro!.technicalDetail != null) ...[
              Divider(height: 1, color: cor.withOpacity(0.15)),
              GestureDetector(
                onTap: () =>
                    setState(() => _mostrarDetalhe = !_mostrarDetalhe),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _mostrarDetalhe
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: _kTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _mostrarDetalhe
                            ? 'Ocultar detalhes'
                            : 'Ver detalhes técnicos',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_mostrarDetalhe)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kCardBorder),
                  ),
                  child: SelectableText(
                    _erro!.technicalDetail!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: _kTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Botão entrar ───────────────────────────────────────────────────────────

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
                  colors: [_kAccent, _kAccentDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: activo ? null : _kCardBorder,
          borderRadius: BorderRadius.circular(15),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ]
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
// WIDGETS AUXILIARES (inalterados, apenas paleta)
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
    this.keyboardType    = TextInputType.text,
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
              color: _kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _kTextSecondary),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            filled: true,
            fillColor: _kSurface,
            prefixIcon: Icon(icone, color: _kTextSecondary, size: 18),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kCardBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kCardBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kAccent, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kDanger)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kDanger, width: 1.5)),
            errorStyle: const TextStyle(color: _kDanger, fontSize: 11),
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
              color: _kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _kTextSecondary),
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
                borderSide: const BorderSide(color: _kCardBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kCardBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kAccent, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kDanger)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _kDanger, width: 1.5)),
            errorStyle: const TextStyle(color: _kDanger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}