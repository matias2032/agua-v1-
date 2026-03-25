// lib/screens/gerenciar_usuarios.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../widgets/app_sidebar.dart';

// =============================================================================
// ENUMS DE FILTRO
// =============================================================================

enum StatusFiltro { todos, ativo, inativo }

enum PerfilFiltro { todos, gerente, funcionario }

// =============================================================================
// SCREEN
// =============================================================================

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  final UsuarioService _service = UsuarioService();

  late Future<List<UsuarioModel>> _usuariosFuture;
  StatusFiltro _statusFiltro = StatusFiltro.todos;
  PerfilFiltro _perfilFiltro = PerfilFiltro.todos;
  int _refreshCounter = 0;

  // ---------------------------------------------------------------------------
  // CICLO DE VIDA
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _usuariosFuture = _loadUsuarios();
  }



  // ---------------------------------------------------------------------------
  // CARREGAMENTO COM FILTROS
  // ---------------------------------------------------------------------------

// SUBSTITUIR o método completo:

Future<List<UsuarioModel>> _loadUsuarios({
  StatusFiltro? status,
  PerfilFiltro? perfil,
}) async {
  // Usa os parâmetros passados, ou o estado actual como fallback
  final filtroStatus = status ?? _statusFiltro;
  final filtroPerfil = perfil ?? _perfilFiltro;

  final bool? apenasAtivos = switch (filtroStatus) {
    StatusFiltro.ativo   => true,
    StatusFiltro.inativo => null, // busca todos, filtra client-side abaixo
    StatusFiltro.todos   => null,
  };

  final int? idPerfil = switch (filtroPerfil) {
    PerfilFiltro.gerente     => 3,
    PerfilFiltro.funcionario => 4,
    PerfilFiltro.todos       => null,
  };

final lista = await _service.listarUsuarios(
  perfil: idPerfil,
  ativo: apenasAtivos,
);

  if (filtroStatus == StatusFiltro.inativo) {
    return lista.where((u) => !u.ativo).toList();
  }
  return lista;
}

  // ✅ _loadUsuarios() é chamado ANTES do setState para criar um novo objeto Future.
  // O FutureBuilder detecta a mudança de referência e reconstrói imediatamente,
  // sem precisar de hot restart.
