import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
const _kBg            = Color(0xFF0A0E1A);
const _kSurface       = Color(0xFF0D1321);
const _kCard          = Color(0xFF161D2E);
const _kCardBorder    = Color(0xFF1E2A42);
const _kAccent        = Color(0xFF00C9FF);
const _kAccent2       = Color(0xFF0066FF);
const _kTextPrimary   = Color(0xFFF0F4FF);
const _kTextSecondary = Color(0xFF8899BB);
const _kSuccess       = Color(0xFF00E5A0);
const _kDanger        = Color(0xFFFF4D6A);

// ─── Modelo de item de navegação ─────────────────────────────────────────────

class _NavItem {
  final IconData icone;
  final String label;
  final String rota;
  final Color? corActiva;

  const _NavItem({
    required this.icone,
    required this.label,
    required this.rota,
    this.corActiva,
  });
}

const _kNavItems = [
  _NavItem(
    icone: Icons.dashboard_rounded,
    label: 'Dashboard',
    rota: '/dashboard',
    corActiva: _kAccent,
  ),
  _NavItem(
    icone: Icons.storefront_rounded,
    label: 'Menu',
    rota: '/menu',
    corActiva: _kAccent,
  ),
  _NavItem(
    icone: Icons.water_drop_rounded,
    label: 'Estoque',
    rota: '/estoque',
    corActiva: _kAccent,
  ),

    _NavItem(
    icone: Icons.water_drop_rounded,
    label: 'Historico de pedidos',
    rota: '/historico_pedidos',
    corActiva: _kAccent,
  ),
  _NavItem(
    icone: Icons.inventory_2_rounded,
    label: 'Produtos',
    rota: '/gerenciar_produtos',
    corActiva: _kSuccess,
  ),
  _NavItem(
    icone: Icons.people_rounded,
    label: 'Utilizadores',
    rota: '/gerenciar_usuarios',
    corActiva: _kSuccess,
  ),
];

