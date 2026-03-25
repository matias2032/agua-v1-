// // lib/widgets/app_sidebar.dart

// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:api_compartilhado/api_compartilhado.dart';

// // TODO: Descomentar quando servico_logs for migrado para Spring Boot
// // import '../services/servico_logs.dart';

// class AppSidebar extends StatefulWidget {
//   final String currentRoute;

//   const AppSidebar({
//     super.key,
//     required this.currentRoute,
//   });

//   @override
//   State<AppSidebar> createState() => _AppSidebarState();
// }

// class _AppSidebarState extends State<AppSidebar>
//     with SingleTickerProviderStateMixin {
//   bool _showUserMenu = false;
//   late AnimationController _animationController;
//   late Animation<double> _rotationAnimation;

//   // TODO: Reactivar quando pedido_contador_service estiver migrado
//   int _contadorPedidos = 0;
//   StreamSubscription<int>? _contadorSubscription;

//   // ---------------------------------------------------------------------------
//   // CICLO DE VIDA
//   // ---------------------------------------------------------------------------

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 200),
//     );

//     _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut,
//       ),
//     );

//     // TODO: Reactivar quando pedido_contador_service estiver migrado
//     _carregarContadorDoUsuario();
//   }

//   // TODO: Reactivar quando pedido_contador_service estiver migrado
//   Future<void> _carregarContadorDoUsuario() async {
//     // ignore: unused_local_variable
//     final usuario = SessaoService.instance.usuarioAtual;
//     // implementação futura
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _contadorSubscription?.cancel();
//     super.dispose();
//   }

//   // ---------------------------------------------------------------------------
//   // MENU DO UTILIZADOR (toggle)
//   // ---------------------------------------------------------------------------

//   void _toggleUserMenu() {
//     setState(() {
//       _showUserMenu = !_showUserMenu;
//       if (_showUserMenu) {
//         _animationController.forward();
//       } else {
//         _animationController.reverse();
//       }
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // CONTROLO DE PERMISSÕES
//   // Usa usuario.perfil?.idPerfil — compatível com UsuarioModel do backend
//   // perfil pode ser null (ON DELETE SET NULL na tabela usuario)
//   // ---------------------------------------------------------------------------

//   bool _temPermissao(String route) {
//     final usuario = SessaoService.instance.usuarioAtual;
//     if (usuario == null) return false;

//     // perfil null → sem acesso a rotas restritas
//     final idPerfil = usuario.perfil?.idPerfil;
//     if (idPerfil == null) return false;

//     // Administrador tem acesso a tudo
//     if (idPerfil == 1) return true;

//     // Gerente
//     if (idPerfil == 2) {
//       return const [
//         '/dashboard',
//         '/menu',
//         '/categorias',
//         '/marcas',
//         '/produtos',
//         '/movimentos_estoque',
//         // '/historico_pedidos',
//       ].contains(route);
//     }

//     // Funcionário
//     if (idPerfil == 3) {
//       return const [
//         '/menu',
//         '/dashboard',
//       ].contains(route);
//     }

//     return false;
//   }

//   // ---------------------------------------------------------------------------
//   // BUILD PRINCIPAL
//   // ---------------------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     final usuario = SessaoService.instance.usuarioAtual;

//     if (usuario == null) return const SizedBox.shrink();

//     return Drawer(
//       child: Column(
//         children: [
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 _buildDrawerHeader(usuario),

//                 _buildMenuItem(
//                   icon: Icons.dashboard,
//                   title: 'Dashboard',
//                   route: '/dashboard',
//                 ),

//                 // Criar Pedido — com contador de pedidos pendentes
//                 // TODO: Substituir por _buildMenuItem simples enquanto
//                 //       pedido_contador_service não estiver migrado
//                 if (_temPermissao('/menu'))
//                   _buildMenuItemComContador(
//                     icon: Icons.shopping_cart,
//                     title: 'Criar Pedido',
//                     route: '/menu',
//                     contador: _contadorPedidos,
//                   ),

//                 if (_temPermissao('/categorias'))
//                   _buildMenuItem(
//                     icon: Icons.category,
//                     title: 'Gerenciar Categorias',
//                     route: '/categorias',
//                   ),

