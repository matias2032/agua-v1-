import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// ─── Paleta de Cores ─────────────────────────────────────────────────────────
const _kBg            = Color(0xFF0A0E1A);
const _kSurface       = Color(0xFF0D1321);
const _kCard          = Color(0xFF161D2E);
const _kCardBorder    = Color(0xFF1E2A42);
const _kAccent         = Color(0xFF00C9FF);
const _kAccent2        = Color(0xFF0066FF);
const _kTextPrimary    = Color(0xFFF0F4FF);
const _kTextSecondary  = Color(0xFF8899BB);
const _kSuccess        = Color(0xFF00E5A0);
const _kDanger         = Color(0xFFFF4D6A);

// ─── Modelo de Navegação ─────────────────────────────────────────────────────
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
  _NavItem(icone: Icons.dashboard_rounded, label: 'Dashboard', rota: '/dashboard', corActiva: _kAccent),
  _NavItem(icone: Icons.storefront_rounded, label: 'Menu', rota: '/menu', corActiva: _kAccent),
  _NavItem(icone: Icons.water_drop_rounded, label: 'Estoque', rota: '/estoque', corActiva: _kAccent),
  _NavItem(icone: Icons.history_rounded, label: 'Histórico de pedidos', rota: '/historico_pedidos', corActiva: _kAccent),
  _NavItem(icone: Icons.inventory_2_rounded, label: 'Produtos', rota: '/gerenciar_produtos', corActiva: _kSuccess),
  _NavItem(icone: Icons.people_rounded, label: 'Utilizadores', rota: '/gerenciar_usuarios', corActiva: _kSuccess),
  _NavItem(icone: Icons.print_rounded, label: 'Configurações Impressora', rota: '/configuracoes_impressora', corActiva: _kSuccess),
];

// ─── Widget Principal ────────────────────────────────────────────────────────
class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> with SingleTickerProviderStateMixin {
  bool _perfilExpandido = false;
  late final AnimationController _perfilCtrl;
  late final Animation<double> _perfilAnim;

  @override
  void initState() {
    super.initState();
    _perfilCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _perfilAnim = CurvedAnimation(parent: _perfilCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _perfilCtrl.dispose();
    super.dispose();
  }

  void _togglePerfil() {
    HapticFeedback.selectionClick();
    setState(() => _perfilExpandido = !_perfilExpandido);
    _perfilExpandido ? _perfilCtrl.forward() : _perfilCtrl.reverse();
  }

  String get _rotaActual => ModalRoute.of(context)?.settings.name ?? '';

  void _navegar(String rota) {
    Navigator.pop(context); 
    if (_rotaActual == rota) return;
    Navigator.pushReplacementNamed(context, rota);
  }

  Future<void> _logout() async {
    Navigator.pop(context);
    SessaoService.instance.limparSessao(); 
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final sessao = SessaoService.instance;
    final nome = sessao.nomeUsuario ?? 'Utilizador';
    final apelido = sessao.usuarioAtual?.apelido ?? ''; 
    final email = sessao.usuarioAtual?.email ?? '';
    final iniciais = _iniciais(nome, apelido);
    final isAdmin = SessaoService.instance.usuarioAtual?.idPerfil == 1;

    return Drawer(
      width: 280,
      backgroundColor: _kSurface,
      child: SafeArea(
        child: Column(
          children: [
            _buildBranding(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildSeccaoLabel('Principal'),
                  // Renderiza automaticamente os 2 primeiros itens
                  ..._kNavItems.take(2).map((item) => _NavTile(
                    item: item,
                    activo: _rotaActual == item.rota,
                    onTap: () => _navegar(item.rota),
                  )),
                  
                  const SizedBox(height: 16),
              if (isAdmin) ...[
  const SizedBox(height: 16),
  _buildSeccaoLabel('Gestão'),
  ..._kNavItems.skip(2).map((item) => _NavTile(
    item: item,
    activo: _rotaActual == item.rota,
    onTap: () => _navegar(item.rota),
  )),
],
                ],
              ),
            ),
            const Divider(height: 1, color: _kCardBorder),
            _buildPerfilSection(iniciais: iniciais, nome: nome, apelido: apelido, email: email),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('AquaStore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextPrimary)),
        ],
      ),
    );
  }

  Widget _buildSeccaoLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Text(texto.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kTextSecondary, letterSpacing: 1.2)),
    );
  }

  Widget _buildPerfilSection({required String iniciais, required String nome, required String apelido, required String email}) {
    final nomeCompleto = apelido.isNotEmpty ? '$nome $apelido' : nome;
    return Column(
      children: [
        SizeTransition(
          sizeFactor: _perfilAnim,
          axisAlignment: 1.0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            decoration: BoxDecoration(
              color: _kCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kCardBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(
              children: [
                _AcaoPerfil(icone: Icons.edit_rounded, label: 'Editar dados', onTap: () => Navigator.pushNamed(context, '/editar_usuario')),
                const Divider(height: 1, color: _kCardBorder),
                _AcaoPerfil(icone: Icons.lock_outline_rounded, label: 'Alterar senha', onTap: () => Navigator.pushNamed(context, '/alterar_senha')),
                const Divider(height: 1, color: _kCardBorder),
                _AcaoPerfil(icone: Icons.logout_rounded, label: 'Terminar sessão', cor: _kDanger, onTap: _logout),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: _togglePerfil,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _perfilExpandido ? _kAccent.withOpacity(0.07) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _perfilExpandido ? _kAccent.withOpacity(0.25) : _kCardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kAccent, _kAccent2]), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(iniciais, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomeCompleto, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPrimary)),
                      Text(email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
                    ],
                  ),
                ),
                AnimatedRotation(turns: _perfilExpandido ? 0.5 : 0, duration: const Duration(milliseconds: 250), child: const Icon(Icons.keyboard_arrow_up_rounded, color: _kTextSecondary, size: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _iniciais(String nome, String apelido) {
    final n = nome.isNotEmpty ? nome[0].toUpperCase() : '';
    final a = apelido.isNotEmpty ? apelido[0].toUpperCase() : '';
    return '$n$a';
  }
}

// ─── Componentes Auxiliares ──────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool activo;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = item.corActiva ?? _kAccent;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? cor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: activo ? Border.all(color: cor.withOpacity(0.25)) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(item.icone, color: activo ? cor : _kTextSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: activo ? cor : _kTextSecondary))),
            if (activo) Container(width: 6, height: 6, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

class _AcaoPerfil extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;
  final Color? cor;

  const _AcaoPerfil({required this.icone, required this.label, required this.onTap, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? _kTextSecondary;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icone, color: c, size: 16),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}