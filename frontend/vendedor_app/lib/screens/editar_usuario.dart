// lib/screens/editar_usuario_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class EditarUsuarioScreen extends StatefulWidget {
  const EditarUsuarioScreen({super.key});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl    = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  UsuarioModel? _usuario;
  bool _isLoading  = true;
  bool _isModoEdicao = false;
  bool _isSaving   = false;

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
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));

    _carregar();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ───────────────────────────────────────────────────────────────────

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    try {
      final sessao = SessaoService.instance.usuarioAtual;
      if (sessao == null) throw Exception('Sessão inválida.');

      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/${sessao.idUsuario}'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final usuario = UsuarioModel.fromJson(jsonDecode(response.body));
        setState(() {
          _usuario        = usuario;
          _emailCtrl.text    = usuario.email;
          _telefoneCtrl.text = usuario.telefone ?? '';
          _isLoading      = false;
        });
        _entradaCtrl.forward();
      } else {
        throw Exception('Erro ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erro ao carregar dados: $e', _kDanger);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.usuariosUrl}/${_usuario!.idUsuario}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'nome':     _usuario!.nome,
          'apelido':  _usuario!.apelido,
          'email':    _emailCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim().isNotEmpty
              ? _telefoneCtrl.text.trim()
              : null,
          'idPerfil': _usuario!.idPerfil,
        }),
      );

      if (response.statusCode == 200) {
        _showSnack('Dados actualizados! Será desligado em instantes.', _kSuccess);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          SessaoService.instance.limparSessao();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      } else {
        String erro = 'Erro ao actualizar dados.';
        try {
          final j = jsonDecode(response.body);
          erro = j['message'] ?? j['error'] ?? erro;
        } catch (_) {}
        throw Exception(erro);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('$e', _kDanger);
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelarEdicao() {
    HapticFeedback.selectionClick();
    setState(() {
      _isModoEdicao      = false;
      _emailCtrl.text    = _usuario!.email;
      _telefoneCtrl.text = _usuario!.telefone ?? '';
    });
  }

  void _showSnack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _getPerfilNome(int? id) => switch (id) {
        1 => 'Administrador',
        2 => 'Gerente',
        3 => 'Funcionário',
        4 => 'Vendedor',
        _ => 'Utilizador',
      };

  String _formatarData(DateTime? data) {
    if (data == null) return '—';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

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
          child: _isLoading
              ? _buildLoading()
              : FadeTransition(
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
                                  _buildAvatar(),
                                  const SizedBox(height: 24),
                                  _buildSeccaoBasica(),
                                  const SizedBox(height: 16),
                                  _buildSeccaoContacto(),
                                  const SizedBox(height: 16),
                                  _buildSeccaoConta(),
                                  const SizedBox(height: 28),
                                  _buildBotoes(),
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
            onTap: () => Navigator.pop(context),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Os Meus Dados',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: -0.4,
                  )),
              Text(
                _isModoEdicao ? 'Modo de edição activo' : 'Visualização',
                style: TextStyle(
                  fontSize: 12,
                  color: _isModoEdicao ? _kWarning : _kTextSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!_isModoEdicao)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isModoEdicao = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kAccent.withOpacity(0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: _kAccent, size: 14),
                    SizedBox(width: 6),
                    Text('Editar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kAccent,
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(
                color: _kAccent, strokeWidth: 2.5),
          ),
          SizedBox(height: 14),
          Text('A carregar dados…',
              style: TextStyle(fontSize: 13, color: _kTextSecondary)),
        ],
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final inicial = (_usuario?.nome.isNotEmpty == true)
        ? _usuario!.nome[0].toUpperCase()
        : 'U';
    final isAtivo = _usuario?.ativo == true;

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
          // Avatar
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kAccent.withOpacity(0.3), width: 1.5),
            ),
            child: Center(
              child: Text(inicial,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _kAccent,
                  )),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_usuario?.nome ?? ''} ${_usuario?.apelido ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Pill(
                      label: _getPerfilNome(_usuario?.idPerfil),
                      cor: _kAccent,
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      label: isAtivo ? 'ACTIVO' : 'INACTIVO',
                      cor: isAtivo ? _kSuccess : _kDanger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Secções ───────────────────────────────────────────────────────────────────

  Widget _buildSeccaoBasica() {
    return _InfoCard(
      titulo: 'Informações Básicas',
      icone: Icons.person_rounded,
      children: [
        _CampoReadOnly(
          label: 'Nome',
          valor: _usuario?.nome ?? '—',
          icone: Icons.badge_rounded,
        ),
        const SizedBox(height: 12),
        _CampoReadOnly(
          label: 'Apelido',
          valor: _usuario?.apelido?.isNotEmpty == true
              ? _usuario!.apelido!
              : '—',
          icone: Icons.person_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildSeccaoContacto() {
    return _InfoCard(
      titulo: 'Informações de Contacto',
      icone: Icons.contact_phone_rounded,
      badge: _isModoEdicao ? 'EDITÁVEL' : null,
      badgeCor: _kWarning,
      children: [
        _CampoEditavel(
          label: 'Email',
          controller: _emailCtrl,
          icone: Icons.email_rounded,
          enabled: _isModoEdicao,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email obrigatório.';
            if (!v.contains('@')) return 'Email inválido.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _CampoEditavel(
          label: 'Telefone',
          controller: _telefoneCtrl,
          icone: Icons.phone_rounded,
          enabled: _isModoEdicao,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSeccaoConta() {
    final isAtivo = _usuario?.ativo == true;
    return _InfoCard(
      titulo: 'Informações da Conta',
      icone: Icons.info_outline_rounded,
      children: [
        _CampoReadOnly(
          label: 'Data de Cadastro',
          valor: _formatarData(_usuario?.dataCadastro),
          icone: Icons.calendar_today_rounded,
        ),
        const SizedBox(height: 12),
        _CampoReadOnly(
          label: 'Estado',
          valor: isAtivo ? 'Activo' : 'Inactivo',
          icone: Icons.circle,
          corValor: isAtivo ? _kSuccess : _kDanger,
        ),
      ],
    );
  }

  // ── Botões ────────────────────────────────────────────────────────────────────

  Widget _buildBotoes() {
    if (_isModoEdicao) {
      return Row(
        children: [
          // Cancelar
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _cancelarEdicao,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Center(
                  child: Text('Cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextSecondary,
                      )),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Guardar
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isSaving ? null : _salvar,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 50,
                decoration: BoxDecoration(
                  gradient: _isSaving
                      ? null
                      : const LinearGradient(
                          colors: [_kAccent, Color(0xFF0099CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _isSaving ? _kCardBorder : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isSaving
                      ? null
                      : [
                          BoxShadow(
                            color: _kAccent.withOpacity(0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: _kAccent, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save_rounded,
                                color: _kBg, size: 17),
                            SizedBox(width: 8),
                            Text('Guardar Alterações',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kBg,
                                )),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Modo visualização — botão único
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _isModoEdicao = true);
        },
        child: Container(
          decoration: BoxDecoration(
            color: _kAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kAccent.withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_rounded, color: _kAccent, size: 17),
              SizedBox(width: 8),
              Text('Editar os Meus Dados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kAccent,
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

// ─── Card de secção ───────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String        titulo;
  final IconData      icone;
  final String?       badge;
  final Color?        badgeCor;
  final List<Widget>  children;

  const _InfoCard({
    required this.titulo,
    required this.icone,
    required this.children,
    this.badge,
    this.badgeCor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icone, color: _kAccent, size: 16),
              ),
              const SizedBox(width: 10),
              Text(titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  )),
              if (badge != null) ...[
                const SizedBox(width: 8),
                _Pill(label: badge!, cor: badgeCor ?? _kAccent),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _kCardBorder, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ─── Campo read-only ──────────────────────────────────────────────────────────

class _CampoReadOnly extends StatelessWidget {
  final String   label;
  final String   valor;
  final IconData icone;
  final Color?   corValor;

  const _CampoReadOnly({
    required this.label,
    required this.valor,
    required this.icone,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 13, color: _kTextSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                    letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kCardBorder),
          ),
          child: Text(valor,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: corValor ?? _kTextPrimary,
              )),
        ),
      ],
    );
  }
}

// ─── Campo editável ───────────────────────────────────────────────────────────

class _CampoEditavel extends StatelessWidget {
  final String                   label;
  final TextEditingController    controller;
  final IconData                 icone;
  final bool                     enabled;
  final TextInputType?           keyboardType;
  final String? Function(String?)? validator;

  const _CampoEditavel({
    required this.label,
    required this.controller,
    required this.icone,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 13, color: _kTextSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                    letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled: true,
            fillColor: enabled
                ? _kAccent.withOpacity(0.05)
                : _kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: enabled
                      ? _kAccent.withOpacity(0.45)
                      : _kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDanger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDanger, width: 1.5),
            ),
            errorStyle: const TextStyle(color: _kDanger, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ─── Pill ─────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color  cor;

  const _Pill({required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: cor,
            letterSpacing: 0.5,
          )),
    );
  }
}

