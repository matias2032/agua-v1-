import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:api_compartilhado/api_compartilhado.dart';
import 'produto_form_screen.dart';

const _tag = 'ProdutoDetalheScreen';

class ProdutoDetalheScreen extends StatefulWidget {
  final int idProduto;
  const ProdutoDetalheScreen({super.key, required this.idProduto});

  @override
  State<ProdutoDetalheScreen> createState() => _ProdutoDetalheScreenState();
}

class _ProdutoDetalheScreenState extends State<ProdutoDetalheScreen> {
  DisponibilidadeProdutoModel? _produto;
  bool _carregando = true;
  String? _erro;

  OperacaoModel? _operacaoSelecionada;

  @override
  void initState() {
    super.initState();
    AppLogger.info(_tag, 'initState id=${widget.idProduto}');
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    AppLogger.info(_tag, 'Carregando detalhe id=${widget.idProduto}');
    try {
      final produto =
          await ProdutoService.instance.buscarPorId(widget.idProduto);
      AppLogger.info(_tag, 'Detalhe carregado: ${produto.nomeProduto}');
      if (mounted) {
        setState(() => _produto = produto);
        // carrega operações para o calculador de preço
        await context.read<ProdutoProvider>().carregarOperacoes();
      }
    } catch (e) {
      AppLogger.error(_tag, 'Erro ao carregar detalhe', e);
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _calcularPreco() async {
    if (_operacaoSelecionada == null) return;
    AppLogger.info(_tag,
        'Calcular preço produto=${widget.idProduto} operacao=${_operacaoSelecionada!.idOperacao}');
    await context.read<ProdutoProvider>().calcularPreco(
          idProduto: widget.idProduto,
          idOperacao: _operacaoSelecionada!.idOperacao,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _produto?.nomeProduto ?? 'Produto',
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          if (_produto != null)
            IconButton(
              tooltip: 'Editar produto',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                AppLogger.info(_tag, 'Navegar para edição id=${widget.idProduto}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProdutoFormScreen(idProduto: widget.idProduto),
                  ),
                ).then((_) => _carregar());
              },
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF0)),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Text(_erro!,
                      style: const TextStyle(color: Colors.red)))
              : _produto == null
                  ? const Center(child: Text('Produto não encontrado'))
                  : _Corpo(
                      produto: _produto!,
                      operacaoSelecionada: _operacaoSelecionada,
                      onOperacaoChanged: (op) {
                        setState(() => _operacaoSelecionada = op);
                        AppLogger.debug(
                            _tag, 'Operação selecionada: ${op?.nomeOperacao}');
                      },
                      onCalcular: _calcularPreco,
                    ),
    );
  }
}

// ── Corpo ─────────────────────────────────────────────────────────────────────

class _Corpo extends StatelessWidget {
  final DisponibilidadeProdutoModel produto;
  final OperacaoModel? operacaoSelecionada;
  final ValueChanged<OperacaoModel?> onOperacaoChanged;
  final VoidCallback onCalcular;

  const _Corpo({
    required this.produto,
    required this.operacaoSelecionada,
    required this.onOperacaoChanged,
    required this.onCalcular,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card ─────────────────────────────────────────────────────
          _CardInfo(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1FB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.water_drop,
                          color: Color(0xFF185FA5), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(produto.nomeProduto,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E))),
                          Text('${produto.capacidadeLitros} litros',
                              style: const TextStyle(
                                  color: Color(0xFF888780), fontSize: 14)),
                        ],
                      ),
                    ),
                    _StatusBadge(temEstoque: produto.temEstoque),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFE8ECF0)),
                const SizedBox(height: 16),
                // ── Métricas ──
                Row(
                  children: [
                    _Metrica(
                        label: 'Disponível',
                        valor: '${produto.quantidadeDisponivel} un.',
                        cor: produto.temEstoque
                            ? const Color(0xFF3B6D11)
                            : const Color(0xFFA32D2D)),
                    _Divisor(),
                    _Metrica(
                        label: 'Litros no estoque',
                        valor:
                            '${produto.litrosDisponiveis.toStringAsFixed(1)} L',
                        cor: const Color(0xFF185FA5)),
                    _Divisor(),
                    _Metrica(
                        label: 'Preço compra',
                        valor:
                            'MT ${produto.precoCompra.toStringAsFixed(2)}',
                        cor: const Color(0xFF2C2C2A)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  _Metrica(
                      label: 'Reenchimento',
                      valor:
                          'MT ${produto.precoReenchimento.toStringAsFixed(2)}',
                      cor: const Color(0xFF0F6E56)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Calculador de preço ──────────────────────────────────────────
          _CardInfo(
            child: Consumer<ProdutoProvider>(
              builder: (ctx, provider, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_outlined,
                          color: Color(0xFF185FA5), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Simulador de preço',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<OperacaoModel>(
                    value: operacaoSelecionada,
                    hint: const Text('Selecione a operação'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF6F8FB),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFD3D1C7)),
                      ),
                    ),
                    items: provider.operacoes
                        .map((op) => DropdownMenuItem(
                              value: op,
                              child: Text(op.nomeOperacao),
                            ))
                        .toList(),
                    onChanged: (v) => onOperacaoChanged(v),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: operacaoSelecionada == null || provider.carregando
                        ? null
                        : onCalcular,
                    icon: const Icon(Icons.price_check, size: 18),
                    label: const Text('Calcular preço'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6E56),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (provider.precoCalculado != null) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE8ECF0)),
                    const SizedBox(height: 14),
                    _ResultadoPreco(provider: provider),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoPreco extends StatelessWidget {
  final ProdutoProvider provider;
  const _ResultadoPreco({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider.precoCalculado!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resultado',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888780),
                letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Row(
          children: [
            _Metrica(
                label: 'Preço base',
                valor: 'MT ${p.precoBase.toStringAsFixed(2)}',
                cor: const Color(0xFF444441)),
            _Divisor(),
            _Metrica(
                label: 'Fator',
                valor: '×${p.fatorPreco}',
                cor: const Color(0xFF888780)),
            _Divisor(),
            _Metrica(
                label: 'Preço final',
                valor: 'MT ${p.precoFinal.toStringAsFixed(2)}',
                cor: const Color(0xFF185FA5)),
          ],
        ),
        const SizedBox(height: 4),
        Text(p.nomeOperacao,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF888780))),
      ],
    );
  }
}

// ── Widgets utilitários ───────────────────────────────────────────────────────

class _CardInfo extends StatelessWidget {
  final Widget child;
  const _CardInfo({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: child,
    );
  }
}

class _Metrica extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _Metrica(
      {required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF888780))),
          const SizedBox(height: 2),
          Text(valor,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cor)),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 32, color: const Color(0xFFE8ECF0));
  }
}

class _StatusBadge extends StatelessWidget {
  final bool temEstoque;
  const _StatusBadge({required this.temEstoque});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: temEstoque
            ? const Color(0xFFEAF3DE)
            : const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        temEstoque ? 'Disponível' : 'Indisponível',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: temEstoque
              ? const Color(0xFF3B6D11)
              : const Color(0xFFA32D2D),
        ),
      ),
    );
  }
}