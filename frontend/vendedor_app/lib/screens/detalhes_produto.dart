import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:decimal/decimal.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// ─── Paleta (partilhada) ──────────────────────────────────────────────────
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

class DetalhesProdutoScreen extends StatefulWidget {
  final DisponibilidadeProdutoModel produto;

  const DetalhesProdutoScreen({super.key, required this.produto});

  @override
  State<DetalhesProdutoScreen> createState() => _DetalhesProdutoScreenState();
}

class _DetalhesProdutoScreenState extends State<DetalhesProdutoScreen>
    with TickerProviderStateMixin {
  // Operação seleccionada: 1 = Compra, 2 = Reenchimento
  int _idOperacao = 1;
  int _idTipoPagamento = 1;
  int _quantidade = 1;
  bool _criando = false;

  late AnimationController _headerCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150),
        () => _contentCtrl.forward());

    // Carregar operações e tipos de pagamento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutoProvider>().carregarOperacoes();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── Getters derivados ─────────────────────────────────────────────────────

  int get _disponivel => widget.produto.quantidadeDisponivel;
  bool get _excedeLimite => _quantidade > _disponivel;


  Decimal get _precoUnitario => _idOperacao == 1
      ? widget.produto.precoCompra
      : widget.produto.precoReenchimento;

  Decimal get _subtotal =>
      _precoUnitario * Decimal.fromInt(_quantidade);

  // ── Criar pedido ──────────────────────────────────────────────────────────

  Future<void> _criarPedido() async {
    if (!_podecriar) return;
    HapticFeedback.mediumImpact();
    setState(() => _criando = true);

    final idUsuario = SessaoService.instance.idUsuario;
    if (idUsuario == null) {
      _mostrarErro('Sessão expirada. Faça login novamente.');
      setState(() => _criando = false);
      return;
    }

    final request = PedidoRequest(
      idOperacao: _idOperacao,
      idTipoPagamento: _idTipoPagamento,
      itens: [
        ItemPedidoRequest(
          idProduto: widget.produto.idProduto,
          quantidade: _quantidade,
          idOperacao: _idOperacao,
        ),
      ],
    );

    final prov = context.read<PedidoProvider>();
    final pedido = await prov.criar(request, idUsuario);

    setState(() => _criando = false);

    if (pedido != null && mounted) {
     HapticFeedback.heavyImpact();
      _mostrarSucesso(pedido.idPedido);
    } else if (prov.temErro && mounted) {
      _mostrarErro(prov.erro ?? 'Erro ao criar pedido');
    }
  }

  // Getter usado acima — corrigido typo
 bool get _podecriar => !_excedeLimite && _quantidade >= 1 && !_criando;
  bool get _podecriar_interno => !_excedeLimite && _quantidade >= 1 && !_criando;

  void _mostrarSucesso(int idPedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SucessoSheet(
        idPedido: idPedido,
        onVerPedidos: () {
          Navigator.pop(context); // fecha sheet
          Navigator.pop(context); // volta ao menu
          Navigator.pushNamed(context, '/pedidos-por-finalizar');
        },
        onNovoPedido: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(mensagem,
                    style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: _kDanger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
        body: Column(
          children: [
            // Header hero
            FadeTransition(
              opacity: _headerFade,
              child: _buildHero(),
            ),
            // Conteúdo scrollável
            Expanded(
              child: SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentCtrl,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEstoqueInfo(),
                        const SizedBox(height: 20),
                        _buildOperacaoSelector(),
                        const SizedBox(height: 20),
                        _buildPagamentoSelector(),
                        const SizedBox(height: 20),
                        _buildQuantidadeControl(),
                        const SizedBox(height: 20),
                        _buildResumo(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Botão fixo no fundo
        bottomSheet: _buildBottomAction(),
      ),
    );
  }

  // ── Hero header ───────────────────────────────────────────────────────────

  Widget _buildHero() {
    final p = widget.produto;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kAccent2.withOpacity(0.3),
            _kBg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              // Barra de navegação
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _kTextPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalhes do Produto',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Ícone grande
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kAccent.withOpacity(0.2),
                      _kAccent2.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kAccent.withOpacity(0.3),
                      width: 1.5),
                ),
                child: Icon(Icons.water_drop_rounded,
                    color: _kAccent, size: 44),
              ),
              const SizedBox(height: 16),
              Text(
                p.nomeProduto,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Capacidade: ${p.capacidadeLitros.toStringAsFixed(p.capacidadeLitros == p.capacidadeLitros.truncate() ? 0 : 1)} litros por galão',
                style: const TextStyle(
                    fontSize: 14, color: _kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Estoque info ──────────────────────────────────────────────────────────

  Widget _buildEstoqueInfo() {
    final p = widget.produto;
    final color = p.quantidadeDisponivel == 0
        ? _kDanger
        : p.quantidadeDisponivel <= 3
            ? _kWarning
            : _kSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.quantidadeDisponivel} unidades disponíveis',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '${p.litrosDisponiveis.toStringAsFixed(1)} litros no estoque global',
                  style: const TextStyle(
                      fontSize: 12, color: _kTextSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.quantidadeDisponivel == 0
                  ? 'Esgotado'
                  : p.quantidadeDisponivel <= 3
                      ? 'Quase a esgotar'
                      : 'Em stock',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de operação ──────────────────────────────────────────────────

  Widget _buildOperacaoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(texto: 'Tipo de operação'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OperacaoTile(
                id: 1,
                titulo: 'Compra nova',
                subtitulo: 'Recipiente incluído',
                icone: Icons.shopping_bag_rounded,
                preco: widget.produto.precoCompra,
                seleccionado: _idOperacao == 1,
                onTap: () => setState(() => _idOperacao = 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OperacaoTile(
                id: 2,
                titulo: 'Reenchimento',
                subtitulo: 'Recipiente próprio',
                icone: Icons.recycling_rounded,
                preco: widget.produto.precoReenchimento,
                seleccionado: _idOperacao == 2,
                accent: _kSuccess,
                onTap: () => setState(() => _idOperacao = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Selector de pagamento ─────────────────────────────────────────────────

  Widget _buildPagamentoSelector() {
    // Tipos fixos (correspondem aos dados iniciais do schema)
    const tipos = [
      (id: 1, nome: 'Dinheiro', icone: Icons.payments_rounded),
      (id: 2, nome: 'Transferência', icone: Icons.account_balance_rounded),
      (id: 3, nome: 'Débito', icone: Icons.credit_card_rounded),
      (id: 4, nome: 'Crédito', icone: Icons.credit_score_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(texto: 'Forma de pagamento'),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tipos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final t = tipos[i];
              final sel = _idTipoPagamento == t.id;
              return GestureDetector(
                onTap: () => setState(() => _idTipoPagamento = t.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel
                        ? _kAccent.withOpacity(0.15)
                        : _kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel
                          ? _kAccent.withOpacity(0.5)
                          : _kCardBorder,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.icone,
                          color: sel ? _kAccent : _kTextSecondary,
                          size: 20),
                      const SizedBox(height: 4),
                      Text(
                        t.nome,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? _kAccent : _kTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Controlo de quantidade ────────────────────────────────────────────────

  Widget _buildQuantidadeControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(texto: 'Quantidade'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _excedeLimite
                  ? _kDanger.withOpacity(0.5)
                  : _kCardBorder,
              width: _excedeLimite ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Botão —
              _QtyButton(
                icone: Icons.remove_rounded,
                activo: _quantidade > 1,
                onTap: () {
                  if (_quantidade > 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _quantidade--);
                  }
                },
              ),
              // Número
              Expanded(
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim, child: child),
                      child: Text(
                        '$_quantidade',
                        key: ValueKey(_quantidade),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _excedeLimite
                              ? _kDanger
                              : _kTextPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    Text(
                      'de ${_disponivel} disponíveis',
                      style: TextStyle(
                        fontSize: 12,
                        color: _excedeLimite
                            ? _kDanger.withOpacity(0.7)
                            : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão +
              _QtyButton(
                icone: Icons.add_rounded,
                activo: _quantidade < _disponivel,
                accent: true,
                onTap: () {
                  if (_quantidade < _disponivel) {
                    HapticFeedback.selectionClick();
                    setState(() => _quantidade++);
                  }
                },
              ),
            ],
          ),
        ),
        // Mensagem de erro de quantidade
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _excedeLimite
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: _kDanger, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Quantidade superior ao estoque disponível ($_disponivel un.)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kDanger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Resumo do pedido ──────────────────────────────────────────────────────

  Widget _buildResumo() {
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
          const _SectionLabel(texto: 'Resumo do pedido'),
          const SizedBox(height: 14),
          _ResumoLinha(
              label: 'Produto', valor: widget.produto.nomeProduto),
          _ResumoLinha(
              label: 'Preço unitário',
              valor: '${_precoUnitario.toStringAsFixed(2)} MT'),
          _ResumoLinha(
              label: 'Quantidade', valor: '$_quantidade un.'),
          const Divider(color: _kCardBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              Text(
                '${_subtotal.toStringAsFixed(2)} MT',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kAccent,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Botão de acção ────────────────────────────────────────────────────────

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Aviso de bloqueio
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _excedeLimite
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kDanger.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.block_rounded,
                              color: _kDanger, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pedido bloqueado — quantidade excede o estoque',
                              style: TextStyle(
                                fontSize: 13,
                                color: _kDanger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Botão principal
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                child: ElevatedButton(
                  onPressed:
                      (_podecriar && !_criando) ? _criarPedido : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _podecriar ? _kAccent : _kCardBorder,
                    foregroundColor:
                        _podecriar ? _kBg : _kTextSecondary,
                    elevation: _podecriar ? 8 : 0,
                    shadowColor: _kAccent.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _criando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _excedeLimite
                                  ? Icons.block_rounded
                                  : Icons.add_shopping_cart_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _excedeLimite
                                  ? 'Pedido bloqueado'
                                  : 'Criar Pedido • ${_subtotal.toStringAsFixed(2)} MT',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String texto;
  const _SectionLabel({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kTextSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _OperacaoTile extends StatelessWidget {
  final int id;
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Decimal preco;
  final bool seleccionado;
  final VoidCallback onTap;
  final Color accent;

  const _OperacaoTile({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.preco,
    required this.seleccionado,
    required this.onTap,
    this.accent = _kAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionado ? accent.withOpacity(0.12) : _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? accent.withOpacity(0.5) : _kCardBorder,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone,
                    color: seleccionado ? accent : _kTextSecondary,
                    size: 18),
                const Spacer(),
                if (seleccionado)
                  Icon(Icons.check_circle_rounded,
                      color: accent, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: seleccionado ? accent : _kTextPrimary,
              ),
            ),
            Text(
              subtitulo,
              style: const TextStyle(
                  fontSize: 11, color: _kTextSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              '${preco.toStringAsFixed(2)} MT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: seleccionado ? accent : _kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icone;
  final bool activo;
  final bool accent;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icone,
    required this.onTap,
    this.activo = true,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo
        ? (accent ? _kAccent : _kTextSecondary)
        : _kCardBorder;

    return GestureDetector(
      onTap: activo ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: activo
              ? (accent
                  ? _kAccent.withOpacity(0.15)
                  : _kSurface)
              : _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icone, color: color, size: 22),
      ),
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  final String label;
  final String valor;
  const _ResumoLinha({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: _kTextSecondary)),
          Text(valor,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary)),
        ],
      ),
    );
  }
}

// ─── Sheet de sucesso ─────────────────────────────────────────────────────────

class _SucessoSheet extends StatelessWidget {
  final int idPedido;
  final VoidCallback onVerPedidos;
  final VoidCallback onNovoPedido;

  const _SucessoSheet({
    required this.idPedido,
    required this.onVerPedidos,
    required this.onNovoPedido,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kSuccess.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: _kSuccess, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pedido criado!',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pedido #$idPedido criado com sucesso.\nAguarda finalização.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _kTextSecondary),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onVerPedidos,
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Ver pedidos por finalizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: _kBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onNovoPedido,
              child: const Text(
                'Voltar ao menu',
                style: TextStyle(color: _kTextSecondary, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}