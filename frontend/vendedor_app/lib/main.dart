import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// ─── Telas Usuários ─────────────────────────────────────────
import 'screens/gerenciar_usuarios.dart';
import 'screens/detalhes_usuario.dart';
import 'screens/cadastrar_usuario.dart';
import 'screens/alterar_senha.dart';
import 'screens/editar_usuario.dart';
import 'screens/primeira_troca_senha.dart';

// ─── Telas Produtos ─────────────────────────────────────────
import 'screens/produto_lista_screen.dart';
import 'screens/produto_form_screen.dart';

// 🆕 NOVAS TELAS
import 'screens/menu.dart';
import 'screens/detalhes_produto.dart';
import 'screens/pedidos_por_finalizar.dart';

// ─── Estoque ───────────────────────────────────────────────
import 'screens/estoque_dashboard_screen.dart';
import 'screens/movimentos_estoque_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/historico_pedidos_screen.dart';

// ─── Auth ──────────────────────────────────────────────────
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiConfig.baseUrlAsync.then((_) {
    debugPrint("✅ API Config carregada com sucesso!");
  }).catchError((error) {
    debugPrint("❌ Erro ao carregar API Config: $error");
  });

  ApiConfig.printConfig();

  runApp(
 MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProdutoProvider()),
    ChangeNotifierProvider(create: (_) => EstoqueProvider()),
    ChangeNotifierProxyProvider<ProdutoProvider, PedidoProvider>(
      create: (_) => PedidoProvider(),
      update: (_, prodProv, pedProv) {
        pedProv!.setProdutoProvider(prodProv);
        return pedProv;
      },
    ),
  ],
  child: const MyApp(),
),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestão',
      debugShowCheckedModeBanner: false,

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

      // 🔥 Continua login como entrada
      initialRoute: '/login',

      onGenerateRoute: (settings) {

        // ─── ROTAS COM ARGUMENTOS ─────────────────────────

        if (settings.name == '/detalhes_usuario') {
          final usuarioId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => DetalhesUsuarioScreen(usuarioId: usuarioId),
          );
        }

        if (settings.name == '/detalhes_produto') {
          final produto = settings.arguments as DisponibilidadeProdutoModel;
          return MaterialPageRoute(
            builder: (_) => DetalhesProdutoScreen(produto: produto),
          );
        }

        // ─── ROTAS SIMPLES ───────────────────────────────

        switch (settings.name) {

          // AUTH
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );

          // 🆕 MENU PRINCIPAL
          case '/menu':
            return MaterialPageRoute(
              builder: (_) => const MenuScreen(),
               settings: settings,
            );

          // 🆕 PEDIDOS
          case '/pedidos-por-finalizar':
            return MaterialPageRoute(
              builder: (_) => const PedidosPorFinalizarScreen(),
            );

          // PRODUTOS (LEGADO / ADMIN)
          case '/gerenciar_produtos':
            return MaterialPageRoute(
              builder: (_) => const ProdutoListaScreen(),
               settings: settings,
            );

          case '/ProdutoFormScreen':
            return MaterialPageRoute(
              builder: (_) => const ProdutoFormScreen(),
            );

          // USUÁRIOS
          case '/usuarios':
          case '/gerenciar_usuarios':
            return MaterialPageRoute(
              builder: (_) => const UsuarioListScreen(),
               settings: settings,
            );

          case '/cadastrar_usuarios':
            return MaterialPageRoute(
              builder: (_) => const UsuarioFormScreen(),
            );

          case '/editar_usuario':
            return MaterialPageRoute(
              builder: (_) => const EditarUsuarioScreen(),
            );

          case '/alterar_senha':
            return MaterialPageRoute(
              builder: (_) => const AlterarSenhaScreen(),
            );

          case '/primeira_troca_senha':
            return MaterialPageRoute(
              builder: (_) => const PrimeiraTrocaSenhaScreen(),

            );

          // ESTOQUE
          case '/estoque':
            return MaterialPageRoute(
              builder: (_) => const EstoqueDashboardScreen(),
               settings: settings,
            );

          case '/movimentos_estoque':
            return MaterialPageRoute(
              builder: (_) => const MovimentosEstoqueScreen(),
               settings: settings,
            );
case '/dashboard':
  return MaterialPageRoute(
    builder: (_) => const DashboardScreen(),
    settings: settings, // IMPORTANTE: Passa o nome '/dashboard' para a tela
  );

  case '/historico_pedidos':
  return MaterialPageRoute(
    builder: (_) => const HistoricoPedidosScreen(),
    settings: settings, // IMPORTANTE: Passa o nome '/dashboard' para a tela
  );


          default:
            return null;
        }
      },
    );
  }
}