//                 if (_temPermissao('/marcas'))
//                   _buildMenuItem(
//                     icon: Icons.shopping_cart,
//                     title: 'Gerenciar Marcas',
//                     route: '/marcas',
//                   ),

//                 // TODO: Reactivar usarBadge: true quando estoque_badge
//                 //       estiver validado
//                 if (_temPermissao('/produtos'))
//                   _buildMenuItem(
//                     icon: Icons.fastfood,
//                     title: 'Gerenciar Produtos',
//                     route: '/produtos',
//                     usarBadge: true,
//                   ),

//                 if (_temPermissao('/gerenciar_usuarios'))
//                   _buildMenuItem(
//                     icon: Icons.people,
//                     title: 'Gerenciar Usuários',
//                     route: '/gerenciar_usuarios',
//                   ),

//                 // if (_temPermissao('/historico_pedidos'))
//                 //   _buildMenuItem(
//                 //     icon: Icons.history,
//                 //     title: 'Histórico de Pedidos',
//                 //     route: '/historico_pedidos',
//                 //   ),

//                 // if (_temPermissao('/logs'))
//                 //   _buildMenuItem(
//                 //     icon: Icons.list_alt,
//                 //     title: 'Logs do Sistema',
//                 //     route: '/logs',
//                 //   ),

//                 if (_temPermissao('/movimentos_estoque'))
//                   _buildMenuItem(
//                     icon: Icons.inventory,
//                     title: 'Movimentos de Estoque',
//                     route: '/movimentos_estoque',
//                   ),
//               ],
//             ),
//           ),

//           _buildUserSection(usuario),
//         ],
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // DRAWER HEADER
//   // ---------------------------------------------------------------------------

//   Widget _buildDrawerHeader(UsuarioModel usuario) {
//     return DrawerHeader(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.deepOrange, Colors.deepOrange.shade700],
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Hero(
//             tag: 'user_avatar_${usuario.idUsuario}',
//             child: CircleAvatar(
//               radius: 32,
//               backgroundColor: Colors.white,
//               child: Text(
//                 usuario.nome[0].toUpperCase(),
//                 style: const TextStyle(
//                   fontSize: 36,
//                   color: Colors.deepOrange,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           // nome completo — getter apelido extrai o sobrenome de 'nome'
//           Text(
//             usuario.nome,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 4),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               // usa nomePerfil do PerfilModel aninhado; fallback para 'Usuário'
//               usuario.perfil?.nomePerfil ?? 'Usuário',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // ITEM DE MENU SIMPLES
//   // ---------------------------------------------------------------------------

//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     required String route,
//     // TODO: Reactivar quando estoque_badge estiver validado
//     bool usarBadge = false,
//   }) {
//     final isSelected = widget.currentRoute == route;

//     Widget iconWidget = Icon(
//       icon,
//       color: isSelected ? Colors.deepOrange : Colors.grey[700],
//     );

//     // TODO: Reactivar quando estoque_badge estiver validado


//     return ListTile(
//       leading: iconWidget,
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isSelected ? Colors.deepOrange : Colors.black87,
//           fontWeight:
//               isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//       selected: isSelected,
//       selectedTileColor: Colors.deepOrange.withOpacity(0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       onTap: () {
//         Navigator.pop(context);
//         if (!isSelected) {
//           Navigator.pushReplacementNamed(context, route);
//         }
//       },
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // ITEM DE MENU COM CONTADOR (pedidos pendentes)
//   // TODO: Reactivar completamente quando pedido_contador_service migrar
//   // ---------------------------------------------------------------------------

//   Widget _buildMenuItemComContador({
//     required IconData icon,
//     required String title,
//     required String route,
//     required int contador,
//   }) {
//     final isSelected = widget.currentRoute == route;

//     return ListTile(
//       leading: Icon(
//         icon,
//         color: isSelected ? Colors.deepOrange : Colors.grey[700],
//       ),
//       title: Row(
//         children: [
//           Expanded(
//             child: Text(
//               title,
//               style: TextStyle(
//                 color: isSelected ? Colors.deepOrange : Colors.black87,
//                 fontWeight:
//                     isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//           if (contador > 0)
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.red.withOpacity(0.4),
//                     blurRadius: 4,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: Text(
//                 '$contador',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       selected: isSelected,
//       selectedTileColor: Colors.deepOrange.withOpacity(0.1),
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8)),
//       onTap: () {
//         Navigator.pop(context);
//         if (!isSelected) {
//           Navigator.pushReplacementNamed(context, route);
//         }
//       },
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // SECÇÃO DO UTILIZADOR (rodapé do drawer)
//   // ---------------------------------------------------------------------------

