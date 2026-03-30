// lib/services/sync_queue_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

const _kMaxTentativas = 3;
const _kBaseUrl = 'http://localhost:8080';

Duration _backoff(int tentativa) =>
    Duration(seconds: (2 << tentativa).clamp(2, 30));

// ─── Enum ────────────────────────────────────────────────────────────────────

enum OperacaoTipo {
  // Pedido
  criarPedido,
  adicionarItem,
  finalizarPedido,
  cancelarPedido,
  actualizarValorPago,
  // Usuario
  criarUsuario,
  atualizarUsuario,
  toggleStatusUsuario,
  resetarSenhaUsuario,
  // Produto
  criarProduto,
  atualizarProduto,
  ativarProduto,
  desativarProduto,
  // Estoque
  adicionarEstoque,
  removerEstoque,
  definirEstoque,
}

// ─── Modelo ──────────────────────────────────────────────────────────────────

class OperacaoFila {
  final String id;
  final OperacaoTipo tipo;
  final Map<String, dynamic> payload;
  final DateTime criadoEm;
  int tentativas;
  String status;

  OperacaoFila({
    required this.id,
    required this.tipo,
    required this.payload,
    required this.criadoEm,
    this.tentativas = 0,
    this.status = 'pendente',
  });

  Map<String, dynamic> toJson() => {
        'id':         id,
        'tipo':       tipo.name,
        'payload':    payload,
        'criadoEm':   criadoEm.toIso8601String(),
        'tentativas': tentativas,
        'status':     status,
      };

  factory OperacaoFila.fromJson(Map<String, dynamic> json) => OperacaoFila(
        id:          json['id'] as String,
        tipo:        OperacaoTipo.values.firstWhere((e) => e.name == json['tipo']),
        payload:     Map<String, dynamic>.from(json['payload'] as Map),
        criadoEm:    DateTime.parse(json['criadoEm'] as String),
        tentativas:  (json['tentativas'] as int?) ?? 0,
        status:      (json['status'] as String?) ?? 'pendente',
      );
}

// ─── Serviço ─────────────────────────────────────────────────────────────────

class SyncQueueService {
  static final SyncQueueService instance = SyncQueueService._internal();
  factory SyncQueueService() => instance;
  SyncQueueService._internal();

  static const _prefsKey = 'sync_queue_v1';

  final List<OperacaoFila> _fila = [];
  bool _sincronizando = false;

  final _controller = StreamController<List<OperacaoFila>>.broadcast();
  Stream<List<OperacaoFila>> get stream => _controller.stream;

  List<OperacaoFila> get pendentes =>
      _fila.where((o) => o.status == 'pendente' || o.status == 'erro').toList();

  int get totalPendentes => pendentes.length;

  // ── Inicialização ─────────────────────────────────────────────────────────

  Future<void> inicializar() async {
    await _carregarDoDisco();
    ConnectivityService.instance.onlineStream.listen((online) {
      if (online) _processarFila();
    });
  }

  // ── Enfileirar ────────────────────────────────────────────────────────────

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

    if (ConnectivityService.instance.estaOnline) _processarFila();
  }

  // ── Processamento ─────────────────────────────────────────────────────────

  Future<void> _processarFila() async {
    if (_sincronizando) return;
    _sincronizando = true;
    try {
      final ordenados = List<OperacaoFila>.from(pendentes)
        ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

      for (final op in ordenados) {
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
        break;
      }

      op.tentativas++;
      op.status = 'erro';
      _emitir();

      if (op.tentativas < _kMaxTentativas) {
        await Future.delayed(_backoff(op.tentativas));
      }
    }

    op.status = 'erro';
    await _salvarNoDisco();
    _emitir();
  }

  // ── Envio HTTP ────────────────────────────────────────────────────────────

  Future<bool> _enviarAoBackend(OperacaoFila op) async {
    const timeout = Duration(seconds: 15);
    final h = {'Content-Type': 'application/json'};

    try {
      http.Response resp;
      final p = op.payload;

      switch (op.tipo) {

        // ── Pedido ──────────────────────────────────────────────────────────

        case OperacaoTipo.criarPedido:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/pedidos'), headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.adicionarItem:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/pedidos/${p['idPedido']}/itens'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.finalizarPedido:
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/pedidos/${p['idPedido']}/finalizar'),
                  headers: h)
              .timeout(timeout);

        case OperacaoTipo.cancelarPedido:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/pedidos/${p['idPedido']}/cancelar'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.actualizarValorPago:
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/pedidos/${p['idPedido']}/valor-pago'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        // ── Usuario ─────────────────────────────────────────────────────────

        case OperacaoTipo.criarUsuario:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/usuarios'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.atualizarUsuario:
          resp = await http
              .put(Uri.parse('$_kBaseUrl/api/usuarios/${p['idUsuario']}'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.toggleStatusUsuario:
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/usuarios/${p['idUsuario']}/toggle-status'),
                  headers: h)
              .timeout(timeout);

        case OperacaoTipo.resetarSenhaUsuario:
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/usuarios/${p['idUsuario']}/reset-password'),
                  headers: h)
              .timeout(timeout);

        // ── Produto ─────────────────────────────────────────────────────────

        case OperacaoTipo.criarProduto:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/produtos'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.atualizarProduto:
          resp = await http
              .put(Uri.parse('$_kBaseUrl/api/produtos/${p['idProduto']}'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.ativarProduto:
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/produtos/${p['idProduto']}/ativar'),
                  headers: h)
              .timeout(timeout);

        case OperacaoTipo.desativarProduto:
          resp = await http
              .patch(Uri.parse('$_kBaseUrl/api/produtos/${p['idProduto']}/desativar'),
                  headers: h)
              .timeout(timeout);

        // ── Estoque ─────────────────────────────────────────────────────────

        case OperacaoTipo.adicionarEstoque:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/estoque/adicionar'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.removerEstoque:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/estoque/remover'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);

        case OperacaoTipo.definirEstoque:
          resp = await http
              .post(Uri.parse('$_kBaseUrl/api/estoque/definir'),
                  headers: h, body: jsonEncode(p))
              .timeout(timeout);
      }

      return resp.statusCode >= 200 && resp.statusCode < 300;

    } on Exception {
      return false;
    }
  }

  // ── Persistência ──────────────────────────────────────────────────────────

  Future<void> _salvarNoDisco() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_fila.map((o) => o.toJson()).toList()));
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
      _fila..clear()..addAll(lista);
      _emitir();
    } catch (_) {
      await prefs.remove(_prefsKey);
    }
  }

  // ── Utilitários ───────────────────────────────────────────────────────────

  void _emitir() {
    if (!_controller.isClosed) _controller.add(List.unmodifiable(_fila));
  }

  String _gerarId() => '${DateTime.now().millisecondsSinceEpoch}_${_fila.length}';

  Future<void> limparEnviados() async {
    _fila.removeWhere((o) => o.status == 'enviado');
    await _salvarNoDisco();
    _emitir();
  }

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