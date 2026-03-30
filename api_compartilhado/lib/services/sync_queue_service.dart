// lib/services/sync_queue_service.dart
//
// Fila durável de operações offline.
// Quando a rede está indisponível, as operações são guardadas na tabela
// sync_queue do PostgreSQL (via backend). Quando a ligação volta,
// este serviço reenvia as operações pendentes ao Spring Boot por ordem
// de criação, com backoff exponencial (máx. 3 tentativas).
//
// Dependências (pubspec.yaml):
//   http: ^1.x.x
//   connectivity_plus: ^6.x.x
//   shared_preferences: ^2.x.x

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

// ─── Constantes de configuração ───────────────────────────────────────────────

const _kMaxTentativas = 3;
const _kBaseUrl = 'http://localhost:8080'; // ajustar para produção

// Backoff: tentativa 1 → 2s, tentativa 2 → 4s, tentativa 3 → 8s
Duration _backoff(int tentativa) =>
    Duration(seconds: (2 << tentativa).clamp(2, 30));

// ─── Modelo de operação na fila ───────────────────────────────────────────────

enum OperacaoTipo {
  criarPedido,
  adicionarItem,
  finalizarPedido,
  cancelarPedido,
  actualizarValorPago,
}

class OperacaoFila {
  final String id;          // UUID gerado localmente
  final OperacaoTipo tipo;
  final Map<String, dynamic> payload;
  final DateTime criadoEm;
  int tentativas;
  String status; // 'pendente' | 'enviando' | 'enviado' | 'erro'

  OperacaoFila({
    required this.id,
    required this.tipo,
    required this.payload,
    required this.criadoEm,
    this.tentativas = 0,
    this.status = 'pendente',
  });

  Map<String, dynamic> toJson() => {
        'id':        id,
        'tipo':      tipo.name,
        'payload':   payload,
        'criadoEm':  criadoEm.toIso8601String(),
        'tentativas': tentativas,
        'status':    status,
      };

  factory OperacaoFila.fromJson(Map<String, dynamic> json) => OperacaoFila(
        id:          json['id'] as String,
        tipo:        OperacaoTipo.values
                        .firstWhere((e) => e.name == json['tipo']),
        payload:     Map<String, dynamic>.from(json['payload'] as Map),
        criadoEm:    DateTime.parse(json['criadoEm'] as String),
        tentativas:  (json['tentativas'] as int?) ?? 0,
        status:      (json['status'] as String?) ?? 'pendente',
      );
}

// ─── Serviço principal ────────────────────────────────────────────────────────

class SyncQueueService {
  static final SyncQueueService instance = SyncQueueService._internal();
  factory SyncQueueService() => instance;
  SyncQueueService._internal();

  static const _prefsKey = 'sync_queue_v1';

  // Fila em memória (espelha o que está em SharedPreferences)
  final List<OperacaoFila> _fila = [];

  // Evita múltiplos ciclos de sync simultâneos
  bool _sincronizando = false;

  // Stream público para a UI observar o estado da fila
  final _controller = StreamController<List<OperacaoFila>>.broadcast();
  Stream<List<OperacaoFila>> get stream => _controller.stream;

  List<OperacaoFila> get pendentes =>
      _fila.where((o) => o.status == 'pendente' || o.status == 'erro').toList();

  int get totalPendentes => pendentes.length;

  // ── Inicialização ──────────────────────────────────────────────────────────

  /// Carregar fila do disco e registar listener de conectividade.
  Future<void> inicializar() async {
    await _carregarDoDisco();
    ConnectivityService.instance.onlineStream.listen((online) {
      if (online) _processarFila();
    });
  }

  // ── Enfileirar operação ───────────────────────────────────────────────────

  /// Adiciona uma operação à fila e tenta processá-la imediatamente
  /// se houver ligação.
  Future<void> enfileirar({
    required OperacaoTipo tipo,
    required Map<String, dynamic> payload,
  }) async {
    final op = OperacaoFila(
      id:       _gerarId(),
      tipo:     tipo,
      payload:  payload,
      criadoEm: DateTime.now(),
    );
    _fila.add(op);
    await _salvarNoDisco();
    _emitir();

    if (ConnectivityService.instance.estaOnline) {
      _processarFila();
    }
  }

  // ── Processamento da fila ─────────────────────────────────────────────────

