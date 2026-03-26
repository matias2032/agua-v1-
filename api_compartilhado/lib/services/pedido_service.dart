import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_compartilhado.dart';

import '../models/pedido_model.dart';
import '../models/pedido_request.dart';

const _tag = 'PedidoService';

/// Modelo de paginação para pedidos
class PaginaPedidos {
  final List<PedidoModel> conteudo;
  final int totalElementos;
  final int totalPaginas;
  final int paginaActual;

  const PaginaPedidos({
    required this.conteudo,
    required this.totalElementos,
    required this.totalPaginas,
    required this.paginaActual,
  });

  bool get temProxima => paginaActual < totalPaginas - 1;

  factory PaginaPedidos.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List<dynamic>)
        .map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginaPedidos(
      conteudo: content,
      totalElementos: json['totalElements'] as int,
      totalPaginas: json['totalPages'] as int,
      paginaActual: json['number'] as int,
    );
  }
}

class PedidoService {
  static PedidoService? _instance;

  /// Singleton que utiliza o baseUrl dinâmico do ApiConfig
  static PedidoService get instance =>
      _instance ??= PedidoService(baseUrl: ApiConfig.baseUrl);

  final http.Client _client;
  final String _baseUrl;

  PedidoService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client() {
    AppLogger.info(_tag, 'Inicializado — baseUrl: $_baseUrl');
  }

  String get _pedidosUrl => '$_baseUrl/api/pedidos';

  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  Map<String, String> _headersComUsuario(int idUsuario) => {
        ..._headers,
        'X-Usuario-Id': idUsuario.toString(),
      };

  // ── Helpers ──────────────────────────────────────────────────────────────

  T _parseDados<T>(
    http.Response response,
    T Function(dynamic json) fromJson,
  ) {
    AppLogger.debug(
        _tag, 'Response ${response.statusCode}: ${response.request?.url}');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final envelope = ApiResponse<T>.fromJson(body, fromJson);

    if (response.statusCode == 404) {
      AppLogger.warn(_tag, '404 → ${envelope.erro}');
      throw Exception(envelope.erro ?? 'Pedido não encontrado');
    }
    if (!envelope.sucesso || envelope.temErro) {
      AppLogger.error(
          _tag, 'Erro do servidor [${response.statusCode}]: ${envelope.erro}');
      throw Exception(envelope.erro ?? 'Erro desconhecido');
    }
    if (envelope.dados == null) {
      throw Exception('Resposta sem dados');
    }
    return envelope.dados as T;
  }

  List<T> _parseLista<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      _parseDados<List<T>>(
        response,
        (json) => (json as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ── Pedidos ──────────────────────────────────────────────────────────────

  /// POST /api/pedidos — Criar pedido com itens
  Future<PedidoModel> criar(PedidoRequest request, int idUsuario) async {
    final uri = Uri.parse(_pedidosUrl);
    final payload = jsonEncode(request.toJson());
    AppLogger.info(_tag, 'POST $uri → $payload');
    final res = await _client.post(
      uri,
      headers: _headersComUsuario(idUsuario),
      body: payload,
    );
    return _parseDados(
        res, (json) => PedidoModel.fromJson(json as Map<String, dynamic>));
  }

  /// GET /api/pedidos — Listar pedidos (paginado, filtro por status opcional)
  Future<PaginaPedidos> listar({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (status != null) 'status': status,
    };
    final uri = Uri.parse(_pedidosUrl).replace(queryParameters: params);
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseDados(
        res, (json) => PaginaPedidos.fromJson(json as Map<String, dynamic>));
  }

  /// GET /api/pedidos/{id} — Buscar pedido por ID com itens
  Future<PedidoModel> buscarPorId(int id) async {
    final uri = Uri.parse('$_pedidosUrl/$id');
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseDados(
        res, (json) => PedidoModel.fromJson(json as Map<String, dynamic>));
  }

  /// GET /api/pedidos/usuario/{idUsuario} — Pedidos de um funcionário
  Future<List<PedidoModel>> listarPorUsuario(int idUsuario) async {
    final uri = Uri.parse('$_pedidosUrl/usuario/$idUsuario');
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseLista(res, PedidoModel.fromJson);
  }

  /// PATCH /api/pedidos/{id}/finalizar — Finalizar pedido
  Future<PedidoModel> finalizar(int id) async {
    final uri = Uri.parse('$_pedidosUrl/$id/finalizar');
    AppLogger.info(_tag, 'PATCH $uri');
    final res = await _client.patch(uri, headers: _headers);
    return _parseDados(
        res, (json) => PedidoModel.fromJson(json as Map<String, dynamic>));
  }

  /// PATCH /api/pedidos/{id}/valor-pago — Registar valor pago
  Future<PedidoModel> actualizarValorPago(
      int id, ValorPagoRequest request) async {
    final uri = Uri.parse('$_pedidosUrl/$id/valor-pago');
    final payload = jsonEncode(request.toJson());
    AppLogger.info(_tag, 'PATCH $uri → $payload');
    final res = await _client.patch(uri, headers: _headers, body: payload);
    return _parseDados(
        res, (json) => PedidoModel.fromJson(json as Map<String, dynamic>));
  }

  /// POST /api/pedidos/{id}/cancelar — Cancelar pedido
  Future<PedidoModel> cancelar(
    int id,
    CancelamentoPedidoRequest request,
    int idUsuario,
  ) async {
    final uri = Uri.parse('$_pedidosUrl/$id/cancelar');
    final payload = jsonEncode(request.toJson());
    AppLogger.info(_tag, 'POST $uri → $payload');
    final res = await _client.post(
      uri,
      headers: _headersComUsuario(idUsuario),
      body: payload,
    );
    return _parseDados(
        res, (json) => PedidoModel.fromJson(json as Map<String, dynamic>));
  }

  void dispose() {
    AppLogger.info(_tag, 'dispose — fechando http.Client');
    _client.close();
  }
}