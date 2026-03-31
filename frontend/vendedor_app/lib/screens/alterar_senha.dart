// lib/screens/alterar_senha.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _senhaAtualCtrl    = TextEditingController();
  final _novaSenhaCtrl     = TextEditingController();
  final _confirmacaoCtrl   = TextEditingController();

  bool _obscureSenhaAtual  = true;
  bool _obscureNovaSenha   = true;
  bool _obscureConfirmacao = true;
  bool _isLoading          = false;
  String? _erro;

  // força rebuild dos requisitos ao digitar
  String _novaSenhaValor   = '';

  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── Ciclo de vida ────────────────────────────────────────────────────────────

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
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmacaoCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ───────────────────────────────────────────────────────────────────

  Future<void> _alterarSenha() async {
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    if (_novaSenhaCtrl.text != _confirmacaoCtrl.text) {
      setState(() => _erro = 'A nova senha e a confirmação não coincidem.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final usuario = SessaoService.instance.usuarioAtual;
      if (usuario == null) throw Exception('Sessão inválida.');

      final response = await http.patch(
        Uri.parse('${ApiConfig.authUrl}/${usuario.idUsuario}/alterar-senha'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'senhaAtual': _senhaAtualCtrl.text,
          'novaSenha':  _novaSenhaCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSnack('Senha alterada! Será desligado em instantes.', _kSuccess);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          SessaoService.instance.limparSessao();
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
        }
      } else {
        String erro = 'Erro ao alterar senha.';
        try {
          final j = jsonDecode(response.body);
          erro = j['message'] ?? j['error'] ?? erro;
        } catch (_) {}
        setState(() => _erro = erro);
      }
    } catch (e) {
      setState(() => _erro = 'Erro: $e');
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

  // ── Requisitos em tempo real ──────────────────────────────────────────────────

  bool get _reqComprimento  => _novaSenhaValor.length >= 6;
  bool get _reqConfirmacao  =>
      _novaSenhaValor.isNotEmpty &&
      _novaSenhaValor == _confirmacaoCtrl.text;

  // ── Build ─────────────────────────────────────────────────────────────────────

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
                            _buildIconeSeguranca(),
                            const SizedBox(height: 20),
                            _buildInfoBanner(),
                            const SizedBox(height: 16),

                            // Erro global
                            AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              child: _erro != null
                                  ? _buildErroBanner()
                                  : const SizedBox.shrink(),
                            ),

                            _buildSeccaoSenhaAtual(),
                            const SizedBox(height: 12),
                            _buildDivisor(),
                            const SizedBox(height: 12),
                            _buildSeccaoNovaSenha(),
                            const SizedBox(height: 16),
                            _buildRequisitos(),
                            const SizedBox(height: 28),
                            _buildBotaoAlterar(),
                            const SizedBox(height: 12),
                            _buildBotaoCancelar(),
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
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kCardBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kTextPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alterar Senha',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: -0.4,
                  )),
              Text('Segurança da conta',
                  style: TextStyle(fontSize: 12, color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ícone central ─────────────────────────────────────────────────────────────

  Widget _buildIconeSeguranca() {
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
              color: _kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kAccent.withOpacity(0.3)),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: _kAccent, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Altere a sua senha',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    )),
                SizedBox(height: 4),
                Text(
                  'Recomendamos alterar a senha\nregularmente para maior segurança.',
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

  // ── Banner de info ────────────────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _kAccent, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Não poderá usar senhas anteriormente utilizadas.',
              style: TextStyle(
                  fontSize: 12, color: _kAccent, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner de erro ────────────────────────────────────────────────────────────

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

  // ── Secção senha actual ───────────────────────────────────────────────────────

  Widget _buildSeccaoSenhaAtual() {
    return _CampoSenha(
      label: 'Senha Actual',
      hint: 'Digite a sua senha actual',
      controller: _senhaAtualCtrl,
      obscure: _obscureSenhaAtual,
      onToggle: () =>
          setState(() => _obscureSenhaAtual = !_obscureSenhaAtual),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Insira a senha actual.' : null,
    );
  }

  // ── Divisor ───────────────────────────────────────────────────────────────────

  Widget _buildDivisor() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kCardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kWarning.withOpacity(0.3)),
            ),
            child: const Text('Nova Senha',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kWarning,
                  letterSpacing: 0.4,
                )),
          ),
        ),
        const Expanded(child: Divider(color: _kCardBorder)),
      ],
    );
  }

  // ── Secção nova senha ─────────────────────────────────────────────────────────

  Widget _buildSeccaoNovaSenha() {
    return Column(
      children: [
        _CampoSenha(
          label: 'Nova Senha',
          hint: 'Mínimo 6 caracteres',
          controller: _novaSenhaCtrl,
          obscure: _obscureNovaSenha,
          onToggle: () =>
              setState(() => _obscureNovaSenha = !_obscureNovaSenha),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Insira a nova senha.';
            if (v.length < 6) return 'Mínimo de 6 caracteres.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _CampoSenha(
          label: 'Confirmar Nova Senha',
          hint: 'Repita a nova senha',
          controller: _confirmacaoCtrl,
          obscure: _obscureConfirmacao,
          onToggle: () =>
              setState(() => _obscureConfirmacao = !_obscureConfirmacao),
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Confirme a nova senha.' : null,
        ),
      ],
    );
  }

  // ── Requisitos em tempo real ──────────────────────────────────────────────────

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
            label: 'Mínimo de 6 caracteres',
            cumprido: _reqComprimento,
            ativo: _novaSenhaValor.isNotEmpty,
          ),
          const SizedBox(height: 8),
          _Requisito(
            label: 'Diferente de senhas anteriores',
            cumprido: false,
            ativo: false,
            indeterminado: true,
          ),
          const SizedBox(height: 8),
          _Requisito(
            label: 'Nova senha e confirmação coincidem',
            cumprido: _reqConfirmacao,
            ativo: _confirmacaoCtrl.text.isNotEmpty,
          ),
        ],
      ),
    );
  }

  // ── Botão alterar ─────────────────────────────────────────────────────────────

  Widget _buildBotaoAlterar() {
    final activo = !_isLoading;
    return GestureDetector(
      onTap: activo ? _alterarSenha : null,
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
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: _kBg, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: _kBg, size: 17),
                    SizedBox(width: 8),
                    Text('Alterar Senha',
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

  // ── Botão cancelar ────────────────────────────────────────────────────────────

  Widget _buildBotaoCancelar() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Cancelar',
            style: TextStyle(color: _kTextSecondary, fontSize: 14)),
      ),
    );
  }
}

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================

// ─── Campo de senha ───────────────────────────────────────────────────────────

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
            hintStyle: const TextStyle(
                fontSize: 13, color: _kTextSecondary),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
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
              borderSide:
                  const BorderSide(color: _kAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _kDanger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide:
                  const BorderSide(color: _kDanger, width: 1.5),
            ),
            errorStyle:
                const TextStyle(color: _kDanger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ─── Requisito visual ─────────────────────────────────────────────────────────

class _Requisito extends StatelessWidget {
  final String label;
  final bool   cumprido;
  final bool   ativo;
  final bool   indeterminado;

  const _Requisito({
    required this.label,
    required this.cumprido,
    required this.ativo,
    this.indeterminado = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final IconData icone;

    if (indeterminado || !ativo) {
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
              color: ativo && !indeterminado ? cor : _kTextSecondary,
              fontWeight:
                  cumprido && ativo ? FontWeight.w600 : FontWeight.normal,
            )),
      ],
    );
  }
}

