import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:decimal/decimal.dart';
import '/widgets/app_sidebar.dart';

// ─── Paleta (mesmo padrão do Dashboard) ──────────────────────────────────────
const _kBg            = Color(0xFF0A0E1A);
const _kSurface       = Color(0xFF111827);
const _kCard          = Color(0xFF161D2E);
const _kCardBorder    = Color(0xFF1E2A42);
const _kAccent        = Color(0xFF00C9FF);
const _kAccent2       = Color(0xFF0066FF);
const _kTextPrimary   = Color(0xFFF0F4FF);
const _kTextSecondary = Color(0xFF8899BB);
const _kSuccess       = Color(0xFF00E5A0);
const _kWarning       = Color(0xFFFFB800);
const _kDanger        = Color(0xFFFF4D6A);
const _kPurple        = Color(0xFF9B6DFF);

// ─── Períodos (idêntico ao Dashboard) ────────────────────────────────────────
enum _Periodo {
  dia('1D', 1),
  semana('7D', 7),
  mes('1M', 30),
  tresMeses('3M', 90),
  seisMeses('6M', 180),
  ano('1A', 365);

  final String label;
  final int dias;
  const _Periodo(this.label, this.dias);
}

// ─── Tela ─────────────────────────────────────────────────────────────────────
class HistoricoPedidosScreen extends StatefulWidget {
  const HistoricoPedidosScreen({super.key});

  @override
  State<HistoricoPedidosScreen> createState() => _HistoricoPedidosScreenState();
}

class _HistoricoPedidosScreenState extends State<HistoricoPedidosScreen>
    with SingleTickerProviderStateMixin {
  _Periodo _periodo       = _Periodo.semana;
  String?  _filtroStatus; // null = todos
  bool     _carregando    = false;
  List<PedidoModel> _todos = [];
  String?  _erro;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  static const _statusOpcoes = ['todos', 'finalizado', 'cancelado', 'pendente'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Carregamento ────────────────────────────────────────────────────────────

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final prov = context.read<PedidoProvider>();
      // Carrega todos os pedidos (sem filtro de status para ter o histórico completo)
      await prov.carregar();
      if (mounted) {
        setState(() {
          _todos      = List.of(prov.pedidos);
          _carregando = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  // ── Filtros ─────────────────────────────────────────────────────────────────

  List<PedidoModel> get _pedidosFiltrados {
    final corte = DateTime.now().subtract(Duration(days: _periodo.dias));
    return _todos.where((p) {
      final noPeriodo = p.dataPedido.isAfter(corte);
      final noStatus  = _filtroStatus == null || _filtroStatus == 'todos'
          ? true
          : p.statusPedido == _filtroStatus;
      return noPeriodo && noStatus;
    }).toList()
      ..sort((a, b) => b.dataPedido.compareTo(a.dataPedido));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        drawer: const AppSidebar(),
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSelectorPeriodo(),
              _buildFiltroStatus(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 44, height: 44,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Icon(Icons.menu_rounded,
                    color: _kTextSecondary, size: 20),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Histórico',
                    style: TextStyle(
                      fontFamily: 'Georgia', fontSize: 26,
                      fontWeight: FontWeight.w700, color: _kTextPrimary,
                      letterSpacing: -0.6,
                    )),
                const Text('Todos os pedidos registados',
                    style: TextStyle(fontSize: 13, color: _kTextSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _carregar,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kCardBorder),
              ),
              child: _carregando
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: _kAccent, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded,
                      color: _kTextSecondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de período ─────────────────────────────────────────────────────

  Widget _buildSelectorPeriodo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kCardBorder),
        ),
        child: Row(
          children: _Periodo.values.map((p) {
            final sel = p == _periodo;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _periodo = p);
                  _fadeCtrl.forward(from: 0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: sel ? _kAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(p.label,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: sel ? _kBg : _kTextSecondary,
                        )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Filtro de status ────────────────────────────────────────────────────────

  Widget _buildFiltroStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOpcoes.map((s) {
            final sel = (_filtroStatus ?? 'todos') == s;
            final cor = _corStatus(s);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filtroStatus = s == 'todos' ? null : s);
                _fadeCtrl.forward(from: 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? cor.withOpacity(0.15) : _kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? cor : _kCardBorder, width: 1.2),
                ),
                child: Text(
                  _labelStatus(s),
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? cor : _kTextSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _corStatus(String s) {
    switch (s) {
      case 'finalizado': return _kSuccess;
      case 'cancelado':  return _kDanger;
      case 'pendente':   return _kWarning;
      default:           return _kAccent;
    }
  }

  String _labelStatus(String s) {
    switch (s) {
      case 'finalizado': return 'Finalizados';
      case 'cancelado':  return 'Cancelados';
      case 'pendente':   return 'Pendentes';
      default:           return 'Todos';
    }
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_carregando && _todos.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2));
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _kDanger, size: 40),
            const SizedBox(height: 12),
            Text(_erro!,
                style: const TextStyle(color: _kTextSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent, foregroundColor: _kBg),
            ),
          ],
        ),
      );
    }

    final lista = _pedidosFiltrados;

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: _kAccent, backgroundColor: _kCard,
        onRefresh: _carregar,
        child: lista.isEmpty
            ? _buildVazio()
            : _buildLista(lista),
      ),
    );
  }

  Widget _buildVazio() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: _kTextSecondary, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Sem pedidos neste período',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: _kTextPrimary)),
              const SizedBox(height: 6),
              const Text('Ajuste o período ou o filtro de estado.',
                  style: TextStyle(fontSize: 13, color: _kTextSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLista(List<PedidoModel> lista) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      itemCount: lista.length + 1, // +1 para o header de contagem
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text(
              '${lista.length} pedido${lista.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: _kTextSecondary),
            ),
          );
        }
        return _PedidoCard(pedido: lista[index - 1]);
      },
    );
  }
}

