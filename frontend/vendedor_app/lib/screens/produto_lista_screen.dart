import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'produto_detalhe_screen.dart';
import 'produto_form_screen.dart';

const _tag = 'ProdutoListaScreen';

class ProdutoListaScreen extends StatefulWidget {
  const ProdutoListaScreen({super.key});

  @override
  State<ProdutoListaScreen> createState() => _ProdutoListaScreenState();
}

class _ProdutoListaScreenState extends State<ProdutoListaScreen> {
@override
void initState() {
  super.initState();
  // Alterado de Env.apiBaseUrl para ApiConfig.baseUrl
  AppLogger.info(_tag, 'initState — baseUrl: ${ApiConfig.baseUrl}'); 
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ProdutoProvider>().carregarProdutos();
  });
}

  Future<void> _confirmarToggleAtivo(
    BuildContext ctx,
    DisponibilidadeProdutoModel produto,
    bool ativar,
  ) async {
    final acao = ativar ? 'ativar' : 'desativar';
    AppLogger.info(_tag, 'Solicitando confirmação para $acao id=${produto.idProduto}');

    final confirmar = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('${ativar ? 'Ativar' : 'Desativar'} produto'),
        content:
            Text('Deseja $acao o produto "${produto.nomeProduto}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ativar
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(ativar ? 'Ativar' : 'Desativar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !ctx.mounted) return;

    final provider = ctx.read<ProdutoProvider>();
    final ok = ativar
        ? await provider.ativarProduto(produto.idProduto)
        : await provider.desativarProduto(produto.idProduto);

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Produto ${ativar ? 'ativado' : 'desativado'} com sucesso'
            : provider.mensagemErro ?? 'Erro ao alterar produto'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Produtos',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar lista',
            onPressed: () {
              AppLogger.info(_tag, 'Atualizar lista manualmente');
              context.read<ProdutoProvider>().carregarProdutos();
            },
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF0)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppLogger.info(_tag, 'Abrir tela de criação de produto');
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ProdutoFormScreen()),
          ).then((_) => context.read<ProdutoProvider>().carregarProdutos());
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
        backgroundColor: const Color(0xFF185FA5),
      ),
      body: Consumer<ProdutoProvider>(
        builder: (ctx, provider, _) {
          if (provider.carregando &&
              provider.produtos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.estado == EstadoCarregamento.erro &&
              provider.produtos.isEmpty) {
            return _ErroWidget(
              mensagem: provider.mensagemErro ?? 'Erro ao carregar produtos',
              onRetry: () => provider.carregarProdutos(),
            );
          }

          final lista = provider.produtos;

          if (lista.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_outlined,
                      size: 64, color: Color(0xFFB5D4F4)),
                  SizedBox(height: 16),
                  Text('Nenhum produto cadastrado',
                      style: TextStyle(
                          color: Color(0xFF888780), fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.carregarProdutos(),
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _ProdutoCard(produto: lista[i], onToggle: _confirmarToggleAtivo),
            ),
          );
        },
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _ProdutoCard extends StatelessWidget {
  final DisponibilidadeProdutoModel produto;
  final Future<void> Function(
          BuildContext, DisponibilidadeProdutoModel, bool) onToggle;

  const _ProdutoCard({required this.produto, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final temEstoque = produto.temEstoque;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFFE8ECF0), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          AppLogger.info('ProdutoCard',
              'Abrir detalhe id=${produto.idProduto}');
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ProdutoDetalheScreen(idProduto: produto.idProduto)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ── Ícone produto ──
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop,
                        color: Color(0xFF185FA5), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produto.nomeProduto,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${produto.capacidadeLitros} L',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888780),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Badge estoque ──
                  _EstoqueBadge(
                    quantidade: produto.quantidadeDisponivel,
                    temEstoque: temEstoque,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE8ECF0)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PrecoChip(
                    label: 'Compra',
                    valor: 'MT ${produto.precoCompra.toStringAsFixed(2)}',
                    cor: const Color(0xFF185FA5),
                  ),
                  const SizedBox(width: 10),
                  _PrecoChip(
                    label: 'Reenchi.',
                    valor: 'MT ${produto.precoReenchimento.toStringAsFixed(2)}',
                    cor: const Color(0xFF0F6E56),
                  ),
                  const Spacer(),
                  // ── Ações rápidas ──
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: Color(0xFF888780)),
                    onPressed: () {
                      AppLogger.info('ProdutoCard',
                          'Abrir edição id=${produto.idProduto}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProdutoFormScreen(
                            idProduto: produto.idProduto,
                          ),
                        ),
                      ).then((_) =>
                          context.read<ProdutoProvider>().carregarProdutos());
                    },
                  ),
                  IconButton(
                    tooltip: temEstoque ? 'Desativar' : 'Ativar',
                    icon: Icon(
                      temEstoque
                          ? Icons.toggle_on_outlined
                          : Icons.toggle_off_outlined,
                      size: 24,
                      color: temEstoque
                          ? const Color(0xFF0F6E56)
                          : const Color(0xFFA32D2D),
                    ),
                    onPressed: () =>
                        onToggle(context, produto, !temEstoque),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstoqueBadge extends StatelessWidget {
  final int quantidade;
  final bool temEstoque;
  const _EstoqueBadge({required this.quantidade, required this.temEstoque});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: temEstoque
            ? const Color(0xFFEAF3DE)
            : const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        temEstoque ? '$quantidade un.' : 'Sem estoque',
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

class _PrecoChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _PrecoChip(
      {required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
        Text(valor,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: cor)),
      ],
    );
  }
}

class _ErroWidget extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _ErroWidget({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: Color(0xFFF09595)),
            const SizedBox(height: 16),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF888780))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}