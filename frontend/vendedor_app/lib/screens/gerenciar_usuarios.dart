// lib/screens/gerenciar_usuarios.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../widgets/app_sidebar.dart';

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

// ─── Enums ────────────────────────────────────────────────────────────────────
enum StatusFiltro { todos, ativo, inativo }
enum PerfilFiltro { todos, gerente, funcionario }

// =============================================================================
// SCREEN
// =============================================================================

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen>
    with SingleTickerProviderStateMixin {
  final UsuarioService _service = UsuarioService();

  late Future<List<UsuarioModel>> _usuariosFuture;
  StatusFiltro _statusFiltro = StatusFiltro.todos;
  PerfilFiltro _perfilFiltro = PerfilFiltro.todos;
  int _refreshCounter = 0;

  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ---------------------------------------------------------------------------
  // CICLO DE VIDA
  // ---------------------------------------------------------------------------

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

    _usuariosFuture = _loadUsuarios();
    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CARREGAMENTO
  // ---------------------------------------------------------------------------

  Future<List<UsuarioModel>> _loadUsuarios({
    StatusFiltro? status,
    PerfilFiltro? perfil,
  }) async {
    final filtroStatus = status ?? _statusFiltro;
    final filtroPerfil = perfil ?? _perfilFiltro;

    final bool? apenasAtivos = switch (filtroStatus) {
      StatusFiltro.ativo   => true,
      StatusFiltro.inativo => null,
      StatusFiltro.todos   => null,
    };

    final int? idPerfil = switch (filtroPerfil) {
      PerfilFiltro.gerente     => 3,
      PerfilFiltro.funcionario => 4,
      PerfilFiltro.todos       => null,
    };

    final lista = await _service.listarUsuarios(perfil: idPerfil, ativo: apenasAtivos);

    if (filtroStatus == StatusFiltro.inativo) {
      return lista.where((u) => !u.ativo).toList();
    }
    return lista;
  }

  void _recarregar() {
    setState(() {
      _refreshCounter++;
      _usuariosFuture = _loadUsuarios();
    });
    _entradaCtrl.forward(from: 0);
  }

  // ---------------------------------------------------------------------------
  // ACÇÕES
  // ---------------------------------------------------------------------------

  Future<void> _toggleStatus(UsuarioModel usuario) async {
    HapticFeedback.mediumImpact();
    try {
      await _service.toggleStatus(usuario.idUsuario);
      if (!mounted) return;
      _showSnack(
        usuario.ativo
            ? '${usuario.nome} inactivado com sucesso.'
            : '${usuario.nome} activado com sucesso.',
        usuario.ativo ? _kWarning : _kSuccess,
      );
      _recarregar();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro: $e', _kDanger);
    }
  }

  Future<void> _resetarSenha(UsuarioModel usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: _kBg.withOpacity(0.88),
      builder: (ctx) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _kWarning.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: _kWarning, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Resetar Senha',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  )),
              const SizedBox(height: 10),
              Text(
                'A senha de ${usuario.nome} será redefinida para 12345678.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: _kTextSecondary, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'Cancelar',
                      cor: _kTextSecondary,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogButton(
                      label: 'Resetar',
                      cor: _kWarning,
                      filled: true,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _service.resetarSenha(usuario.idUsuario);
      if (!mounted) return;
      _showSnack('Senha resetada! Nova senha: 12345678', _kSuccess);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro: $e', _kDanger);
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

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _getPerfilNome(UsuarioModel u) => switch (u.idPerfil) {
        1 => 'Administrador',
        2 => 'Gerente',
        3 => 'Funcionário',
        4 => 'Vendedor',
        _ => 'Sem perfil',
      };

  String _formatarData(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  String _getFiltroLabel() {
    final status = switch (_statusFiltro) {
      StatusFiltro.ativo   => 'Activos',
      StatusFiltro.inativo => 'Inactivos',
      StatusFiltro.todos   => 'Todos',
    };
    final perfil = switch (_perfilFiltro) {
      PerfilFiltro.gerente     => ' · Gerentes',
      PerfilFiltro.funcionario => ' · Vendedores',
      PerfilFiltro.todos       => '',
    };
    return '$status$perfil';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        drawer: const AppSidebar(),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildFiltrosActivos(),
                  Expanded(
                    child: FutureBuilder<List<UsuarioModel>>(
                      key: ValueKey(_refreshCounter),
                      future: _usuariosFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoading();
                        }
                        if (snapshot.hasError) {
                          return _buildErro(snapshot.error);
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildVazio();
                        }
                        return _buildLista(snapshot.data!);
                      },
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

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Icon(Icons.menu_rounded,
                    color: _kTextPrimary, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Utilizadores',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.4,
                    )),
                Text(_getFiltroLabel(),
                    style: const TextStyle(
                        fontSize: 12, color: _kTextSecondary)),
              ],
            ),
          ),
          // Filtro status
          _HeaderIconButton(
            icon: Icons.filter_list_rounded,
            cor: _kAccent,
            tooltip: 'Filtrar status',
            onTap: () => _mostrarMenuStatus(context),
          ),
          const SizedBox(width: 8),
          // Filtro perfil
          _HeaderIconButton(
            icon: Icons.group_rounded,
            cor: _kAccent,
            tooltip: 'Filtrar perfil',
            onTap: () => _mostrarMenuPerfil(context),
          ),
          const SizedBox(width: 8),
          // Refresh
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            cor: _kTextSecondary,
            tooltip: 'Recarregar',
            onTap: _recarregar,
          ),
          const SizedBox(width: 8),
          // Novo utilizador
          _HeaderIconButton(
            icon: Icons.person_add_rounded,
            cor: _kSuccess,
            tooltip: 'Novo utilizador',
            onTap: () async {
              await Navigator.of(context).pushNamed('/cadastrar_usuarios');
              _recarregar();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PILLS DE FILTROS ACTIVOS
  // ---------------------------------------------------------------------------

  Widget _buildFiltrosActivos() {
    final temFiltroStatus = _statusFiltro != StatusFiltro.todos;
    final temFiltroPerfil = _perfilFiltro != PerfilFiltro.todos;
    if (!temFiltroStatus && !temFiltroPerfil) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Wrap(
        spacing: 8,
        children: [
          if (temFiltroStatus)
            _FiltroPill(
              label: switch (_statusFiltro) {
                StatusFiltro.ativo   => 'Activos',
                StatusFiltro.inativo => 'Inactivos',
                StatusFiltro.todos   => '',
              },
              cor: _statusFiltro == StatusFiltro.ativo ? _kSuccess : _kDanger,
              onRemove: () {
                final f = _loadUsuarios(status: StatusFiltro.todos);
                setState(() {
                  _statusFiltro = StatusFiltro.todos;
                  _refreshCounter++;
                  _usuariosFuture = f;
                });
              },
            ),
          if (temFiltroPerfil)
            _FiltroPill(
              label: switch (_perfilFiltro) {
                PerfilFiltro.gerente     => 'Gerentes',
                PerfilFiltro.funcionario => 'Vendedores',
                PerfilFiltro.todos       => '',
              },
              cor: _kWarning,
              onRemove: () {
                final f = _loadUsuarios(perfil: PerfilFiltro.todos);
                setState(() {
                  _perfilFiltro = PerfilFiltro.todos;
                  _refreshCounter++;
                  _usuariosFuture = f;
                });
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENUS POPUP (substituem PopupMenuButton do AppBar)
  // ---------------------------------------------------------------------------

  void _mostrarMenuStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FiltroSheet(
        titulo: 'Filtrar por Status',
        opcoes: const [
          ('Todos os Status',   StatusFiltro.todos),
          ('Apenas Activos',    StatusFiltro.ativo),
          ('Apenas Inactivos',  StatusFiltro.inativo),
        ],
        seleccionado: _statusFiltro,
        icones: const [
          Icons.people_rounded,
          Icons.person_rounded,
          Icons.person_off_rounded,
        ],
        cores: const [_kTextSecondary, _kSuccess, _kDanger],
        onSelect: (v) {
          final f = _loadUsuarios(status: v as StatusFiltro);
          setState(() {
            _statusFiltro = v;
            _refreshCounter++;
            _usuariosFuture = f;
          });
        },
      ),
    );
  }

  void _mostrarMenuPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FiltroSheet(
        titulo: 'Filtrar por Perfil',
        opcoes: const [
          ('Todos os Perfis',   PerfilFiltro.todos),
          ('Apenas Gerentes',   PerfilFiltro.gerente),
          ('Apenas Vendedores', PerfilFiltro.funcionario),
        ],
        seleccionado: _perfilFiltro,
        icones: const [
          Icons.people_rounded,
          Icons.manage_accounts_rounded,
          Icons.point_of_sale_rounded,
        ],
        cores: const [_kTextSecondary, _kAccent, _kWarning],
        onSelect: (v) {
          final f = _loadUsuarios(perfil: v as PerfilFiltro);
          setState(() {
            _perfilFiltro = v;
            _refreshCounter++;
            _usuariosFuture = f;
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ESTADOS DA LISTA
  // ---------------------------------------------------------------------------

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
          Text('A carregar utilizadores…',
              style: TextStyle(fontSize: 13, color: _kTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildErro(Object? erro) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: _kDanger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: _kDanger, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Erro ao carregar utilizadores',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary)),
            const SizedBox(height: 8),
            Text('$erro',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: _kTextSecondary, height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _recarregar,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _kDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kDanger.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: _kDanger, size: 16),
                    SizedBox(width: 8),
                    Text('Tentar novamente',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kDanger)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: _kTextSecondary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: _kTextSecondary, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Nenhum utilizador encontrado',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 4),
          Text(_getFiltroLabel(),
              style: const TextStyle(
                  fontSize: 12, color: _kTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildLista(List<UsuarioModel> usuarios) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final u = usuarios[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _UsuarioCard(
            usuario: u,
            perfilNome: _getPerfilNome(u),
            dataFormatada: _formatarData(u.dataCadastro),
            onDetalhes: () => Navigator.pushNamed(
              context,
              '/detalhes_usuario',
              arguments: u.idUsuario,
            ).then((_) => _recarregar()),
            onToggle: () => _toggleStatus(u),
            onReset: () => _resetarSenha(u),
          ),
        );
      },
    );
  }
}

// =============================================================================
// CARD DE UTILIZADOR
// =============================================================================

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;
  final String       perfilNome;
  final String       dataFormatada;
  final VoidCallback onDetalhes;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  const _UsuarioCard({
    required this.usuario,
    required this.perfilNome,
    required this.dataFormatada,
    required this.onDetalhes,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isAtivo  = usuario.ativo;
    final corStatus = isAtivo ? _kSuccess : _kDanger;
    final inicial  = usuario.nome[0].toUpperCase();

    return GestureDetector(
      onTap: onDetalhes,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCardBorder),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: corStatus.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(inicial,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: corStatus,
                    )),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${usuario.nome} ${usuario.apelido ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: corStatus.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isAtivo ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: corStatus,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(perfilNome,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kAccent,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(usuario.email,
                            style: const TextStyle(
                                fontSize: 11, color: _kTextSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('Cadastro: $dataFormatada',
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSecondary)),
                ],
              ),
            ),

            // Menu acções
            _CardMenu(
              isAtivo: isAtivo,
              onDetalhes: onDetalhes,
              onToggle: onToggle,
              onReset: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MENU DE ACÇÕES DO CARD
// =============================================================================

class _CardMenu extends StatelessWidget {
  final bool         isAtivo;
  final VoidCallback onDetalhes;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  const _CardMenu({
    required this.isAtivo,
    required this.onDetalhes,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: _kTextSecondary, size: 20),
      color: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _kCardBorder),
      ),
      onSelected: (v) => switch (v) {
        'detalhes' => onDetalhes(),
        'toggle'   => onToggle(),
        'reset'    => onReset(),
        _          => null,
      },
      itemBuilder: (_) => [
        _menuItem('detalhes', Icons.info_outline_rounded,
            'Ver Detalhes', _kAccent),
        _menuItem(
          'toggle',
          isAtivo ? Icons.person_off_rounded : Icons.person_rounded,
          isAtivo ? 'Desactivar' : 'Activar',
          isAtivo ? _kDanger : _kSuccess,
        ),
        _menuItem('reset', Icons.lock_reset_rounded,
            'Resetar Senha', _kWarning),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color cor) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: cor, size: 16),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cor)),
        ],
      ),
    );
  }
}

// =============================================================================
// SHEET DE FILTROS (Bottom Sheet)
// =============================================================================

class _FiltroSheet extends StatelessWidget {
  final String        titulo;
  final List<(String, Object)> opcoes;
  final Object        seleccionado;
  final List<IconData> icones;
  final List<Color>   cores;
  final void Function(Object) onSelect;

  const _FiltroSheet({
    required this.titulo,
    required this.opcoes,
    required this.seleccionado,
    required this.icones,
    required this.cores,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _kCardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(titulo,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              )),
          const SizedBox(height: 14),
          ...List.generate(opcoes.length, (i) {
            final (label, valor) = opcoes[i];
            final isSel = valor == seleccionado;
            final cor   = cores[i];
            return GestureDetector(
              onTap: () {
                onSelect(valor);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: isSel ? cor.withOpacity(0.1) : _kCard,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSel ? cor.withOpacity(0.55) : _kCardBorder,
                    width: isSel ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icones[i], color: isSel ? cor : _kTextSecondary,
                        size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSel ? cor : _kTextSecondary,
                          )),
                    ),
                    if (isSel)
                      Icon(Icons.check_circle_rounded, color: cor, size: 16),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================

class _HeaderIconButton extends StatelessWidget {
  final IconData     icon;
  final Color        cor;
  final String       tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.cor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withOpacity(0.3)),
          ),
          child: Icon(icon, color: cor, size: 18),
        ),
      ),
    );
  }
}

class _FiltroPill extends StatelessWidget {
  final String       label;
  final Color        cor;
  final VoidCallback onRemove;

  const _FiltroPill({
    required this.label,
    required this.cor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cor)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: cor),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String       label;
  final Color        cor;
  final bool         filled;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.cor,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? cor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: filled ? cor.withOpacity(0.5) : _kCardBorder),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? cor : _kTextSecondary,
              )),
        ),
      ),
    );
  }
}