// ─── Card de pedido ──────────────────────────────────────────────────────────

class _PedidoCard extends StatelessWidget {
  final PedidoModel pedido;
  const _PedidoCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final cor    = _corStatus(pedido.statusPedido);
    final icone  = _iconeStatus(pedido.statusPedido);

    // Nome do utilizador que criou: nome + apelido (ou fallback)
    // NOTA: PedidoModel deve expor nomeUsuario e apelidoUsuario (ver secção
    // "Alterações necessárias no backend / DTO" abaixo).
    final nomeOperador = _nomeOperador(pedido);

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        children: [
          // ── Cabeçalho do card ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                // Ícone de status
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, color: cor, size: 17),
                ),
                const SizedBox(width: 10),

                // Referência + data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pedido.reference ?? '#${pedido.idPedido}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _kTextPrimary),
                      ),
                      Text(
                        _formatarData(pedido.dataPedido),
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),

                // Badge de status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _labelStatus(pedido.statusPedido),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: cor, letterSpacing: 0.4),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _kCardBorder),

          // ── Corpo do card ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                // Cliente
                _InfoLinha(
                  icone: Icons.person_outline_rounded,
                  label: 'Cliente',
                  valor: pedido.nomeCliente?.isNotEmpty == true
                      ? pedido.nomeCliente!
                      : '—',
                ),
                const SizedBox(height: 6),

                // Operador (nome + apelido em vez de id_usuario)
                _InfoLinha(
                  icone: Icons.badge_outlined,
                  label: 'Operador',
                  valor: nomeOperador,
                  corValor: _kAccent,
                ),
                const SizedBox(height: 6),

                // Itens (quantidade total)
                _InfoLinha(
                  icone: Icons.list_alt_rounded,
                  label: 'Itens',
                  valor: '${pedido.itens.length} produto${pedido.itens.length != 1 ? 's' : ''}',
                ),
                const SizedBox(height: 10),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _kTextSecondary)),
                    Text(
                      '${pedido.total.toStringAsFixed(2)} MT',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: cor, letterSpacing: -0.4),
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Monta o nome do operador a partir dos campos expostos pelo backend.
  /// Se o backend ainda não expõe nomeUsuario/apelidoUsuario, usa o idUsuario
  /// como fallback temporário (ver nota na secção de alterações do backend).
  String _nomeOperador(PedidoModel p) {
    final nome    = p.nomeUsuario;
    final apelido = p.apelidoUsuario;
    if (nome != null && apelido != null) return '$nome $apelido';
    if (nome != null) return nome;
    return 'Utilizador #${p.idUsuario}';
  }

  Color _corStatus(String? s) {
    switch (s) {
      case 'finalizado': return _kSuccess;
      case 'cancelado':  return _kDanger;
      case 'pendente':   return _kWarning;
      default:           return _kTextSecondary;
    }
  }

  IconData _iconeStatus(String? s) {
    switch (s) {
      case 'finalizado': return Icons.check_circle_outline_rounded;
      case 'cancelado':  return Icons.cancel_outlined;
      case 'pendente':   return Icons.hourglass_top_rounded;
      default:           return Icons.receipt_long_rounded;
    }
  }

  String _labelStatus(String? s) {
    switch (s) {
      case 'finalizado': return 'FINALIZADO';
      case 'cancelado':  return 'CANCELADO';
      case 'pendente':   return 'PENDENTE';
      default:           return s?.toUpperCase() ?? '—';
    }
  }

  String _formatarData(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1)   return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24)  return 'há ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Linha de informação ─────────────────────────────────────────────────────

class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String   label;
  final String   valor;
  final Color?   corValor;

  const _InfoLinha({
    required this.icone,
    required this.label,
    required this.valor,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 14, color: _kTextSecondary),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: _kTextSecondary)),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: corValor ?? _kTextPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ALTERAÇÕES NECESSÁRIAS NO BACKEND / DTO
// ══════════════════════════════════════════════════════════════════════════════
//
// Para mostrar nome + apelido do operador em vez do id_usuario, são necessárias
// as seguintes alterações mínimas:
//
// 1. PedidoDTO.Response — adicionar dois campos:
//
//    private String nomeUsuario;
//    private String apelidoUsuario;
//
// 2. PedidoService.toResponse() — popular os campos acima com um lookup ao
//    repositório de utilizadores (UsuarioRepository ou similar):
//
//    Usuario u = usuarioRepository.findById(pedido.getIdUsuario()).orElse(null);
//    .nomeUsuario(u != null ? u.getNome() : null)
//    .apelidoUsuario(u != null ? u.getApelido() : null)
//
// 3. PedidoModel (Flutter) — adicionar os campos correspondentes:
//
//    final String? nomeUsuario;
//    final String? apelidoUsuario;
//
//    // No fromJson:
//    nomeUsuario:    json['nomeUsuario']    as String?,
//    apelidoUsuario: json['apelidoUsuario'] as String?,
//
// ══════════════════════════════════════════════════════════════════════════════