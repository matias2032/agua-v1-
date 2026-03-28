// lib/screens/cadastrar_usuario.dart

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

class UsuarioFormScreen extends StatefulWidget {
  const UsuarioFormScreen({super.key});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl     = TextEditingController();
  final _apelidoCtrl  = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  int  _idPerfil  = 3;
  bool _isLoading = false;
  String? _erro;

  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  final _usuarioService = UsuarioService();

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
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));

    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  Future<void> _salvarUsuario() async {
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await _usuarioService.criarUsuario(
        nome: _nomeCtrl.text.trim(),
        apelido: _apelidoCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        telefone: _telefoneCtrl.text.trim().isEmpty
            ? null
            : _telefoneCtrl.text.trim(),
        idPerfil: _idPerfil,
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _showSnack('Usuário cadastrado! Senha padrão: 12345678', _kSuccess);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _erro = 'Erro ao cadastrar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
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
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            _buildIconeBanner(),
                            const SizedBox(height: 16),
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

                            _buildSeccaoPessoal(),
                            const SizedBox(height: 12),
                            _buildDivisor('Contacto'),
                            const SizedBox(height: 12),
                            _buildSeccaoContacto(),
                            const SizedBox(height: 12),
                            _buildDivisor('Perfil'),
                            const SizedBox(height: 12),
                            _buildDropdownCargo(),
                            const SizedBox(height: 28),
                            _buildBotaoSalvar(),
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

  // ── Header ────────────────────────────────────────────────────────────────

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
              Text('Cadastrar Usuário',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: -0.4,
                  )),
              Text('Gestão de utilizadores',
                  style: TextStyle(fontSize: 12, color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ícone banner ──────────────────────────────────────────────────────────

  Widget _buildIconeBanner() {
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
            child: const Icon(Icons.person_add_rounded,
                color: _kAccent, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Novo utilizador',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    )),
                SizedBox(height: 4),
                Text(
                  'Preencha os dados para criar\numa conta de acesso ao sistema.',
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

  // ── Info banner ───────────────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kWarning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kWarning.withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _kWarning, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Senha padrão: 12345678. No primeiro login, o utilizador será obrigado a criar uma nova senha.',
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
            const Icon(Icons.warning_amber_rounded, color: _kDanger, size: 16),
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

  // ── Secção dados pessoais ─────────────────────────────────────────────────

  Widget _buildSeccaoPessoal() {
    return Column(
      children: [
        _Campo(
          label: 'Nome',
          hint: 'Primeiro nome',
          controller: _nomeCtrl,
          icone: Icons.person_outline_rounded,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'O nome é obrigatório.' : null,
        ),
        const SizedBox(height: 12),
        _Campo(
          label: 'Apelido',
          hint: 'Sobrenome',
          controller: _apelidoCtrl,
          icone: Icons.badge_outlined,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'O apelido é obrigatório.' : null,
        ),
      ],
    );
  }

  // ── Secção contacto ───────────────────────────────────────────────────────

  Widget _buildSeccaoContacto() {
    return Column(
      children: [
        _Campo(
          label: 'E-mail',
          hint: 'exemplo@dominio.com',
          controller: _emailCtrl,
          icone: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'O e-mail é obrigatório.';
            if (!v.contains('@')) return 'Digite um e-mail válido.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _Campo(
          label: 'Telefone',
          hint: 'Opcional',
          controller: _telefoneCtrl,
          icone: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // ── Divisor temático ──────────────────────────────────────────────────────

  Widget _buildDivisor(String rotulo) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kCardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kAccent.withOpacity(0.25)),
            ),
            child: Text(rotulo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kAccent,
                  letterSpacing: 0.4,
                )),
          ),
        ),
        const Expanded(child: Divider(color: _kCardBorder)),
      ],
    );
  }

  // ── Dropdown cargo ────────────────────────────────────────────────────────

  Widget _buildDropdownCargo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cargo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _idPerfil,
          dropdownColor: _kCard,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _kTextPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kTextSecondary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            filled: true,
            fillColor: _kSurface,
            prefixIcon: const Icon(Icons.work_outline_rounded,
                color: _kTextSecondary, size: 18),
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
          ),
          items: const [
            DropdownMenuItem(value: 3, child: Text('Funcionário')),
            DropdownMenuItem(value: 2, child: Text('Gerente')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _idPerfil = v);
          },
        ),
      ],
    );
  }

  // ── Botão salvar ──────────────────────────────────────────────────────────

  Widget _buildBotaoSalvar() {
    return GestureDetector(
      onTap: _isLoading ? null : _salvarUsuario,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: !_isLoading
              ? const LinearGradient(
                  colors: [_kAccent, Color(0xFF0099CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isLoading ? _kCardBorder : null,
          borderRadius: BorderRadius.circular(15),
          boxShadow: !_isLoading
              ? [BoxShadow(
                  color: _kAccent.withOpacity(0.28),
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
                    Icon(Icons.person_add_rounded, color: _kBg, size: 17),
                    SizedBox(width: 8),
                    Text('Cadastrar Usuário',
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

  // ── Botão cancelar ────────────────────────────────────────────────────────

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

class _Campo extends StatelessWidget {
  final String                     label;
  final String                     hint;
  final TextEditingController      controller;
  final IconData                   icone;
  final TextInputType              keyboardType;
  final String? Function(String?)? validator;

  const _Campo({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icone,
    this.keyboardType = TextInputType.text,
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
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
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
            errorStyle: const TextStyle(color: _kDanger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}