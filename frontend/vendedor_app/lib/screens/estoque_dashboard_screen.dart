import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

import 'estoque_ajuste_sheet.dart';
import 'estoque_definir_sheet.dart';
import 'movimentos_estoque_screen.dart';

class EstoqueDashboardScreen extends StatefulWidget {
  const EstoqueDashboardScreen({super.key});

  @override
  State<EstoqueDashboardScreen> createState() => _EstoqueDashboardScreenState();
}

class _EstoqueDashboardScreenState extends State<EstoqueDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstoqueProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque de Água'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Movimentos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MovimentosEstoqueScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => context.read<EstoqueProvider>().carregar(),
          ),
        ],
      ),
      body: Consumer<EstoqueProvider>(
        builder: (context, provider, _) {
          if (provider.carregando && provider.estoque == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.estado == EstadoEstoque.erro && provider.estoque == null) {
            return _ErroView(
              mensagem: provider.erro ?? 'Erro desconhecido',
              onRetry: () => provider.carregar(),
            );
          }

          final estoque = provider.estoque;
          if (estoque == null) {
            return const Center(child: Text('Sem dados de estoque.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.carregar(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Card principal ──────────────────────────────────────
                _CardEstoque(estoque: estoque, carregando: provider.carregando),

                const SizedBox(height: 24),

                // ─── Acções ──────────────────────────────────────────────
                Text(
                  'Acções',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),

                _BotaoAcao(
                  icone: Icons.add_circle_outline,
                  label: 'Adicionar Litros',
                  cor: Colors.green,
                  onTap: () => _abrirAjuste(context, tipo: 'adicionar'),
                ),
                const SizedBox(height: 10),
                _BotaoAcao(
                  icone: Icons.remove_circle_outline,
                  label: 'Remover Litros',
                  cor: Colors.orange,
                  onTap: () => _abrirAjuste(context, tipo: 'remover'),
                ),
                const SizedBox(height: 10),
                _BotaoAcao(
                  icone: Icons.edit_outlined,
                  label: 'Definir Valor Directo',
                  cor: colorScheme.primary,
                  onTap: () => _abrirDefinir(context, estoque: estoque),
                ),
                const SizedBox(height: 10),
                _BotaoAcao(
                  icone: Icons.list_alt_outlined,
                  label: 'Ver Movimentos',
                  cor: colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MovimentosEstoqueScreen(),
                    ),
                  ),
                ),

                // ─── Observação ──────────────────────────────────────────
                if (estoque.observacao != null &&
                    estoque.observacao!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CardObservacao(observacao: estoque.observacao!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _abrirAjuste(BuildContext context, {required String tipo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EstoqueAjusteSheet(tipo: tipo),
    );
  }

  void _abrirDefinir(BuildContext context, {required EstoqueModel estoque}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EstoqueDefinirSheet(valorActual: estoque.litrosDisponiveis),
    );
  }
}

// ─── Widgets internos ──────────────────────────────────────────────────────────

class _CardEstoque extends StatelessWidget {
  final EstoqueModel estoque;
  final bool carregando;

  const _CardEstoque({required this.estoque, required this.carregando});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Litros Disponíveis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: carregando
                  ? const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '${estoque.litrosDisponiveis.toStringAsFixed(1)} L',
                      key: ValueKey(estoque.litrosDisponiveis),
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
            ),
            if (estoque.ultimaAtualizacao != null) ...[
              const SizedBox(height: 12),
              Text(
                'Actualizado em ${_formatarData(estoque.ultimaAtualizacao!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _BotaoAcao extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color cor;
  final VoidCallback onTap;

  const _BotaoAcao({
    required this.icone,
    required this.label,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icone, color: cor),
        title: Text(label),
        trailing: Icon(Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}

class _CardObservacao extends StatelessWidget {
  final String observacao;

  const _CardObservacao({required this.observacao});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                observacao,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;

  const _ErroView({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}