//   Widget _buildUserSection(UsuarioModel usuario) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Sub-menu animado (Alterar Dados / Alterar Senha / Sair)
//           AnimatedSize(
//             duration: const Duration(milliseconds: 250),
//             curve: Curves.easeInOut,
//             alignment: Alignment.bottomCenter,
//             child: _showUserMenu
//                 ? Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       border: Border(
//                         bottom: BorderSide(color: Colors.grey[300]!),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         _buildUserMenuItem(
//                           icon: Icons.person,
//                           title: 'Alterar Dados',
//                           color: Colors.blue,
//                           onTap: () {
//                             Navigator.pop(context);
//                             Navigator.pushNamed(
//                                 context, '/editar_usuario');
//                           },
//                         ),
//                         Divider(height: 1, color: Colors.grey[200]),
//                         _buildUserMenuItem(
//                           icon: Icons.lock,
//                           title: 'Alterar Senha',
//                           color: Colors.orange,
//                           onTap: () {
//                             Navigator.pop(context);
//                             Navigator.pushNamed(
//                                 context, '/alterar_senha');
//                           },
//                         ),
//                         Divider(height: 1, color: Colors.grey[200]),
//                         _buildUserMenuItem(
//                           icon: Icons.logout,
//                           title: 'Sair',
//                           color: Colors.red,
//                           onTap: () => _confirmarLogout(context),
//                         ),
//                       ],
//                     ),
//                   )
//                 : const SizedBox.shrink(),
//           ),

//           // Linha principal com avatar + nome + username
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: _toggleUserMenu,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 16, vertical: 14),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 22,
//                       backgroundColor: Colors.deepOrange,
//                       child: Text(
//                         usuario.nome[0].toUpperCase(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             usuario.nome,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 2),
//                           // username em vez de email — backend não persiste email
//                           Text(
//                             usuario.username,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                     RotationTransition(
//                       turns: _rotationAnimation,
//                       child: Icon(
//                           Icons.expand_less, color: Colors.grey[700]),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // ITEM DO SUB-MENU DO UTILIZADOR
//   // ---------------------------------------------------------------------------

//   Widget _buildUserMenuItem({
//     required IconData icon,
//     required String title,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: color, size: 22),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: title == 'Sair' ? Colors.red : Colors.black87,
//           fontSize: 14,
//         ),
//       ),
//       dense: true,
//       contentPadding:
//           const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       onTap: onTap,
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // LOGOUT
//   // ---------------------------------------------------------------------------

//   Future<void> _confirmarLogout(BuildContext context) async {
//     final confirmado = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.logout, color: Colors.red),
//             SizedBox(width: 12),
//             Text('Confirmar Saída'),
//           ],
//         ),
//         content: const Text('Tem certeza que deseja sair da sua conta?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(false),
//             child: const Text('Cancelar'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(ctx).pop(true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Sair'),
//           ),
//         ],
//       ),
//     );

//     if (confirmado != true) return;

//     // TODO: Reactivar log de logout quando servico_logs estiver migrado
//     // final usuario = SessaoService.instance.usuarioAtual;
//     // if (usuario != null) {
//     //   await ServicoLogs.instance.registrarLogout(
//     //     usuario.idUsuario,
//     //     usuario.nome,
//     //   );
//     // }

//     // TODO: Reactivar quando pedido_contador_service estiver migrado
//     // _contadorService.resetar();

//     SessaoService.instance.limparSessao();

//     if (!mounted) return;
//     Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
//   }
// }