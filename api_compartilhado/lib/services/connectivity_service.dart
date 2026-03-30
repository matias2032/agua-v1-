// lib/services/connectivity_service.dart
//
// Observa o estado da ligação de rede e notifica outros serviços.
// Usa o package connectivity_plus para detectar mudanças em tempo real.
//
// Dependências (pubspec.yaml):
//   connectivity_plus: ^6.x.x

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  factory ConnectivityService() => instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();

  // Stream público — emite true quando online, false quando offline
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _controller.stream;

  bool _estaOnline = true;
  bool get estaOnline => _estaOnline;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  // ── Inicialização ──────────────────────────────────────────────────────────

  /// Chamar uma vez no arranque da aplicação (ex: em main() ou num Provider).
  Future<void> inicializar() async {
    // Estado inicial
    final resultados = await _connectivity.checkConnectivity();
    _estaOnline = _isOnline(resultados);

    // Subscrever mudanças futuras
    _sub = _connectivity.onConnectivityChanged.listen(_onMudanca);
  }

  void _onMudanca(List<ConnectivityResult> resultados) {
    final online = _isOnline(resultados);

    if (online == _estaOnline) return; // sem mudança real

    _estaOnline = online;
    _controller.add(online);
  }

  bool _isOnline(List<ConnectivityResult> resultados) {
    return resultados.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  // ── Verificação manual ────────────────────────────────────────────────────

  /// Verifica o estado actual e emite no stream se mudou.
  Future<bool> verificarAgora() async {
    final resultados = await _connectivity.checkConnectivity();
    final online = _isOnline(resultados);
    if (online != _estaOnline) {
      _estaOnline = online;
      _controller.add(online);
    }
    return _estaOnline;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}