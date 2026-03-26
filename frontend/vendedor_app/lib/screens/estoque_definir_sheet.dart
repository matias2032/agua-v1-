import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

const int _kIdUsuarioTemp = 1;

class EstoqueDefinirSheet extends StatefulWidget {
  final double valorActual;

  const EstoqueDefinirSheet({super.key, required this.valorActual});

  @override
  State<EstoqueDefinirSheet> createState() => _EstoqueDefinirSheetState();
}

class _EstoqueDefinirSheetState extends State<EstoqueDefinirSheet> {
  final _formKey = GlobalKey<FormState>();
  final _litrosCtrl = TextEditingController();
  final _observacaoCtrl = TextEditingController();
  bool _enviando = false;

  // Preview do delta em tempo real
  double? get _novoValor => double.tryParse(_litrosCtrl.text.trim());
  double get _delta => (_novoValor ?? widget.valorActual) - widget.valorActual;
  bool get _aumentou => _delta > 0;
  bool get _diminuiu => _delta < 0;

  @override
  void initState() {
    super.initState();
    _litrosCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _litrosCtrl.dispose();
    _observacaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Handle ─────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ─── Título ──────────────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.edit_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Definir Valor Directo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Valor actual: ${widget.valorActual.toStringAsFixed(1)} L',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // ─── Campo litros ────────────────────────────────────────
                TextFormField(
                  controller: _litrosCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Novo valor *',
                    hintText: 'Ex: 200.0',
                    prefixIcon: Icon(Icons.water_drop_outlined,
                        color: colorScheme.primary),
                    suffixText: 'L',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o novo valor';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n < 0) {
                      return 'Valor não pode ser negativo';
                    }
                    return null;
                  },
                ),

                // ─── Preview do delta ─────────────────────────────────────
                if (_novoValor != null && _delta != 0) ...[
                  const SizedBox(height: 12),
                  _DeltaChip(delta: _delta, aumentou: _aumentou),
                ],

                const SizedBox(height: 16),

                // ─── Campo observação ────────────────────────────────────
                TextFormField(
                  controller: _observacaoCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex: Correcção de contagem',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Botão confirmar ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(_enviando ? 'A processar…' : 'Confirmar'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _enviando ? null : _confirmar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    final litros = double.parse(_litrosCtrl.text.trim());
    final observacao = _observacaoCtrl.text.trim().isEmpty
        ? null
        : _observacaoCtrl.text.trim();
    final provider = context.read<EstoqueProvider>();

    final sucesso =
        await provider.definir(litros, _kIdUsuarioTemp, observacao: observacao);

    if (!mounted) return;
    setState(() => _enviando = false);

    if (sucesso) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estoque actualizado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.erro ?? 'Erro ao processar'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _DeltaChip extends StatelessWidget {
  final double delta;
  final bool aumentou;

  const _DeltaChip({required this.delta, required this.aumentou});

  @override
  Widget build(BuildContext context) {
    final cor = aumentou ? Colors.green : Colors.orange;
    final icone = aumentou ? Icons.arrow_upward : Icons.arrow_downward;
    final sinal = aumentou ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 4),
          Text(
            '$sinal${delta.toStringAsFixed(1)} L',
            style: TextStyle(
                color: cor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}