import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:api_compartilhado/api_compartilhado.dart';

const _tag = 'ProdutoFormScreen';

class ProdutoFormScreen extends StatefulWidget {
  /// Null = criação, não-null = edição.
  final int? idProduto;

  const ProdutoFormScreen({super.key, this.idProduto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precoCompraCtrl = TextEditingController();
  final _precoReenchCtrl = TextEditingController();
  final _capacidadeCtrl = TextEditingController();

  bool _carregandoInicial = false;

  bool get _editando => widget.idProduto != null;

  @override
  void initState() {
    super.initState();
    AppLogger.info(_tag,
        'initState — ${_editando ? "edição id=${widget.idProduto}" : "criação"}');
    if (_editando) _carregarProdutoExistente();
  }

  Future<void> _carregarProdutoExistente() async {
    setState(() => _carregandoInicial = true);
    AppLogger.info(_tag, 'Carregando produto id=${widget.idProduto} para edição');
    try {
      final p =
          await ProdutoService.instance.buscarPorId(widget.idProduto!);
      _nomeCtrl.text = p.nomeProduto;
      _precoCompraCtrl.text = p.precoCompra.toStringAsFixed(2);
      _precoReenchCtrl.text = p.precoReenchimento.toStringAsFixed(2);
      _capacidadeCtrl.text = p.capacidadeLitros.toStringAsFixed(3);
      AppLogger.info(_tag, 'Formulário preenchido: ${p.nomeProduto}');
    } catch (e) {
      AppLogger.error(_tag, 'Falha ao carregar produto para edição', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao carregar produto: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _carregandoInicial = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.warn(_tag, 'Formulário inválido — salvar cancelado');
      return;
    }

    final request = ProdutoRequest(
      nomeProduto: _nomeCtrl.text.trim(),
      descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      precoCompra: Decimal.parse(_precoCompraCtrl.text.replaceAll(',', '.')),
      precoReenchimento:
          Decimal.parse(_precoReenchCtrl.text.replaceAll(',', '.')),
      capacidadeLitros:
          Decimal.parse(_capacidadeCtrl.text.replaceAll(',', '.')),
    );

    AppLogger.info(_tag, 'Enviando ${_editando ? "PUT" : "POST"} — ${request.nomeProduto}');

    final provider = context.read<ProdutoProvider>();
    final ok = _editando
        ? await provider.atualizarProduto(widget.idProduto!, request)
        : await provider.criarProduto(request);

    if (!mounted) return;

    if (ok) {
      AppLogger.info(_tag, 'Produto salvo com sucesso');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Produto salvo com sucesso!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } else {
      AppLogger.warn(_tag, 'Falha ao salvar: ${provider.mensagemErro}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.mensagemErro ?? 'Erro ao salvar produto'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _precoCompraCtrl.dispose();
    _precoReenchCtrl.dispose();
    _capacidadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _editando ? 'Editar produto' : 'Novo produto',
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1A1A2E),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF0)),
        ),
      ),
      body: _carregandoInicial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Secao(titulo: 'Identificação'),
                    const SizedBox(height: 12),
                    _Campo(
                      label: 'Nome do produto *',
                      controller: _nomeCtrl,
                      hint: 'Ex.: Galão 6L',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Nome obrigatório'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    _Campo(
                      label: 'Descrição',
                      controller: _descCtrl,
                      hint: 'Opcional',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _Secao(titulo: 'Preços (MT)'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _Campo(
                          label: 'Preço de compra *',
                          controller: _precoCompraCtrl,
                          hint: '50.00',
                          keyboard: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]'))
                          ],
                          validator: _validarDecimal,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _Campo(
                          label: 'Preço reenchimento *',
                          controller: _precoReenchCtrl,
                          hint: '35.00',
                          keyboard: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]'))
                          ],
                          validator: _validarDecimal,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _Secao(titulo: 'Volume'),
                    const SizedBox(height: 12),
                    _Campo(
                      label: 'Capacidade (litros) *',
                      controller: _capacidadeCtrl,
                      hint: '6.000',
                      keyboard: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                      ],
                      validator: _validarDecimal,
                    ),
                    const SizedBox(height: 32),
                    Consumer<ProdutoProvider>(
                      builder: (_, provider, __) => FilledButton(
                        onPressed:
                            provider.carregando ? null : _salvar,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF185FA5),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: provider.carregando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white))
                            : Text(
                                _editando ? 'Salvar alterações' : 'Criar produto',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _validarDecimal(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
    final normalizado = v.replaceAll(',', '.');
    final n = double.tryParse(normalizado);
    if (n == null || n <= 0) return 'Valor inválido';
    return null;
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _Secao extends StatelessWidget {
  final String titulo;
  const _Secao({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF185FA5),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Campo({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF444441))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFFB4B2A9), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD3D1C7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFD3D1C7), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF185FA5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}