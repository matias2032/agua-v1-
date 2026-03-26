import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class MovimentosEstoqueScreen extends StatefulWidget {
  const MovimentosEstoqueScreen({super.key});

  @override
  State<MovimentosEstoqueScreen> createState() =>
      _MovimentosEstoqueScreenState();
}

class _MovimentosEstoqueScreenState extends State<MovimentosEstoqueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<EstoqueProvider>();
      p.carregarTodos();
      p.carregarManuais();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimentos de Estoque'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Manuais'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ListaMovimentos(modo: _ModoLista.todos),
          _ListaMovimentos(modo: _ModoLista.manuais),
        ],
      ),
    );
  }
}

// ─── Modo de listagem ──────────────────────────────────────────────────────────

enum _ModoLista { todos, manuais }

// ─── Lista de movimentos ───────────────────────────────────────────────────────

class _ListaMovimentos extends StatelessWidget {
  final _ModoLista modo;

  const _ListaMovimentos({required this.modo});

  @override
  Widget build(BuildContext context) {
    return Consumer<EstoqueProvider>(
      builder: (context, provider, _) {
        final pagina =
            modo == _ModoLista.todos ? provider.paginaTodos : provider.paginaManuais;

        if (provider.carregando && pagina == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.estado == EstadoEstoque.erro && pagina == null) {
          return _ErroView(
            mensagem: provider.erro ?? 'Erro desconhecido',
            onRetry: () => modo == _ModoLista.todos
                ? provider.carregarTodos()
                : provider.carregarManuais(),
          );
        }

        final movimentos = pagina?.conteudo ?? [];

        if (movimentos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Nenhum movimento encontrado',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => modo == _ModoLista.todos
              ? provider.carregarTodos()
              : provider.carregarManuais(),
          child: Column(
            children: [
              // ─── Contador ───────────────────────────────────────────
              if (pagina != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${pagina.totalElementos} movimentos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const Spacer(),
                      if (provider.carregando)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),

              // ─── Lista ──────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: movimentos.length +
                      (pagina != null && pagina.temProxima ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == movimentos.length) {
                      // ─── Botão carregar mais ──────────────────────
                      return _BotaoCarregarMais(
                        onTap: () {
                          final proximaPagina =
                              (pagina?.paginaActual ?? 0) + 1;
                          if (modo == _ModoLista.todos) {
                            provider.carregarTodos(page: proximaPagina);
                          } else {
                            provider.carregarManuais(page: proximaPagina);
                          }
                        },
                      );
                    }
                    return _CardMovimento(movimento: movimentos[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Card de um movimento ─────────────────────────────────────────────────────

class _CardMovimento extends StatelessWidget {
  final MovimentoEstoqueModel movimento;

  const _CardMovimento({required this.movimento});

  @override
  Widget build(BuildContext context) {
    final isEntrada = movimento.isEntrada;
    final cor = isEntrada ? Colors.green : Colors.orange;
    final icone = isEntrada ? Icons.arrow_upward : Icons.arrow_downward;
    final sinal = isEntrada ? '+' : '-';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Ícone de tipo ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icone, color: cor, size: 20),
            ),
            const SizedBox(width: 12),

            // ─── Conteúdo ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Litros movimentados + badge manual
                  Row(
                    children: [
                      Text(
                        '$sinal${movimento.litrosMovimentados.toStringAsFixed(1)} L',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: cor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (movimento.manual)
                        _Badge(label: 'Manual', cor: colorScheme.secondary),
                      if (!movimento.manual && movimento.idPedido != null)
                        _Badge(
                          label: 'Pedido #${movimento.idPedido}',
                          cor: colorScheme.tertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Saldo anterior → novo
                  Text(
                    '${movimento.litrosAnterior.toStringAsFixed(1)} L  →  ${movimento.litrosNovo.toStringAsFixed(1)} L',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),

                  // Motivo / observação
                  if (movimento.motivo != null &&
                      movimento.motivo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      movimento.motivo!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 6),
                  Text(
                    _formatarData(movimento.dataMovimento),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),

            // ─── Utilizador ─────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: colorScheme.outline),
                Text(
                  '#${movimento.idUsuario}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color cor;

  const _Badge({required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BotaoCarregarMais extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoCarregarMais({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.expand_more),
          label: const Text('Carregar mais'),
          onPressed: onTap,
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
            Text(mensagem,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
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