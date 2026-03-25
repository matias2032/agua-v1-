// lib/screens/detalhes_usuario.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class DetalhesUsuarioScreen extends StatefulWidget {
  final int usuarioId;
  const DetalhesUsuarioScreen({required this.usuarioId, super.key});

  @override
  State<DetalhesUsuarioScreen> createState() => _DetalhesUsuarioScreenState();
}

class _DetalhesUsuarioScreenState extends State<DetalhesUsuarioScreen> {
  final UsuarioService _service = UsuarioService();
  late Future<UsuarioModel?> _usuarioFuture;

  // ---------------------------------------------------------------------------
  // CICLO DE VIDA
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  

  // ---------------------------------------------------------------------------
  // CARREGAMENTO
  // ---------------------------------------------------------------------------

  void _loadUsuario() {
    setState(() {
      _usuarioFuture = _service.buscarPorId(widget.usuarioId);
    });
  }

  // ---------------------------------------------------------------------------
  // AÇÕES
  // ---------------------------------------------------------------------------

  Future<void> _toggleAfastamento(UsuarioModel usuario) async {
    final bool isAtivo  = usuario.ativo;
    final String acao   = isAtivo ? 'Afastar' : 'Reativar';
    final String status = isAtivo ? 'Inativo' : 'Ativo';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$acao Funcionário'),
        content: Text(
          'Tem certeza que deseja $acao ${usuario.nome}?\n'
          'O status mudará para "$status".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAtivo ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(acao),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.toggleStatus(usuario.idUsuario);
      _loadUsuario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${usuario.nome} foi marcado como $status.'),
          backgroundColor: isAtivo ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reiniciarSenha(UsuarioModel usuario) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Colors.orange),
            SizedBox(width: 10),
            Text('Reiniciar Senha'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja reiniciar a senha de ${usuario.nome}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Atenção:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• A senha será redefinida para: 12345678'),
                  Text('• O usuário deverá alterar a senha no próximo login'),
                  Text('• Esta ação não pode ser desfeita'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reiniciar Senha'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Exibe loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
    await _service.resetarSenha(widget.usuarioId);

      if (mounted) Navigator.of(context).pop(); // fecha loading

      _loadUsuario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Text('✅ Senha de ${usuario.nome} reiniciada!\nNova senha: 12345678'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
  
      if (mounted) Navigator.of(context).pop(); // fecha loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _getPerfilNome(UsuarioModel u) {
  switch (u.idPerfil) {
    case 1: return 'Administrador';
    case 2: return 'Gerente';
    case 3: return 'Funcionário';
    case 4: return 'Vendedor';
    default: return 'Sem perfil';
  }
}
  String _formatarDataHora(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} às '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Usuário'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UsuarioModel?>(
        future: _usuarioFuture,
        builder: (context, snapshot) {
          // ── Loading ────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Erro ───────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar usuário'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadUsuario,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          // ── Não encontrado ─────────────────────────────────────────────────
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Usuário não encontrado.'));
          }

          final usuario = snapshot.data!;
          final isAtivo = usuario.ativo;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. IDENTIFICAÇÃO ─────────────────────────────────────────
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          isAtivo ? Colors.deepOrange : Colors.grey,
                      child: Text(
                        usuario.nome[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      usuario.nome,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _getPerfilNome(usuario),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Chip(
                      label: Text(
                        isAtivo ? 'Ativo' : 'Inativo',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: isAtivo ? Colors.green : Colors.red,
                      avatar: Icon(
                        isAtivo ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 2. INFORMAÇÕES DA CONTA ───────────────────────────────────
                _secaoTitulo('Informações da Conta'),
                const SizedBox(height: 8),
                _infoTile(
                  icon: Icons.badge_outlined,
                  iconColor: Colors.blue,
                  label: 'Username',
                   valor: usuario.email
                ),
                _infoTile(
                  icon: Icons.calendar_today_outlined,
                  iconColor: Colors.orange,
                  label: 'Cadastrado em',
                  valor: _formatarDataHora(usuario.dataCadastro)
                ),
                _infoTile(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.purple,
                  label: 'Perfil de Acesso',
                  valor: _getPerfilNome(usuario),
                ),
                const SizedBox(height: 20),

                // ── 3. AÇÕES DE GERENCIAMENTO ─────────────────────────────────
                const Divider(),
                const SizedBox(height: 8),
                _secaoTitulo('Ações de Gerenciamento'),
                const SizedBox(height: 16),

                // Botão Reiniciar Senha
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _reiniciarSenha(usuario),
                    icon: const Icon(Icons.lock_reset, color: Colors.white),
                    label: const Text(
                      'REINICIAR SENHA',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botão Afastar / Reativar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleAfastamento(usuario),
                    icon: Icon(
                      isAtivo ? Icons.person_off : Icons.person_add,
                      color: Colors.white,
                    ),
                    label: Text(
                      isAtivo
                          ? 'AFASTAR / DESLIGAR FUNCIONÁRIO'
                          : 'REATIVAR FUNCIONÁRIO',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAtivo ? Colors.red.shade700 : Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ao reiniciar a senha, o usuário receberá a senha padrão '
                          '(12345678) e deverá alterá-la no próximo login.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS AUXILIARES
  // ---------------------------------------------------------------------------

  Widget _secaoTitulo(String texto) => Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String valor,
  }) =>
      ListTile(
        dense: true,
        leading: Icon(icon, color: iconColor),
        title: Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      );
}