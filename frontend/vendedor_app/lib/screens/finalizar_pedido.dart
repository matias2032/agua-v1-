import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:decimal/decimal.dart';

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

// ─── Tipos de pagamento ───────────────────────────────────────────────────────

class _TipoPagamento {
  final int id;
  final String nome;
  final IconData icone;
  final Color cor;
  const _TipoPagamento({required this.id, required this.nome,
      required this.icone, required this.cor});
}

const _kMetodos = [
  _TipoPagamento(id: 1, nome: 'Dinheiro em espécie',
      icone: Icons.payments_rounded, cor: _kSuccess),
  _TipoPagamento(id: 2, nome: 'POS',
      icone: Icons.credit_card_rounded, cor: _kAccent),
  _TipoPagamento(id: 3, nome: 'M-Pesa',
      icone: Icons.phone_android_rounded, cor: Color(0xFFFF3D3D)),
  _TipoPagamento(id: 4, nome: 'E-Mola',
      icone: Icons.account_balance_wallet_rounded, cor: Color(0xFFFF8C00)),
];

// ─── Tela principal ───────────────────────────────────────────────────────────

class FinalizarPedidoScreen extends StatefulWidget {
  final PedidoModel pedido;
  const FinalizarPedidoScreen({super.key, required this.pedido});

  @override
  State<FinalizarPedidoScreen> createState() => _FinalizarPedidoScreenState();
}