// ─── AppSidebar — widget reutilizável ────────────────────────────────────────
///
/// USO em qualquer tela:
///
/// ```dart
/// Scaffold(
///   drawer: const AppSidebar(),
///   body: ...,
/// )
/// ```
///
/// Para abrir via botão no header:
/// ```dart
/// IconButton(
///   icon: const Icon(Icons.menu_rounded),
///   onPressed: () => Scaffold.of(context).openDrawer(),
/// )
/// ```
///
/// Ou com GlobalKey:
/// ```dart
/// final _scaffoldKey = GlobalKey<ScaffoldState>();
/// Scaffold(key: _scaffoldKey, drawer: const AppSidebar(), ...)
/// _scaffoldKey.currentState?.openDrawer();
/// ```

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _perfilExpandido = false;
  late final AnimationController _perfilCtrl;
  late final Animation<double> _perfilAnim;

  @override
  void initState() {
    super.initState();
    _perfilCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _perfilAnim = CurvedAnimation(
        parent: _perfilCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _perfilCtrl.dispose();
    super.dispose();
  }

  void _togglePerfil() {
    HapticFeedback.selectionClick();
    setState(() => _perfilExpandido = !_perfilExpandido);
    _perfilExpandido
        ? _perfilCtrl.forward()
        : _perfilCtrl.reverse();
  }

  String get _rotaActual =>
      ModalRoute.of(context)?.settings.name ?? '';

  void _navegar(String rota) {
    Navigator.pop(context); // fecha drawer
    if (_rotaActual == rota) return;
    Navigator.pushReplacementNamed(context, rota);
  }

Future<void> _logout() async {
    Navigator.pop(context);
    // Correção: alterado de limpar() para limparSessao()
    SessaoService.instance.limparSessao(); 
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Obtém dados do utilizador da sessão
    final sessao  = SessaoService.instance;
    final nome    = sessao.nomeUsuario ?? 'Utilizador';
final apelido = sessao.usuarioAtual?.apelido ?? ''; 
    final email   = sessao.usuarioAtual?.email ?? '';
    final iniciais = _iniciais(nome, apelido);

    return Drawer(
      width: 280,
      backgroundColor: _kSurface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Logo / Branding ─────────────────────────────────────────
            _buildBranding(),

            // ── Navegação ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                children: [
                  _buildSeccaoLabel('Principal'),
                  _NavTile(
                    item: _kNavItems[0],
                    activo: _rotaActual == _kNavItems[0].rota,
                    onTap: () => _navegar(_kNavItems[0].rota),
                  ),
                  _NavTile(
                    item: _kNavItems[1],
                    activo: _rotaActual == _kNavItems[1].rota,
                    onTap: () => _navegar(_kNavItems[1].rota),
                  ),
                  const SizedBox(height: 8),
                  _buildSeccaoLabel('Gestão'),
                  _NavTile(
                    item: _kNavItems[2],
                    activo: _rotaActual == _kNavItems[2].rota,
                    onTap: () => _navegar(_kNavItems[2].rota),
                  ),
                  _NavTile(
                    item: _kNavItems[3],
                    activo: _rotaActual == _kNavItems[3].rota,
                    onTap: () => _navegar(_kNavItems[3].rota),
                  ),
                  _NavTile(
                    item: _kNavItems[4],
                    activo: _rotaActual == _kNavItems[4].rota,
                    onTap: () => _navegar(_kNavItems[4].rota),
                  ),
                ],
              ),
            ),

            // ── Linha separadora ─────────────────────────────────────────
            const Divider(height: 1, color: _kCardBorder),

            // ── Perfil do utilizador (fundo) ─────────────────────────────
            _buildPerfilSection(
                iniciais: iniciais,
                nome: nome,
                apelido: apelido,
                email: email),
          ],
        ),
      ),
    );
  }

  // ── Branding ──────────────────────────────────────────────────────────────

  Widget _buildBranding() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kAccent, _kAccent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('AquaStore',
              style: TextStyle(
                fontFamily: 'Georgia', fontSize: 18,
                fontWeight: FontWeight.w700, color: _kTextPrimary,
                letterSpacing: -0.4,
              )),
        ],
      ),
    );
  }

  // ── Label de secção ───────────────────────────────────────────────────────

  Widget _buildSeccaoLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Text(texto.toUpperCase(),
          style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: _kTextSecondary, letterSpacing: 1.2,
          )),
    );
  }

  // ── Secção de perfil (fundo, estilo Claude.ai) ────────────────────────────

  Widget _buildPerfilSection({
    required String iniciais,
    required String nome,
    required String apelido,
    required String email,
  }) {
    final nomeCompleto = apelido.isNotEmpty ? '$nome $apelido' : nome;

    return Column(
      children: [
        // Menu de acções (expande para cima)
        SizeTransition(
          sizeFactor: _perfilAnim,
          axisAlignment: 1.0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kCardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                _AcaoPerfil(
                  icone: Icons.edit_rounded,
                  label: 'Editar dados',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/editar_usuario');
                  },
                ),
                const Divider(height: 1, color: _kCardBorder),
                _AcaoPerfil(
                  icone: Icons.lock_outline_rounded,
                  label: 'Alterar senha',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/alterar_senha');
                  },
                ),
                const Divider(height: 1, color: _kCardBorder),
                _AcaoPerfil(
                  icone: Icons.logout_rounded,
                  label: 'Terminar sessão',
                  cor: _kDanger,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),

        // Botão do perfil
        GestureDetector(
          onTap: _togglePerfil,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _perfilExpandido
                  ? _kAccent.withOpacity(0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _perfilExpandido
                    ? _kAccent.withOpacity(0.25)
                    : _kCardBorder,
              ),
            ),
            child: Row(
              children: [
                // Avatar com iniciais
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kAccent, _kAccent2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(iniciais,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.5,
                        )),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomeCompleto,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          )),
                      Text(email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: _kTextSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _perfilExpandido ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_up_rounded,
                      color: _kTextSecondary, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _iniciais(String nome, String apelido) {
    final n = nome.isNotEmpty ? nome[0].toUpperCase() : '';
    final a = apelido.isNotEmpty ? apelido[0].toUpperCase() : '';
    return '$n$a';
  }
}

// ─── Tile de navegação ────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool activo;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = item.corActiva ?? _kAccent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? cor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: activo
              ? Border.all(color: cor.withOpacity(0.25))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(item.icone,
                color: activo ? cor : _kTextSecondary,
                size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: activo ? cor : _kTextSecondary,
                  )),
            ),
            if (activo)
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                    color: cor, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Acção no menu de perfil ──────────────────────────────────────────────────

class _AcaoPerfil extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;
  final Color? cor;

  const _AcaoPerfil({
    required this.icone,
    required this.label,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final c = cor ?? _kTextSecondary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icone, color: c, size: 16),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}