  Future<void> _processarFila() async {
    if (_sincronizando) return;
    _sincronizando = true;

    try {
      // Processa em ordem de criação
      final pendentesOrdenados = List<OperacaoFila>.from(pendentes)
        ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

      for (final op in pendentesOrdenados) {
        if (!ConnectivityService.instance.estaOnline) break;
        await _enviarComRetry(op);
      }
    } finally {
      _sincronizando = false;
    }
  }

  Future<void> _enviarComRetry(OperacaoFila op) async {
    while (op.tentativas < _kMaxTentativas) {
      try {
        op.status = 'enviando';
        _emitir();

        final sucesso = await _enviarAoBackend(op);

        if (sucesso) {
          op.status = 'enviado';
          _fila.remove(op);
          await _salvarNoDisco();
          _emitir();
          return;
        }
      } catch (_) {
        // Rede caiu a meio — sai do loop
        break;
      }

      op.tentativas++;
      op.status = 'erro';
      _emitir();

      if (op.tentativas < _kMaxTentativas) {
        await Future.delayed(_backoff(op.tentativas));
      }
    }

    // Esgotou tentativas
    op.status = 'erro';
    await _salvarNoDisco();
    _emitir();
  }

  // ── Envio HTTP ao Spring Boot ────────────────────────────────────────────

  Future<bool> _enviarAoBackend(OperacaoFila op) async {
    final headers = {
      'Content-Type': 'application/json',
      // Adaptar para o mecanismo de sessão real (ex: token JWT)
      if (op.payload['idUsuario'] != null)
        'X-Usuario-Id': op.payload['idUsuario'].toString(),
    };

    try {
      http.Response resp;

      switch (op.tipo) {
        case OperacaoTipo.criarPedido:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/pedidos'),
                  headers: headers, body: jsonEncode(op.payload))
              .timeout(const Duration(seconds: 15));

        case OperacaoTipo.adicionarItem:
          final id = op.payload['idPedido'];
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/pedidos/$id/itens'),
                  headers: headers, body: jsonEncode(op.payload))
              .timeout(const Duration(seconds: 15));

        case OperacaoTipo.finalizarPedido:
          final id = op.payload['idPedido'];
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/pedidos/$id/finalizar'),
                  headers: headers)
              .timeout(const Duration(seconds: 15));

        case OperacaoTipo.cancelarPedido:
          final id = op.payload['idPedido'];
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/pedidos/$id/cancelar'),
                  headers: headers, body: jsonEncode(op.payload))
              .timeout(const Duration(seconds: 15));

        case OperacaoTipo.actualizarValorPago:
          final id = op.payload['idPedido'];
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/pedidos/$id/valor-pago'),
                  headers: headers, body: jsonEncode(op.payload))
              .timeout(const Duration(seconds: 15));
      }

      // 2xx = sucesso
      return resp.statusCode >= 200 && resp.statusCode < 300;

    } on Exception {
      return false;
    }
  }

  // ── Persistência local (SharedPreferences) ────────────────────────────────

  Future<void> _salvarNoDisco() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_fila.map((o) => o.toJson()).toList());
    await prefs.setString(_prefsKey, json);
  }

  Future<void> _carregarDoDisco() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    try {
      final lista = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(OperacaoFila.fromJson)
          .toList();
      _fila
        ..clear()
        ..addAll(lista);
      _emitir();
    } catch (_) {
      // Ficheiro corrompido — começa com fila vazia
      await prefs.remove(_prefsKey);
    }
  }

  // ── Utilitários ───────────────────────────────────────────────────────────

  void _emitir() {
    if (!_controller.isClosed) _controller.add(List.unmodifiable(_fila));
  }

  String _gerarId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_fila.length}';

  /// Limpa operações já enviadas (manutenção).
  Future<void> limparEnviados() async {
    _fila.removeWhere((o) => o.status == 'enviado');
    await _salvarNoDisco();
    _emitir();
  }

  /// Força nova tentativa nas operações em erro.
  Future<void> retentar() async {
    for (final op in _fila.where((o) => o.status == 'erro')) {
      op.tentativas = 0;
      op.status = 'pendente';
    }
    await _salvarNoDisco();
    _emitir();
    _processarFila();
  }

  void dispose() => _controller.close();
}