class _FinalizarPedidoScreenState extends State<FinalizarPedidoScreen>
    with TickerProviderStateMixin {

  // ── Estado ──────────────────────────────────────────────────────────────
  _TipoPagamento? _metodo;
  bool _finalizando = false;

  // Para dinheiro em espécie
  final _dinheiroPagoCtrl = TextEditingController();
  Decimal _dinheiroPago   = Decimal.zero;
  bool _dinheiroValido    = false;

  // ── Animações ────────────────────────────────────────────────────────────
  late final AnimationController _entradaCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _pulseAnim;

  bool get _ehDinheiro => _metodo?.id == 1;

  bool get _podeFinalizarr =>
      _metodo != null &&
      !_finalizando &&
      (!_ehDinheiro || _dinheiroValido);

  Decimal get _troco {
    if (!_ehDinheiro || !_dinheiroValido) return Decimal.zero;
    final diff = _dinheiroPago - widget.pedido.total;
    return diff > Decimal.zero ? diff : Decimal.zero;
  }

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..repeat(reverse: true);

    _fadeAnim  = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entradaCtrl, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.035)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _pulseCtrl.dispose();
    _dinheiroPagoCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ───────────────────────────────────────────────────────────────

  void _onDinheiroPagoChanged(String v) {
    try {
      final parsed = Decimal.parse(v.replaceAll(',', '.'));
      setState(() {
        _dinheiroPago   = parsed;
        _dinheiroValido = parsed >= widget.pedido.total;
      });
    } catch (_) {
      setState(() {
        _dinheiroPago   = Decimal.zero;
        _dinheiroValido = false;
      });
    }
  }

  void _onMetodoTap(_TipoPagamento m) {
    HapticFeedback.selectionClick();
    setState(() {
      _metodo = m;
      if (m.id != 1) {
        _dinheiroPagoCtrl.clear();
        _dinheiroPago   = Decimal.zero;
        _dinheiroValido = false;
      }
    });
  }

  Future<void> _finalizar() async {
    if (!_podeFinalizarr) return;
    HapticFeedback.mediumImpact();
    setState(() => _finalizando = true);

    final prov = context.read<PedidoProvider>();

    if (_ehDinheiro && _dinheiroPago > Decimal.zero) {
      await prov.actualizarValorPago(
        widget.pedido.idPedido,
        ValorPagoRequest(valorPago: _dinheiroPago),
      );
    }

    final ok = await prov.finalizar(widget.pedido.idPedido);

    if (!mounted) return;
    setState(() => _finalizando = false);

    if (ok) {
      HapticFeedback.heavyImpact();
      await _mostrarSucesso();
    } else {
      _showSnack(prov.erro ?? 'Erro ao finalizar o pedido', _kDanger);
    }
  }

  Future<void> _mostrarSucesso() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: _kBg.withOpacity(0.88),
      builder: (_) => _SucessoDialog(
        pedido: widget.pedido,
        metodo: _metodo!,
        troco: _troco,
        onContinuar: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(true);
        },
      ),
    );
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _buildResumoPedido(),
                          const SizedBox(height: 24),
                          _buildSeccaoMetodos(),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            child: _ehDinheiro
                                ? _buildCamposDinheiro()
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 28),
                          _buildBotaoFinalizar(),
                          const SizedBox(height: 10),
                          _buildBotaoVoltar(),
                        ],
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
              const Text('Finalizar Pedido',
                  style: TextStyle(fontFamily: 'Georgia', fontSize: 20,
                      fontWeight: FontWeight.w700, color: _kTextPrimary,
                      letterSpacing: -0.4)),
              Text('Pedido #${widget.pedido.idPedido}',
                  style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Resumo ────────────────────────────────────────────────────────────────

  Widget _buildResumoPedido() {
    final p = widget.pedido;
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: _kAccent, size: 17),
                const SizedBox(width: 8),
                const Text('Resumo do pedido',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kWarning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text('PENDENTE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                          color: _kWarning, letterSpacing: 0.8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kCardBorder),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: _kAccent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nomeCliente?.isNotEmpty == true
                            ? p.nomeCliente!
                            : 'Cliente não identificado',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: _kTextPrimary),
                      ),
                      if (p.telefoneCliente?.isNotEmpty == true)
                        Text(p.telefoneCliente!,
                            style: const TextStyle(
                                fontSize: 12, color: _kTextSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (p.itens.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: _kCardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Column(
                children: p.itens.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('${item.quantidade}×',
                              style: const TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w800, color: _kAccent)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.nomeProduto ?? 'Produto #${item.idProduto}',
                            style: const TextStyle(
                                fontSize: 13, color: _kTextSecondary)),
                      ),
                      Text(
                        item.subtotal != null
                            ? '${item.subtotal!.toStringAsFixed(2)} MT'
                            : '—',
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600, color: _kTextPrimary),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],

          const Divider(height: 1, color: _kCardBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: _kTextSecondary)),
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Text('${p.total.toStringAsFixed(2)} MT',
                      style: const TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w800, color: _kAccent,
                          letterSpacing: -0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chips de método ───────────────────────────────────────────────────────

  Widget _buildSeccaoMetodos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Método de pagamento',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: _kTextPrimary, letterSpacing: -0.3)),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _metodo == null
                  ? _Pill('Obrigatório', _kDanger, key: const ValueKey('ob'))
                  : _Pill('Seleccionado', _kSuccess, key: const ValueKey('ok')),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Text('Escolha como o cliente vai efectuar o pagamento',
            style: TextStyle(fontSize: 12, color: _kTextSecondary)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _kMetodos.map((m) => _MetodoChip(
            metodo: m,
            seleccionado: _metodo?.id == m.id,
            onTap: () => _onMetodoTap(m),
          )).toList(),
        ),
      ],
    );
  }

  // ── Campos dinheiro ───────────────────────────────────────────────────────

  Widget _buildCamposDinheiro() {
    final total = widget.pedido.total;
    final temValor = _dinheiroPago > Decimal.zero;
    final falta    = temValor && !_dinheiroValido;
    final inputCor = temValor ? (_dinheiroValido ? _kSuccess : _kDanger) : _kCardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Text('Dinheiro recebido',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: _kTextSecondary)),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: inputCor, width: 1.5),
          ),
          child: TextField(
            controller: _dinheiroPagoCtrl,
            onChanged: _onDinheiroPagoChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
            ],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                color: _kTextPrimary, letterSpacing: -0.4),
            decoration: const InputDecoration(
              prefixText: 'MT  ',
              prefixStyle: TextStyle(color: _kTextSecondary,
                  fontSize: 15, fontWeight: FontWeight.w500),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        // Aviso: valor insuficiente
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: falta
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kDanger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kDanger.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: _kDanger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Faltam ${(total - _dinheiroPago).toStringAsFixed(2)} MT. '
                            'O valor recebido tem de ser igual ou superior ao total.',
                            style: const TextStyle(fontSize: 12,
                                color: _kDanger, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Troco
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: (_dinheiroValido && _troco > Decimal.zero)
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kSuccess.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kSuccess.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_exchange_rounded,
                            color: _kSuccess, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Troco a devolver: ${_troco.toStringAsFixed(2)} MT',
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: _kSuccess),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Botão finalizar ───────────────────────────────────────────────────────

  Widget _buildBotaoFinalizar() {
    final activo = _podeFinalizarr;

    // Mensagem de hint quando inactivo
    String hint = 'Seleccione um método de pagamento';
    if (_metodo != null && !activo) {
      hint = _dinheiroPago == Decimal.zero
          ? 'Insira o valor recebido em dinheiro'
          : 'O valor recebido é insuficiente';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: activo
            ? const LinearGradient(
                colors: [_kSuccess, Color(0xFF00B87A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: activo ? null : _kCardBorder,
        boxShadow: activo
            ? [BoxShadow(color: _kSuccess.withOpacity(0.32),
                blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: activo ? _finalizar : null,
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: _finalizando
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: _kBg, strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: activo ? _kBg : _kTextSecondary, size: 19),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          activo ? 'Finalizar — ${_metodo!.nome}' : hint,
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: activo ? _kBg : _kTextSecondary,
                              letterSpacing: -0.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoVoltar() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Voltar sem finalizar',
            style: TextStyle(color: _kTextSecondary, fontSize: 14)),
      ),
    );
  }
}

// ─── Chip compacto de método ──────────────────────────────────────────────────

class _MetodoChip extends StatelessWidget {
  final _TipoPagamento metodo;
  final bool seleccionado;
  final VoidCallback onTap;

  const _MetodoChip({required this.metodo, required this.seleccionado,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? metodo.cor.withOpacity(0.12) : _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? metodo.cor.withOpacity(0.65) : _kCardBorder,
            width: seleccionado ? 1.6 : 1,
          ),
          boxShadow: seleccionado
              ? [BoxShadow(color: metodo.cor.withOpacity(0.18),
                  blurRadius: 12, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(metodo.icone,
                color: seleccionado ? metodo.cor : _kTextSecondary, size: 16),
            const SizedBox(width: 7),
            Text(metodo.nome,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: seleccionado ? metodo.cor : _kTextSecondary)),
            if (seleccionado) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, color: metodo.cor, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Pill de estado ───────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String texto;
  final Color cor;
  const _Pill(this.texto, this.cor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(texto,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: cor)),
    );
  }
}

// ─── Diálogo de sucesso ───────────────────────────────────────────────────────

class _SucessoDialog extends StatefulWidget {
  final PedidoModel pedido;
  final _TipoPagamento metodo;
  final Decimal troco;
  final VoidCallback onContinuar;

  const _SucessoDialog({required this.pedido, required this.metodo,
      required this.troco, required this.onContinuar});

  @override
  State<_SucessoDialog> createState() => _SucessoDialogState();
}

class _SucessoDialogState extends State<_SucessoDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    return Dialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: _kSuccess.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _kSuccess.withOpacity(0.28),
                        blurRadius: 20, spreadRadius: 3)],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: _kSuccess, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Pedido Finalizado!',
                  style: TextStyle(fontFamily: 'Georgia', fontSize: 21,
                      fontWeight: FontWeight.w700, color: _kTextPrimary,
                      letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text('Pedido #${p.idPedido} concluído com sucesso.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13,
                      color: _kTextSecondary, height: 1.5)),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    _LinhaResumo(
                      rotulo: 'Cliente',
                      valor: p.nomeCliente?.isNotEmpty == true
                          ? p.nomeCliente! : 'Não identificado',
                    ),
                    const SizedBox(height: 7),
                    _LinhaResumo(rotulo: 'Total',
                        valor: '${p.total.toStringAsFixed(2)} MT',
                        corValor: _kAccent),
                    const SizedBox(height: 7),
                    _LinhaResumo(rotulo: 'Pagamento',
                        valor: widget.metodo.nome,
                        icone: widget.metodo.icone,
                        corValor: widget.metodo.cor),
                    if (widget.troco > Decimal.zero) ...[
                      const SizedBox(height: 7),
                      _LinhaResumo(rotulo: 'Troco',
                          valor: '${widget.troco.toStringAsFixed(2)} MT',
                          corValor: _kSuccess,
                          icone: Icons.currency_exchange_rounded),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: widget.onContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kSuccess, foregroundColor: _kBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  child: const Text('Continuar',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color? corValor;
  final IconData? icone;

  const _LinhaResumo({required this.rotulo, required this.valor,
      this.corValor, this.icone});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(rotulo, style: const TextStyle(
            fontSize: 13, color: _kTextSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 13, color: corValor ?? _kTextPrimary),
              const SizedBox(width: 4),
            ],
            Text(valor, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700,
                color: corValor ?? _kTextPrimary)),
          ],
        ),
      ],
    );
  }
}