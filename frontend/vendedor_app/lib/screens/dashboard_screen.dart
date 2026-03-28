import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:decimal/decimal.dart';
import '/widgets/app_sidebar.dart';

// ─── Paleta partilhada ────────────────────────────────────────────────────────
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

// Paleta rotativa para avatares de operadores
const _kAvatarCores = [
  _kAccent, _kPurple, _kSuccess, _kWarning,
  Color(0xFFFF6B9D), Color(0xFFFFAA40),
];

// ─── Períodos ─────────────────────────────────────────────────────────────────

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

// ─── Modelo de métricas globais ───────────────────────────────────────────────

class _Metricas {
  final int totalPedidos;
  final Decimal totalReceita;
  final int totalCompras;
  final Decimal receitaCompras;
  final int totalReenchimentos;
  final Decimal receitaReenchimentos;
  final Decimal ticketMedio;

  const _Metricas({
    required this.totalPedidos,
    required this.totalReceita,
    required this.totalCompras,
    required this.receitaCompras,
    required this.totalReenchimentos,
    required this.receitaReenchimentos,
    required this.ticketMedio,
  });

  factory _Metricas.zero() => _Metricas(
        totalPedidos: 0,
        totalReceita: Decimal.zero,
        totalCompras: 0,
        receitaCompras: Decimal.zero,
        totalReenchimentos: 0,
        receitaReenchimentos: Decimal.zero,
        ticketMedio: Decimal.zero,
      );
}

// ─── Modelo de desempenho por operador ───────────────────────────────────────

class _DesempenhoOperador {
  final int idUsuario;
  final String nome;
  final int totalPedidos;
  final Decimal totalReceita;
  final Decimal ticketMedio;

  const _DesempenhoOperador({
    required this.idUsuario,
    required this.nome,
    required this.totalPedidos,
    required this.totalReceita,
    required this.ticketMedio,
  });
}

