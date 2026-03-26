import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


class EstoqueAjusteSheet extends StatefulWidget {
  /// 'adicionar' ou 'remover'
  final String tipo;

  const EstoqueAjusteSheet({super.key, required this.tipo});

  @override
  State<EstoqueAjusteSheet> createState() => _EstoqueAjusteSheetState();
}

class _EstoqueAjusteSheetState extends State<EstoqueAjusteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _litrosCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  bool _enviando = false;

  bool get _isAdicionar => widget.tipo == 'adicionar';

  @override
  void dispose() {
    _litrosCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cor = _isAdicionar ? Colors.green : Colors.orange;
    final icone =
        _isAdicionar ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final titulo = _isAdicionar ? 'Adicionar Litros' : 'Remover Litros';

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
                // ─── Handle + Título ────────────────────────────────────
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
                Row(
                  children: [
                    Icon(icone, color: cor),
                    const SizedBox(width: 8),
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
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
                    labelText: 'Litros *',
                    hintText: 'Ex: 50.5',
                    prefixIcon: Icon(Icons.water_drop_outlined, color: cor),
                    suffixText: 'L',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe a quantidade de litros';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return 'Valor deve ser maior que 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Campo motivo ────────────────────────────────────────
                TextFormField(
                  controller: _motivoCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (opcional)',
                    hintText: 'Ex: Reposição semanal',
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
                        : Icon(icone),
                    label: Text(_enviando ? 'A processar…' : titulo),
                    style: FilledButton.styleFrom(
                      backgroundColor: cor,
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

    final idUsuario = SessaoService.instance.idUsuario;

    if (idUsuario == null) {
      setState(() => _enviando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Faça login novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final litros = double.parse(_litrosCtrl.text.trim());
    final motivo =
        _motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim();
    final provider = context.read<EstoqueProvider>();

    final bool sucesso = _isAdicionar
        ? await provider.adicionar(litros, idUsuario, motivo: motivo)
        : await provider.remover(litros, idUsuario, motivo: motivo);

    if (!mounted) return;
    setState(() => _enviando = false);

    if (sucesso) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAdicionar
              ? '${litros.toStringAsFixed(1)} L adicionados com sucesso'
              : '${litros.toStringAsFixed(1)} L removidos com sucesso'),
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