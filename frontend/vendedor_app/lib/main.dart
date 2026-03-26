import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// Telas de Usuários
import 'screens/gerenciar_usuarios.dart';
import 'screens/detalhes_usuario.dart';
import 'screens/cadastrar_usuario.dart';
import 'screens/alterar_senha.dart';
import 'screens/editar_usuario.dart';
import 'screens/primeira_troca_senha.dart';

// Telas de Produtos
import 'screens/produto_detalhe_screen.dart';
import 'screens/produto_form_screen.dart';
import 'screens/produto_lista_screen.dart';

// Telas de Estoque
import 'screens/estoque_dashboard_screen.dart';
import 'screens/movimentos_estoque_screen.dart';

// Login
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

      // ── Tela inicial: sempre o login ──────────────────────────────────────
      initialRoute: '/login',

      onGenerateRoute: (settings) {
        // ─── Rotas com argumentos ──────────────────────────────────────────
        if (settings.name == '/detalhes_usuario') {
          final usuarioId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => DetalhesUsuarioScreen(usuarioId: usuarioId),
          );
        }

        if (settings.name == '/produto_detalhes') {
          final id = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => ProdutoDetalheScreen(idProduto: id),
          );
        }

        // ─── Rotas simples ─────────────────────────────────────────────────
        switch (settings.name) {
          // AUTH
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );

          // PRODUTOS
          case '/gerenciar_produtos':
            return MaterialPageRoute(
              builder: (context) => const ProdutoListaScreen(),
            );

          case '/ProdutoFormScreen':
            return MaterialPageRoute(
              builder: (context) => const ProdutoFormScreen(),
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
              builder: (context) => const PrimeiraTrocaSenhaScreen(),
            );

          // ESTOQUE
          case '/estoque':
            return MaterialPageRoute(
              builder: (_) => const EstoqueDashboardScreen(),
            );

          case '/movimentos_estoque':
            return MaterialPageRoute(
              builder: (_) => const MovimentosEstoqueScreen(),
            );

          default:
            return null;
        }
      },
    );
  }
}