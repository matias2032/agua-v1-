import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'detalhes_produto.dart';

// ─── Paleta & Tema ─────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0E1A);
const _kSurface = Color(0xFF111827);
const _kCard = Color(0xFF161D2E);
const _kCardBorder = Color(0xFF1E2A42);
const _kAccent = Color(0xFF00C9FF);
const _kAccent2 = Color(0xFF0066FF);
const _kTextPrimary = Color(0xFFF0F4FF);
const _kTextSecondary = Color(0xFF8899BB);
const _kSuccess = Color(0xFF00E5A0);
const _kWarning = Color(0xFFFFB800);
const _kDanger = Color(0xFFFF4D6A);

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutoProvider>().carregarProdutos();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo / título
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAccent, _kAccent2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AquaStore',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Badge pedidos pendentes
              _PedidosPendenteBadge(),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Produtos\nDisponíveis',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Consumer<ProdutoProvider>(
            builder: (_, prov, __) {
              final total = prov.produtos
                  .where((p) => p.quantidadeDisponivel > 0)
                  .length;
              return Text(
                '$total produto${total != 1 ? 's' : ''} com estoque',
                style: const TextStyle(
                  fontSize: 14,
                  color: _kTextSecondary,
                  letterSpacing: 0.2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          style: const TextStyle(color: _kTextPrimary, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Pesquisar produto…',
            hintStyle: TextStyle(color: _kTextSecondary, fontSize: 15),
            prefixIcon:
                Icon(Icons.search_rounded, color: _kTextSecondary, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Consumer<ProdutoProvider>(
      builder: (_, prov, __) {
        if (prov.carregando && prov.produtos.isEmpty) {
          return const Center(child: _LoadingPulse());
        }
       if (prov.estado == EstadoCarregamento.erro && prov.produtos.isEmpty) {
          return _ErrorState(
           mensagem: prov.mensagemErro ?? 'Erro desconhecido',
            onRetry: () => prov.carregarProdutos(),
          );
        }

        // Filtrar activos + pesquisa
        final lista = prov.produtos
            .where((p) =>
                p.ativo &&
                (p.nomeProduto.toLowerCase().contains(_searchQuery) ||
                    _searchQuery.isEmpty))
            .toList();

        if (lista.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          color: _kAccent,
          backgroundColor: _kCard,
          onRefresh: () => prov.carregarProdutos(),
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: lista.length,
              itemBuilder: (ctx, i) => _ProdutoCard(
                produto: lista[i],
                delay: i * 60,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Card do produto ──────────────────────────────────────────────────────

class _ProdutoCard extends StatefulWidget {
  final DisponibilidadeProdutoModel produto;
  final int delay;

  const _ProdutoCard({required this.produto, this.delay = 0});

  @override
  State<_ProdutoCard> createState() => _ProdutoCardState();
}

class _ProdutoCardState extends State<_ProdutoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim =
        Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final temEstoque = p.quantidadeDisponivel > 0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: child),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: temEstoque
            ? () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) =>
                        DetalhesProdutoScreen(produto: p),
                    transitionsBuilder: (_, anim, __, child) =>
                        SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration:
                        const Duration(milliseconds: 350),
                  ),
                );
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 16),
          transform: Matrix4.identity()
            ..scale(_pressed ? 0.975 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: temEstoque ? _kCardBorder : _kCardBorder.withOpacity(0.4),
              ),
              boxShadow: temEstoque
                  ? [
                      BoxShadow(
                        color: _kAccent.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: temEstoque ? 1.0 : 0.45,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _ProductIcon(capacidade: p.capacidadeLitros.toDouble()),
                    const SizedBox(width: 16),
                    Expanded(child: _ProductInfo(produto: p)),
                    const SizedBox(width: 12),
                    _StockBadge(quantidade: p.quantidadeDisponivel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductIcon extends StatelessWidget {
  final double capacidade;
  const _ProductIcon({required this.capacidade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kAccent.withOpacity(0.15),
            _kAccent2.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccent.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_rounded,
              color: _kAccent, size: 24),
          const SizedBox(height: 2),
          Text(
            '${capacidade % 1 == 0 ? capacidade.toInt() : capacidade}L',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kAccent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final DisponibilidadeProdutoModel produto;
  const _ProductInfo({required this.produto});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          produto.nomeProduto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Preços
        Row(
          children: [
            _PriceChip(
              label: 'Compra',
              valor: produto.precoCompra.toStringAsFixed(0),
            ),
            const SizedBox(width: 6),
            _PriceChip(
              label: 'Reench.',
              valor: produto.precoReenchimento.toStringAsFixed(0),
              accent: _kSuccess,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Litros disponíveis
        Row(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 12, color: _kTextSecondary),
            const SizedBox(width: 4),
            Text(
              '${produto.litrosDisponiveis.toStringAsFixed(0)} L no estoque',
              style: const TextStyle(
                  fontSize: 12, color: _kTextSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color accent;

  const _PriceChip({
    required this.label,
    required this.valor,
    this.accent = _kAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $valor MT',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int quantidade;
  const _StockBadge({required this.quantidade});

  @override
  Widget build(BuildContext context) {
    final color = quantidade == 0
        ? _kDanger
        : quantidade <= 3
            ? _kWarning
            : _kSuccess;

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '$quantidade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'un.',
          style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }
}

// ─── Badge de pedidos pendentes ─────────────────────────────────────────────

class _PedidosPendenteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/pedidos-por-finalizar'),
      child: Consumer<PedidoProvider>(
        builder: (_, prov, __) {
          final pendentes =
              prov.pedidos.where((p) => p.isPendente).length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: _kTextSecondary, size: 20),
              ),
              if (pendentes > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _kDanger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$pendentes',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Estados especiais ───────────────────────────────────────────────────────

class _LoadingPulse extends StatefulWidget {
  const _LoadingPulse();

  @override
  State<_LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<_LoadingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.6 * _ctrl.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_rounded, color: _kAccent, size: 48),
            const SizedBox(height: 16),
            const Text('A carregar produtos…',
                style: TextStyle(color: _kTextSecondary, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _ErrorState({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _kDanger, size: 48),
            const SizedBox(height: 16),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: _kBg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, color: _kTextSecondary, size: 48),
          SizedBox(height: 16),
          Text('Nenhum produto encontrado',
              style: TextStyle(color: _kTextSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}