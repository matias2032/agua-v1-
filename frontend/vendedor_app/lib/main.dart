// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/gerenciar_usuarios.dart';
import 'screens/detalhes_usuario.dart';
import 'screens/cadastrar_usuario.dart';
import 'screens/alterar_senha.dart';
import 'screens/editar_usuario.dart';
import 'screens/primeira_troca_senha.dart';
import 'package:api_compartilhado/api_config.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.baseUrlAsync.then((_) {
    print("✅ API Config carregada com sucesso!");
  }).catchError((error) {
    print("❌ Erro ao carregar API Config: $error");
  }); // ← resolve e faz cache ANTES do app arrancar
  ApiConfig.printConfig();      // ← confirma no console o IP resolvido
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestão',
      debugShowCheckedModeBanner: false,
      
      // ===== TEMA =====
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      
      // ===== TELA INICIAL =====
      initialRoute: '/usuarios',
      
      // ===== ROTAS NOMEADAS =====
      onGenerateRoute: (settings) {

        // ─── Rotas com argumentos ──────────────────────────────────────────

        // Detalhes do Usuário
        if (settings.name == '/detalhes_usuario') {
          final usuarioId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => DetalhesUsuarioScreen(usuarioId: usuarioId),
          );
        }


        

        // ─── Rotas simples ─────────────────────────────────────────────────
        switch (settings.name) {

            // 🔥 LOGIN — rota raiz: primeiro ecrã ao iniciar o app
          

               // 🔥 TROCA OBRIGATÓRIA DE SENHA (primeira vez)
          case '/primeira_troca_senha':
            return MaterialPageRoute(
              builder: (context) => const PrimeiraTrocaSenhaScreen(),
            );



          // USUÁRIOS
          case '/usuarios':
          case '/gerenciar_usuarios':
            return MaterialPageRoute(
              builder: (context) => const UsuarioListScreen(),
            );
case '/cadastrar_usuarios':
            return MaterialPageRoute(
              builder: (context) => const UsuarioFormScreen(),
            );
            
              // case '/editar_usuario':
              //   return MaterialPageRoute(
              //     builder: (_) => const EditarUsuarioScreen(),
              //   );
              
              case '/alterar_senha':
                return MaterialPageRoute(
                  builder: (_) => const AlterarSenhaScreen(),
                );

        }
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({Key? key}) : super(key: key);
// //  final ConnectivityService _connectivity = ConnectivityService();
// //   bool _online = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _connectivity.statusStream.listen((online) {
// //       setState(() => _online = online);
// //       if (online) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('✅ Conexão restaurada'),
// //             backgroundColor: Color(0xFF4CAF82),
// //             duration: Duration(seconds: 2),
// //           ),
// //         );
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('⚠️ Sem conexão com a internet'),
// //             backgroundColor: Color(0xFFEF5350),
// //             duration: Duration(days: 1), // persiste até voltar
// //           ),
// //         );
// //       }
// //     });
// //   }
// // }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sistema de Gestão'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: GridView.count(
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           children: [
//             _buildMenuCard(
//               context,
//               title: 'Usuários',
//               icon: Icons.people,
//               color: Colors.blue,
//               route: '/usuarios',
//             ),
//             _buildMenuCard(
//               context,
//               title: 'Categorias',
//               icon: Icons.category,
//               color: Colors.green,
//               route: '/categorias',
//             ),
//             _buildMenuCard(
//               context,
//               title: 'Marcas',
//               icon: Icons.label,
//               color: Colors.orange,
//               route: '/marcas',
//             ),
//             _buildMenuCard(
//               context,
//               title: 'Produtos',
//               icon: Icons.inventory,
//               color: Colors.purple,
//               route: '/produtos',
//             ),
//             // ✅ NOVO — Menu / Catálogo de vendas
//             _buildMenuCard(
//               context,
//               title: 'Menu',
//               icon: Icons.storefront,
//               color: Colors.indigo,
//               route: '/menu',
//             ),
//             // ✅ NOVO — Pedidos por finalizar
//             _buildMenuCard(
//               context,
//               title: 'Por Finalizar',
//               icon: Icons.receipt_long,
//               color: Colors.amber[700]!,
//               route: '/pedidos_por_finalizar',
//             ),
//             _buildMenuCard(
//   context,
//   title: 'Movimentos',
//   icon: Icons.swap_vert_rounded,
//   color: Colors.cyan[700]!,
//   route: '/movimentos_estoque',
// ),
//             _buildMenuCard(
//               context,
//               title: 'Relatórios',
//               icon: Icons.bar_chart,
//               color: Colors.teal,
//               route: '/relatorios', // A implementar
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuCard(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required Color color,
//     required String route,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: InkWell(
//         onTap: () {
//           Navigator.pushNamed(context, route);
//         },
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 color.withOpacity(0.7),
//                 color,
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 64,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
