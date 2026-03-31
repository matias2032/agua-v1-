import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  // ── Configuração de ambiente ──────────────────────────────────────

  static const String _prodBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://agua-v1.onrender.com',
  );

  static const int _porta = int.fromEnvironment(
    'API_PORT',
    defaultValue: 8080,
  );

  /// Quando true, força a URL de produção mesmo em debug.
  /// Activar com: --dart-define=FORCE_PROD=true
  static const bool _forceProd = bool.fromEnvironment(
    'FORCE_PROD',
    defaultValue: false,
  );

  static String? _baseUrlCache;

  // ── Resolução do baseUrl ──────────────────────────────────────────

  /// Resolve o baseUrl detectando automaticamente o ambiente.
  /// Deve ser chamado uma vez no main() antes de runApp().
  static Future<String> get baseUrlAsync async {
    if (_baseUrlCache != null) return _baseUrlCache!;

    // Release ou FORCE_PROD=true → sempre produção
    if (kReleaseMode || _forceProd) {
      _baseUrlCache = _prodBaseUrl;
      return _baseUrlCache!;
    }

    if (kIsWeb) {
      _baseUrlCache = 'http://${Uri.base.host}:$_porta';
      return _baseUrlCache!;
    }

    // Desktop/Mobile em desenvolvimento: descobre IP da rede local
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            _baseUrlCache = 'http://${addr.address}:$_porta';
            return _baseUrlCache!;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao obter IP local: $e');
    }

    _baseUrlCache = 'http://localhost:$_porta';
    return _baseUrlCache!;
  }

  /// Getter síncrono — usa cache (populado pelo baseUrlAsync)
  /// ou fallback imediato até o async resolver.
  static String get baseUrl {
    if (_baseUrlCache != null)      return _baseUrlCache!;
    if (kReleaseMode || _forceProd) return _prodBaseUrl;
    if (kIsWeb)                     return 'http://${Uri.base.host}:$_porta';
    return 'http://localhost:$_porta';
  }

  // ── Caminhos relativos ────────────────────────────────────────────

  static const String _usuarios          = '/api/usuarios';
  static const String _auth              = '/api/auth';
  static const String _perfis            = '/api/perfis';
  static const String _pedidos           = '/api/pedidos';
  static const String _produtos          = '/api/produtos';
  static const String _operacoes         = '/api/operacoes';
  static const String _tiposPagamento    = '/api/tipos-pagamento';
  static const String _estoque           = '/api/estoque';
  static const String _movimentosEstoque = '/api/movimentos-estoque';
  static const String _dashboard         = '/api/dashboard';

  // ── URLs completas ────────────────────────────────────────────────

  static String get usuariosUrl          => '$baseUrl$_usuarios';
  static String get authUrl              => '$baseUrl$_auth';
  static String get loginUrl             => '$baseUrl$_auth/login';
  static String get perfisUrl            => '$baseUrl$_perfis';
  static String get pedidosUrl           => '$baseUrl$_pedidos';
  static String get produtosUrl          => '$baseUrl$_produtos';
  static String get operacoesUrl         => '$baseUrl$_operacoes';
  static String get tiposPagamentoUrl    => '$baseUrl$_tiposPagamento';
  static String get estoqueUrl           => '$baseUrl$_estoque';
  static String get movimentosEstoqueUrl => '$baseUrl$_movimentosEstoque';
  static String get dashboardUrl         => '$baseUrl$_dashboard';

  // ── Configurações gerais ──────────────────────────────────────────

  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get defaultHeaders => const {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  static void printConfig() {
    final modo = kReleaseMode
        ? 'Release'
        : _forceProd
            ? 'Debug→Prod'
            : 'Debug→Local';
    debugPrint('🚀 API CONFIG — ${kIsWeb ? "Web" : "Desktop/Mobile"} [$modo]');
    debugPrint('🔗 Base URL: $baseUrl');
  }
}