void _recarregar() {
  setState(() {
    _refreshCounter++; // Isso forçará o FutureBuilder a resetar
    _usuariosFuture = _loadUsuarios();
  });
}

  // ---------------------------------------------------------------------------
  // AÇÕES
  // ---------------------------------------------------------------------------

  Future<void> _toggleStatus(UsuarioModel usuario) async {
    try {
   await _service.toggleStatus(usuario.idUsuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
         content: Text(usuario.ativo
    ? '${usuario.nome} inativado com sucesso.'
    : '${usuario.nome} ativado com sucesso.'),
          backgroundColor: usuario.ativo ? Colors.orange : Colors.green,
        ),
      );
      _recarregar();
    }catch (e) {
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
     content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetarSenha(UsuarioModel usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetar Senha'),
        content: Text(
          'Tem certeza que deseja resetar a senha de ${usuario.nome} para 12345678?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Resetar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
  await _service.resetarSenha(usuario.idUsuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha resetada com sucesso! Nova senha: 12345678'),
          backgroundColor: Colors.green,
        ),
      );
    }  catch (e) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
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
  String _formatarData(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  String _getFiltroLabel() {
    final status = switch (_statusFiltro) {
      StatusFiltro.ativo   => 'Ativos',
      StatusFiltro.inativo => 'Inativos',
      StatusFiltro.todos   => 'Todos',
    };
    final perfil = switch (_perfilFiltro) {
      PerfilFiltro.gerente     => ' · Gerentes',
      PerfilFiltro.funcionario => ' · Vendedores',
      PerfilFiltro.todos       => '',
    };
    return '$status$perfil';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuários — ${_getFiltroLabel()}'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          // ── Filtro de Status ──────────────────────────────────────────────
          PopupMenuButton<StatusFiltro>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por Status',
          onSelected: (v) {
  // ✅ passa o novo valor directamente para _loadUsuarios
  // antes do setState actualizar _statusFiltro
  final novoFuture = _loadUsuarios(status: v);
  setState(() {
    _statusFiltro = v;
    _refreshCounter++;
    _usuariosFuture = novoFuture;
  });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: StatusFiltro.todos,
                child: Text('Todos os Status'),
              ),
              PopupMenuItem(
                value: StatusFiltro.ativo,
                child: Row(children: [
                  Icon(Icons.person, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Apenas Ativos'),
                ]),
              ),
              PopupMenuItem(
                value: StatusFiltro.inativo,
                child: Row(children: [
                  Icon(Icons.person_off, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Apenas Inativos'),
                ]),
              ),
            ],
          ),

          // ── Filtro de Perfil ──────────────────────────────────────────────
          PopupMenuButton<PerfilFiltro>(
            icon: const Icon(Icons.group),
            tooltip: 'Filtrar por Perfil',
        onSelected: (v) {
  // ✅ passa o novo valor directamente para _loadUsuarios
  // antes do setState actualizar _perfilFiltro
  final novoFuture = _loadUsuarios(perfil: v);
  setState(() {
    _perfilFiltro = v;
    _refreshCounter++;
    _usuariosFuture = novoFuture;
  });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: PerfilFiltro.todos,       child: Text('Todos os Perfis')),
              PopupMenuItem(value: PerfilFiltro.gerente,     child: Text('Apenas Gerentes')),
              PopupMenuItem(value: PerfilFiltro.funcionario, child: Text('Apenas Vendedores')),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _recarregar,
          ),

          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Novo Usuário',
            onPressed: () async {
              await Navigator.of(context).pushNamed('/cadastrar_usuarios');
              _recarregar();
            },
          ),
        ],
      ),

      // drawer: const AppSidebar(currentRoute: '/gerenciar_usuarios'),

      body: FutureBuilder<List<UsuarioModel>>(
        key: ValueKey(_refreshCounter),
        future: _usuariosFuture,
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
                  Text(
                    'Erro ao carregar usuários',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                    onPressed: _recarregar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          // ── Lista vazia ────────────────────────────────────────────────────
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum usuário encontrado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFiltroLabel(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ── Lista ──────────────────────────────────────────────────────────
          final usuarios = snapshot.data!;

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              final perfilNome  = _getPerfilNome(usuario);
              final isAtivo     = usuario.ativo;
              final statusColor = isAtivo ? Colors.green : Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  // Avatar com inicial do nome
                  leading: CircleAvatar(
                    backgroundColor: isAtivo ? Colors.deepOrange : Colors.grey,
                    child: Text(
                      usuario.nome[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Nome completo + perfil + indicador de status
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '${usuario.nome} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '($perfilNome)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.circle, size: 9, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Username + data de cadastro
             subtitle: Text(
  'Email: ${usuario.email}\n'
  'Cadastro: ${_formatarData(usuario.dataCadastro)}',
),
                  isThreeLine: true,

                  // Menu de ações
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'detalhes':
                          Navigator.pushNamed(
                            context,
                            '/detalhes_usuario',
                            arguments: usuario.idUsuario,
                          ).then((_) => _recarregar());
                        case 'toggle':
                          _toggleStatus(usuario);
                        case 'reset':
                          _resetarSenha(usuario);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'detalhes',
                        child: Row(children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('Ver Detalhes'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(children: [
                          Icon(
                            isAtivo ? Icons.person_off : Icons.person,
                            color: isAtivo ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(isAtivo ? 'Desativar' : 'Ativar'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(children: [
                          Icon(Icons.lock_reset, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Resetar Senha'),
                        ]),
                      ),
                    ],
                  ),

                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/detalhes_usuario',
                      arguments: usuario.idUsuario,
                    ).then((_) => _recarregar());
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}