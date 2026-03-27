import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:decimal/decimal.dart';
import 'finalizar_pedido.dart';

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

class PedidosPorFinalizarScreen extends StatefulWidget {
  const PedidosPorFinalizarScreen({super.key});

  @override
  State<PedidosPorFinalizarScreen> createState() =>
      _PedidosPorFinalizarScreenState();
}

class _PedidosPorFinalizarScreenState
    extends State<PedidosPorFinalizarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidoProvider>().carregar(status: 'pendente');
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kCardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _kTextPrimary, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedidos por Finalizar',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Consumer<PedidoProvider>(
                      builder: (_, prov, __) {
                        final n = prov.pedidos
                            .where((p) => p.isPendente)
                            .length;
                        return Text(
                          '$n pedido${n != 1 ? 's' : ''} pendente${n != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 13, color: _kTextSecondary),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Refresh
              GestureDetector(
                onTap: () => context
                    .read<PedidoProvider>()
                    .carregar(status: 'pendente'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kCardBorder),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: _kTextSecondary, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Consumer<PedidoProvider>(
      builder: (_, prov, __) {
        if (prov.carregando && prov.pedidos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
                SizedBox(height: 16),
                Text('A carregar pedidos…',
                    style:
                        TextStyle(color: _kTextSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        final pendentes =
            prov.pedidos.where((p) => p.isPendente).toList();

        if (pendentes.isEmpty) {
          return const _EmptyPendentes();
        }

        return RefreshIndicator(
          color: _kAccent,
          backgroundColor: _kCard,
          onRefresh: () =>
              context.read<PedidoProvider>().carregar(status: 'pendente'),
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              itemCount: pendentes.length,
       itemBuilder: (ctx, i) => _PedidoCard(
  pedido: pendentes[i],
  delay: i * 60,
  estaActivo: context.watch<PedidoProvider>().pedidoActivo?.idPedido == pendentes[i].idPedido,
  onToggleActivacao: () => context.read<PedidoProvider>().toggleActivacao(pendentes[i]),
  onFinalizar: () => Navigator.push(
  ctx,
  MaterialPageRoute(
    builder: (_) => FinalizarPedidoScreen(pedido: pendentes[i]),
  ),
).then((finalizado) {
  if (finalizado == true) {
    context.read<PedidoProvider>().carregar(status: 'pendente');
    _showSnack(context, 'Pedido finalizado com sucesso!', _kSuccess);
  }
}),
  onCancelar: () => _confirmarAcao(ctx, pendentes[i], acaao: 'cancelar'),
  onRegistarPagamento: () => _modalPagamento(ctx, pendentes[i]),
),
            ),
          ),
        );
      },
    );
  }

  // ── Diálogos de acção ─────────────────────────────────────────────────────

  Future<void> _confirmarAcao(
    BuildContext context,
    PedidoModel pedido, {
    required String acaao,
  }) async {
    final bool finalizar = acaao == 'finalizar';

    await showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _AcaoSheet(
        pedido: pedido,
        finalizar: finalizar,
        onConfirmar: () async {
  Navigator.pop(sheetCtx);
  HapticFeedback.mediumImpact();
  final prov = context.read<PedidoProvider>();
  bool ok;
  if (finalizar) {
    ok = await prov.finalizar(pedido.idPedido);
  } else {
    final idUsuario = SessaoService.instance.idUsuario ?? 0;
    ok = await prov.cancelar(
      pedido.idPedido,
      CancelamentoPedidoRequest(),
      idUsuario,
    );
  }
  if (ok && context.mounted) {
    _showSnack(
      context,
      finalizar ? 'Pedido finalizado com sucesso!' : 'Pedido cancelado.',
      finalizar ? _kSuccess : _kWarning,
    );
    // ✗ NÃO chamar prov.carregar() aqui — o optimista já tratou
  } else if (prov.temErro && context.mounted) {
    _showSnack(context, prov.erro ?? 'Erro', _kDanger);
  }
},
      ),
    );
  }

  Future<void> _modalPagamento(
      BuildContext context, PedidoModel pedido) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _PagamentoSheet(
        pedido: pedido,
        onConfirmar: (valor) async {
          Navigator.pop(sheetCtx);
          final prov = context.read<PedidoProvider>();
          final ok = await prov.actualizarValorPago(
              pedido.idPedido, ValorPagoRequest(valorPago: valor));
          if (ok && context.mounted) {
            _showSnack(context, 'Pagamento registado!', _kSuccess);
          } else if (prov.temErro && context.mounted) {
            _showSnack(context, prov.erro ?? 'Erro', _kDanger);
          }
        },
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── Card de pedido pendente ──────────────────────────────────────────────────

class _PedidoCard extends StatefulWidget {
  final PedidoModel pedido;
  final int delay;
  final bool estaActivo;           // ← NOVO
  final VoidCallback onToggleActivacao; // ← NOVO

  final VoidCallback onFinalizar;
  final VoidCallback onCancelar;
  final VoidCallback onRegistarPagamento;

  const _PedidoCard({
    required this.pedido,
    this.delay = 0,
    required this.onFinalizar,
    required this.onCancelar,
        required this.estaActivo,
    required this.onToggleActivacao,
    required this.onRegistarPagamento,
  });

  @override
  State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<double>(begin: 40, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: widget.delay),
        () => mounted ? _ctrl.forward() : null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kCardBorder),
          boxShadow: [
            BoxShadow(
              color: _kWarning.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Cabeçalho ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  // Número e status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
  children: [
    // Status chip
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kWarning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PENDENTE',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kWarning, letterSpacing: 0.8),
      ),
    ),
    const SizedBox(width: 8),
    Text('#${p.idPedido}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextSecondary)),
    const Spacer(),
    // ── Toggle de activação ──────────────────────────────────────────
    GestureDetector(
      onTap: widget.onToggleActivacao,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: widget.estaActivo ? _kAccent.withOpacity(0.15) : _kCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.estaActivo ? _kAccent.withOpacity(0.5) : _kCardBorder,
            width: widget.estaActivo ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.estaActivo ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: widget.estaActivo ? _kAccent : _kTextSecondary,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              widget.estaActivo ? 'Activo' : 'Activar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.estaActivo ? _kAccent : _kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
                        const SizedBox(height: 4),
                        Text(
                          p.nomeCliente?.isNotEmpty == true
                              ? p.nomeCliente!
                              : 'Cliente não identificado',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (p.telefoneCliente?.isNotEmpty == true)
                          Text(
                            p.telefoneCliente!,
                            style: const TextStyle(
                                fontSize: 13, color: _kTextSecondary),
                          ),
                      ],
                    ),
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p.total.toStringAsFixed(2)} MT',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kAccent,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        _formatarData(p.dataPedido),
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Itens do pedido ────────────────────────────────────────
            if (p.itens.isNotEmpty) ...[
              const Divider(height: 1, color: _kCardBorder),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: p.itens
                      .map((item) => _ItemLinha(item: item))
                      .toList(),
                ),
              ),
            ],

            // ── Pagamento ──────────────────────────────────────────────
            const Divider(height: 1, color: _kCardBorder),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 16, color: _kTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Pago: ${p.valorPago.toStringAsFixed(2)} MT',
                    style: const TextStyle(
                        fontSize: 13, color: _kTextSecondary),
                  ),
                  if (p.troco != null && p.troco! > Decimal.zero) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Troco: ${p.troco!.toStringAsFixed(2)} MT',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Botão registar pagamento
                  GestureDetector(
                    onTap: widget.onRegistarPagamento,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _kAccent.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Registar',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Botões de acção ────────────────────────────────────────
            const Divider(height: 1, color: _kCardBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Cancelar
                  Expanded(
                    child: _ActionButton(
                      label: 'Cancelar',
                      icone: Icons.cancel_outlined,
                      cor: _kDanger,
                      onTap: widget.onCancelar,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Finalizar
                  Expanded(
                    flex: 2,
                    child: _ActionButton(
                      label: 'Finalizar pedido',
                      icone: Icons.check_circle_outline_rounded,
                      cor: _kSuccess,
                      filled: true,
                      onTap: widget.onFinalizar,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime dt) {
    final agora = DateTime.now();
    final diff = agora.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ItemLinha extends StatelessWidget {
  final ItemPedidoModel item;
  const _ItemLinha({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantidade}×',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _kAccent),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.nomeProduto ?? 'Produto #${item.idProduto}',
              style:
                  const TextStyle(fontSize: 13, color: _kTextSecondary),
            ),
          ),
          Text(
            item.subtotal != null
                ? '${item.subtotal!.toStringAsFixed(2)} MT'
                : '—',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color cor;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icone,
    required this.cor,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? cor : cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone,
                color: filled ? _kBg : cor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? _kBg : cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet de confirmação de acção ────────────────────────────────────────────

class _AcaoSheet extends StatelessWidget {
  final PedidoModel pedido;
  final bool finalizar;
  final VoidCallback onConfirmar;

  const _AcaoSheet({
    required this.pedido,
    required this.finalizar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = finalizar ? _kSuccess : _kDanger;
    final icone = finalizar
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;
    final titulo = finalizar ? 'Finalizar Pedido' : 'Cancelar Pedido';
    final descricao = finalizar
        ? 'Confirma a finalização do pedido #${pedido.idPedido}?\nEsta acção não pode ser desfeita.'
        : 'Confirma o cancelamento do pedido #${pedido.idPedido}?\nO estoque será reposto automaticamente.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: _kTextSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          // Mini resumo do pedido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pedido.nomeCliente?.isNotEmpty == true
                      ? pedido.nomeCliente!
                      : 'Cliente não identificado',
                  style: const TextStyle(
                      color: _kTextSecondary, fontSize: 13),
                ),
                Text(
                  '${pedido.total.toStringAsFixed(2)} MT',
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: cor,
                foregroundColor: finalizar ? _kBg : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Confirmar — $titulo',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: _kTextSecondary)),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet de pagamento ───────────────────────────────────────────────────────

class _PagamentoSheet extends StatefulWidget {
  final PedidoModel pedido;
  final void Function(Decimal valor) onConfirmar;

  const _PagamentoSheet(
      {required this.pedido, required this.onConfirmar});

  @override
  State<_PagamentoSheet> createState() => _PagamentoSheetState();
}

class _PagamentoSheetState extends State<_PagamentoSheet> {
  final _ctrl = TextEditingController();
  Decimal? _valor;
  bool _valido = false;

  @override
  void initState() {
    super.initState();
    // Pré-preencher com o total
    _ctrl.text = widget.pedido.total.toStringAsFixed(2);
    _valor = widget.pedido.total;
    _valido = true;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChange(String v) {
    try {
      final parsed = Decimal.parse(v.replaceAll(',', '.'));
      setState(() {
        _valor = parsed;
        _valido = parsed >= Decimal.zero;
      });
    } catch (_) {
      setState(() => _valido = false);
    }
  }

  Decimal? get _troco {
    if (_valor == null) return null;
    final diff = _valor! - widget.pedido.total;
    return diff > Decimal.zero ? diff : Decimal.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 28, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registar Pagamento',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pedido #${widget.pedido.idPedido} — Total: ${widget.pedido.total.toStringAsFixed(2)} MT',
            style: const TextStyle(fontSize: 13, color: _kTextSecondary),
          ),
          const SizedBox(height: 20),
          // Campo de valor
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _valido ? _kAccent.withOpacity(0.4) : _kDanger,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: _onChange,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\d,\.]')),
              ],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                prefixText: 'MT  ',
                prefixStyle: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
          ),
          // Troco
          if (_troco != null && _troco! > Decimal.zero) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_exchange_rounded,
                      color: _kSuccess, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Troco: ${_troco!.toStringAsFixed(2)} MT',
                    style: const TextStyle(
                      color: _kSuccess,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_valido && _valor != null)
                  ? () => widget.onConfirmar(_valor!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: _kBg,
                disabledBackgroundColor: _kCardBorder,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Confirmar Pagamento',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyPendentes extends StatelessWidget {
  const _EmptyPendentes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kSuccess.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: _kSuccess, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tudo em dia!',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Não há pedidos pendentes\nneste momento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _kTextSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kCardBorder),
              ),
              child: const Text(
                'Voltar ao menu',
                style: TextStyle(
                    color: _kAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}