// ─── Tela principal ───────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  _Periodo _periodo = _Periodo.semana;
  bool _carregando = false;
  List<PedidoModel> _pedidosFinalizados = [];
  String? _erro;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final prov = context.read<PedidoProvider>();
      await prov.carregar(status: 'finalizado');
      if (mounted) {
        setState(() {
          _pedidosFinalizados = prov.pedidos
              .where((p) => p.isFinalizado)
              .toList();
          _carregando = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  // ── Filtragem por período ────────────────────────────────────────────────

  List<PedidoModel> get _pedidosFiltrados {
    final corte = DateTime.now().subtract(Duration(days: _periodo.dias));
    return _pedidosFinalizados
        .where((p) => p.dataPedido.isAfter(corte))
        .toList();
  }

  // ── Cálculo de métricas globais ──────────────────────────────────────────

  _Metricas get _metricas {
    final lista = _pedidosFiltrados;
    if (lista.isEmpty) return _Metricas.zero();

    var receitaTotal   = Decimal.zero;
    var receitaCompras = Decimal.zero;
    var receitaReench  = Decimal.zero;
    var nCompras       = 0;
    var nReench        = 0;

    for (final p in lista) {
      receitaTotal += p.total;
      for (final item in p.itens) {
        if (item.idOperacao == 1) {
          receitaCompras += item.subtotal ?? Decimal.zero;
          nCompras++;
        } else {
          receitaReench += item.subtotal ?? Decimal.zero;
          nReench++;
        }
      }
    }

    final ticket = lista.isNotEmpty
        ? (receitaTotal / Decimal.fromInt(lista.length))
            .toDecimal(scaleOnInfinitePrecision: 2)
        : Decimal.zero;

    return _Metricas(
      totalPedidos: lista.length,
      totalReceita: receitaTotal,
      totalCompras: nCompras,
      receitaCompras: receitaCompras,
      totalReenchimentos: nReench,
      receitaReenchimentos: receitaReench,
      ticketMedio: ticket,
    );
  }

  // ── Cálculo de desempenho por operador ──────────────────────────────────

  List<_DesempenhoOperador> get _desempenhoOperadores {
    final lista = _pedidosFiltrados;
    if (lista.isEmpty) return [];

    final Map<int, List<PedidoModel>> porUsuario = {};
    for (final p in lista) {
      porUsuario.putIfAbsent(p.idUsuario, () => []).add(p);
    }

    final operadores = porUsuario.entries.map((e) {
      final pedidos = e.value;
      final receita = pedidos.fold(Decimal.zero, (acc, p) => acc + p.total);
      final ticket  = pedidos.isNotEmpty
          ? (receita / Decimal.fromInt(pedidos.length))
              .toDecimal(scaleOnInfinitePrecision: 2)
          : Decimal.zero;

      final primeiro = pedidos.first;
      final nome     = _nomeOperador(primeiro);

      return _DesempenhoOperador(
        idUsuario:    e.key,
        nome:         nome,
        totalPedidos: pedidos.length,
        totalReceita: receita,
        ticketMedio:  ticket,
      );
    }).toList();

    operadores.sort((a, b) => b.totalReceita.compareTo(a.totalReceita));
    return operadores;
  }

  String _nomeOperador(PedidoModel p) {
    final nome    = p.nomeUsuario;
    final apelido = p.apelidoUsuario;
    if (nome != null && apelido != null) return '$nome $apelido';
    if (nome != null) return nome;
    return 'Operador #${p.idUsuario}';
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
        drawer: const AppSidebar(),
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSelectorPeriodo(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Row(
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
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
                const Text('Dashboard',
                    style: TextStyle(
                      fontFamily: 'Georgia', fontSize: 26,
                      fontWeight: FontWeight.w700, color: _kTextPrimary,
                      letterSpacing: -0.6,
                    )),
                const Text('Vendas finalizadas',
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

  // ── Selector de período ───────────────────────────────────────────────────

  Widget _buildSelectorPeriodo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_carregando && _pedidosFinalizados.isEmpty) {
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

    final m          = _metricas;
    final operadores = _desempenhoOperadores;
    final receitaMax = operadores.isNotEmpty
        ? operadores.first.totalReceita
        : Decimal.zero;

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: _kAccent, backgroundColor: _kCard,
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            // ── KPI principal ───────────────────────────────────────────
            _KpiPrincipal(metricas: m),
            const SizedBox(height: 16),

            // ── Grid KPIs secundários ───────────────────────────────────
            Row(
              children: [
                Expanded(child: _KpiCard(
                  label: 'Pedidos',
                  valor: '${m.totalPedidos}',
                  icone: Icons.receipt_long_rounded,
                  cor: _kAccent,
                )),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(
                  label: 'Ticket médio',
                  valor: '${m.ticketMedio.toStringAsFixed(0)} MT',
                  icone: Icons.analytics_rounded,
                  cor: _kPurple,
                )),
              ],
            ),
            const SizedBox(height: 16),

            // ── Breakdown compras vs reenchimentos ──────────────────────
            _BreakdownCard(metricas: m),
            const SizedBox(height: 16),

            // ── Desempenho dos operadores ───────────────────────────────
            _DesempenhoCard(
              operadores: operadores,
              receitaMax: receitaMax,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── KPI Principal ────────────────────────────────────────────────────────────

class _KpiPrincipal extends StatelessWidget {
  final _Metricas metricas;
  const _KpiPrincipal({required this.metricas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1E3A), Color(0xFF0A0E1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: _kAccent.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kSuccess.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('RECEITA TOTAL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _kSuccess,
                        letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${metricas.totalReceita.toStringAsFixed(2)} MT',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${metricas.totalPedidos} pedido${metricas.totalPedidos != 1 ? 's' : ''} finalizados',
            style: const TextStyle(fontSize: 13, color: _kTextSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: metricas.totalReceita > Decimal.zero
                  ? (metricas.receitaCompras / metricas.totalReceita).toDouble()
                  : 0,
              backgroundColor: _kSuccess.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Dot(_kAccent),
              const SizedBox(width: 4),
              const Text('Compras',
                  style: TextStyle(fontSize: 11, color: _kTextSecondary)),
              const SizedBox(width: 12),
              _Dot(_kSuccess),
              const SizedBox(width: 4),
              const Text('Reenchimentos',
                  style: TextStyle(fontSize: 11, color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color cor;
  const _Dot(this.cor);

  @override
  Widget build(BuildContext context) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: cor, shape: BoxShape.circle));
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icone;
  final Color cor;

  const _KpiCard({
    required this.label,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(valor,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cor,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
        ],
      ),
    );
  }
}

// ─── Breakdown Compras vs Reenchimentos ──────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final _Metricas metricas;
  const _BreakdownCard({required this.metricas});

  @override
  Widget build(BuildContext context) {
    final total = metricas.totalReceita;
    final pctCompra = total > Decimal.zero
        ? (metricas.receitaCompras / total).toDouble()
        : 0.0;
    final pctReench = total > Decimal.zero
        ? (metricas.receitaReenchimentos / total).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vendas por tipo',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 16),
          _BreakdownLinha(
            label: 'Compras',
            descricao: '${metricas.totalCompras} item(ns)',
            receita: metricas.receitaCompras,
            pct: pctCompra,
            cor: _kAccent,
            icone: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 14),
          _BreakdownLinha(
            label: 'Reenchimentos',
            descricao: '${metricas.totalReenchimentos} item(ns)',
            receita: metricas.receitaReenchimentos,
            pct: pctReench,
            cor: _kSuccess,
            icone: Icons.water_drop_outlined,
          ),
        ],
      ),
    );
  }
}

class _BreakdownLinha extends StatelessWidget {
  final String label;
  final String descricao;
  final Decimal receita;
  final double pct;
  final Color cor;
  final IconData icone;

  const _BreakdownLinha({
    required this.label,
    required this.descricao,
    required this.receita,
    required this.pct,
    required this.cor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icone, color: cor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary)),
                  Text(descricao,
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${receita.toStringAsFixed(2)} MT',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cor)),
                Text('${(pct * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: cor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ─── Desempenho dos Operadores ────────────────────────────────────────────────

class _DesempenhoCard extends StatelessWidget {
  final List<_DesempenhoOperador> operadores;
  final Decimal receitaMax;

  const _DesempenhoCard({
    required this.operadores,
    required this.receitaMax,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _kPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.leaderboard_rounded,
                    color: _kPurple, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Desempenho por operador',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kPurple.withOpacity(0.25)),
                ),
                child: Text(
                  '${operadores.length} operador${operadores.length != 1 ? 'es' : ''}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kPurple),
                ),
              ),
            ],
          ),

          // ── Lista ────────────────────────────────────────────────────
          if (operadores.isEmpty) ...[
            const SizedBox(height: 20),
            const Center(
              child: Text('Sem dados neste período',
                  style: TextStyle(fontSize: 13, color: _kTextSecondary)),
            ),
            const SizedBox(height: 4),
          ] else ...[
            const SizedBox(height: 16),
            ...operadores.asMap().entries.map((e) {
              final idx    = e.key;
              final op     = e.value;
              final cor    = _kAvatarCores[idx % _kAvatarCores.length];
              final pct    = receitaMax > Decimal.zero
                  ? (op.totalReceita / receitaMax).toDouble()
                  : 0.0;
              final isLider = idx == 0;

              return Padding(
                padding: EdgeInsets.only(
                    bottom: idx < operadores.length - 1 ? 14 : 0),
                child: _OperadorLinha(
                  posicao:  idx + 1,
                  operador: op,
                  cor:      cor,
                  pct:      pct,
                  isLider:  isLider,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _OperadorLinha extends StatelessWidget {
  final int posicao;
  final _DesempenhoOperador operador;
  final Color cor;
  final double pct;
  final bool isLider;

  const _OperadorLinha({
    required this.posicao,
    required this.operador,
    required this.cor,
    required this.pct,
    required this.isLider,
  });

  @override
  Widget build(BuildContext context) {
    // Iniciais do nome para o avatar
    final partes   = operador.nome.trim().split(' ');
    final iniciais = partes.length >= 2
        ? '${partes.first[0]}${partes.last[0]}'.toUpperCase()
        : operador.nome
            .substring(0, operador.nome.length.clamp(1, 2))
            .toUpperCase();

    return Column(
      children: [
        Row(
          children: [
            // ── Posição ─────────────────────────────────────────────
            SizedBox(
              width: 22,
              child: Text(
                '#$posicao',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isLider ? _kWarning : _kTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // ── Avatar com estrela para o líder ─────────────────────
            Stack(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: cor.withOpacity(isLider ? 0.6 : 0.28),
                        width: isLider ? 1.5 : 1),
                  ),
                  child: Center(
                    child: Text(iniciais,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: cor)),
                  ),
                ),
                if (isLider)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: _kWarning,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kCard, width: 1.5),
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: _kBg, size: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),

            // ── Nome + sub-info ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    operador.nome,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${operador.totalPedidos} pedido${operador.totalPedidos != 1 ? 's' : ''}'
                    ' · ticket ${operador.ticketMedio.toStringAsFixed(0)} MT',
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSecondary),
                  ),
                ],
              ),
            ),

            // ── Receita ──────────────────────────────────────────────
            Text(
              '${operador.totalReceita.toStringAsFixed(2)} MT',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: cor),
            ),
          ],
        ),

        // ── Barra relativa ao líder ──────────────────────────────────
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: cor.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
                cor.withOpacity(isLider ? 1.0 : 0.55)),
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}