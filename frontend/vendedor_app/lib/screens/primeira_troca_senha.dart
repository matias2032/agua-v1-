// lib/screens/primeira_troca_senha.dart

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
const _kWarning       = Color(0xFFFFB800);
const _kDanger        = Color(0xFFFF4D6A);

class PrimeiraTrocaSenhaScreen extends StatefulWidget {
  const PrimeiraTrocaSenhaScreen({super.key});

  @override
  State<PrimeiraTrocaSenhaScreen> createState() =>
      _PrimeiraTrocaSenhaScreenState();
}

class _PrimeiraTrocaSenhaScreenState extends State<PrimeiraTrocaSenhaScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _novaSenhaCtrl    = TextEditingController();
  final _confirmarCtrl    = TextEditingController();

  bool _obscureNova       = true;
  bool _obscureConfirmar  = true;
  bool _isLoading         = false;
  String? _erro;

  String _novaSenhaValor  = '';

  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── Requisitos ────────────────────────────────────────────────────────────

  bool get _reqComprimento  => _novaSenhaValor.length >= 8;
  bool get _reqNaoPadrao    => _novaSenhaValor != '12345678';
  bool get _reqConfirmacao  =>
      _novaSenhaValor.isNotEmpty &&
      _novaSenhaValor == _confirmarCtrl.text;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim  = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entradaCtrl, curve: Curves.easeOutCubic));

    _novaSenhaCtrl.addListener(
        () => setState(() => _novaSenhaValor = _novaSenhaCtrl.text));

    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  Future<void> _trocarSenha() async {
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final usuario = SessaoService.instance.usuarioAtual;
      if (usuario == null) throw Exception('Sessão inválida.');

      final sucesso = await ServicoAutenticacao()
          .trocarPrimeiraSenha(usuario.idUsuario, _novaSenhaCtrl.text);

      if (!sucesso) throw Exception('Falha ao actualizar a senha.');

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _showSnack('Senha alterada! Por favor, faça login novamente.', _kSuccess);
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        SessaoService.instance.limparSessao();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao trocar senha: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final usuario = SessaoService.instance.usuarioAtual;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false, // impede voltar — troca obrigatória
        child: Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 4),
                              _buildIconeBanner(usuario),
                              const SizedBox(height: 16),
                              _buildAlertaBanner(),
                              const SizedBox(height: 16),

                              // Erro global
                              AnimatedSize(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                child: _erro != null
                                    ? _buildErroBanner()
                                    : const SizedBox.shrink(),
                              ),

                              _buildCampos(),
                              const SizedBox(height: 16),
                              _buildRequisitos(),
                              const SizedBox(height: 28),
                              _buildBotaoAlterar(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _kWarning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kWarning.withOpacity(0.35)),
            ),
            child: const Icon(Icons.security_rounded,
                color: _kWarning, size: 18),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Troca Obrigatória',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: -0.4,
                  )),
              Text('Crie uma senha pessoal para continuar',
                  style: TextStyle(fontSize: 12, color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Banner de boas-vindas ─────────────────────────────────────────────────

  Widget _buildIconeBanner(dynamic usuario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _kWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kWarning.withOpacity(0.3)),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: _kWarning, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${usuario?.nome ?? 'utilizador'}!',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Por segurança, crie uma nova senha\nantes de continuar a usar o sistema.',
                  style: TextStyle(
                      fontSize: 11, color: _kTextSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Alerta obrigatoriedade ────────────────────────────────────────────────

  Widget _buildAlertaBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kWarning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kWarning.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _kWarning, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Não é possível ignorar este passo. A senha padrão deve ser substituída.',
              style: TextStyle(fontSize: 12, color: _kWarning, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Erro banner ───────────────────────────────────────────────────────────

  Widget _buildErroBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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

  // ── Campos ────────────────────────────────────────────────────────────────

  Widget _buildCampos() {
    return Column(
      children: [
        _CampoSenha(
          label: 'Nova Senha',
          hint: 'Mínimo 8 caracteres',
          controller: _novaSenhaCtrl,
          obscure: _obscureNova,
          onToggle: () => setState(() => _obscureNova = !_obscureNova),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Insira a nova senha.';
            if (v.length < 8) return 'Mínimo de 8 caracteres.';
            if (v == '12345678') return 'Não utilize a senha padrão.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _CampoSenha(
          label: 'Confirmar Nova Senha',
          hint: 'Repita a nova senha',
          controller: _confirmarCtrl,
          obscure: _obscureConfirmar,
          onToggle: () =>
              setState(() => _obscureConfirmar = !_obscureConfirmar),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirme a nova senha.';
            if (v != _novaSenhaCtrl.text) return 'As senhas não coincidem.';
            return null;
          },
        ),
      ],
    );
  }

  // ── Requisitos em tempo real ──────────────────────────────────────────────

  Widget _buildRequisitos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Requisitos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kTextSecondary,
                letterSpacing: 0.4,
              )),
          const SizedBox(height: 12),
          _Requisito(
            label: 'Mínimo de 8 caracteres',
            cumprido: _reqComprimento,
            ativo: _novaSenhaValor.isNotEmpty,
          ),
          const SizedBox(height: 8),
          _Requisito(
            label: 'Diferente da senha padrão (12345678)',
            cumprido: _reqNaoPadrao,
            ativo: _novaSenhaValor.isNotEmpty,
          ),
          const SizedBox(height: 8),
          _Requisito(
            label: 'Nova senha e confirmação coincidem',
            cumprido: _reqConfirmacao,
            ativo: _confirmarCtrl.text.isNotEmpty,
          ),
        ],
      ),
    );
  }

  // ── Botão alterar ─────────────────────────────────────────────────────────

  Widget _buildBotaoAlterar() {
    final activo = !_isLoading;
    return GestureDetector(
      onTap: activo ? _trocarSenha : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: activo
              ? const LinearGradient(
                  colors: [_kWarning, Color(0xFFCC9200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: activo ? null : _kCardBorder,
          borderRadius: BorderRadius.circular(15),
          boxShadow: activo
              ? [BoxShadow(
                  color: _kWarning.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )]
              : null,
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: _kBg, strokeWidth: 2.5))
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: _kBg, size: 17),
                    SizedBox(width: 8),
                    Text('Definir Nova Senha',
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
// WIDGETS AUXILIARES (idênticos ao padrão da tela A)
// =============================================================================

class _CampoSenha extends StatelessWidget {
  final String                     label;
  final String                     hint;
  final TextEditingController      controller;
  final bool                       obscure;
  final VoidCallback               onToggle;
  final String? Function(String?)? validator;
  final void Function(String)?     onChanged;

  const _CampoSenha({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
    this.onChanged,
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
          onChanged: onChanged,
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

class _Requisito extends StatelessWidget {
  final String label;
  final bool   cumprido;
  final bool   ativo;

  const _Requisito({
    required this.label,
    required this.cumprido,
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final IconData icone;

    if (!ativo) {
      cor   = _kTextSecondary;
      icone = Icons.radio_button_unchecked_rounded;
    } else if (cumprido) {
      cor   = _kSuccess;
      icone = Icons.check_circle_rounded;
    } else {
      cor   = _kDanger;
      icone = Icons.cancel_rounded;
    }

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(icone, color: cor, size: 15, key: ValueKey(cor)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: ativo ? cor : _kTextSecondary,
              fontWeight:
                  cumprido && ativo ? FontWeight.w600 : FontWeight.normal,
            )),
      ],
    );
  }
}