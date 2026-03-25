import 'dart:convert';
import 'package:http/http.dart' as http;

// Importe o seu novo arquivo de configuração
import '../exceptions/produto_exceptions.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

const _tag = 'ProdutoService';

class ProdutoService {
  static ProdutoService? _instance;

  /// Singleton que utiliza o baseUrl dinâmico do ApiConfig
  static ProdutoService get instance =>
      _instance ??= ProdutoService(baseUrl: ApiConfig.baseUrl);

  final http.Client _client;
  final String _baseUrl;

  ProdutoService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client() {
    AppLogger.info(_tag, 'Inicializado — baseUrl: $_baseUrl');
  }

  Map<String, String> get _headers => ApiConfig.defaultHeaders;

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
      throw ProdutoNaoEncontradoException(envelope.erro ?? 'Não encontrado');
    }
    if (response.statusCode == 422) {
      AppLogger.warn(_tag, '422 → ${envelope.erro}');
      throw ProdutoValidacaoException(envelope.erro ?? 'Erro de validação');
    }
    if (!envelope.sucesso || envelope.temErro) {
      AppLogger.error(
          _tag, 'Erro do servidor [${response.statusCode}]: ${envelope.erro}');
      throw ProdutoServiceException(
        envelope.erro ?? 'Erro desconhecido',
        statusCode: response.statusCode,
      );
    }
    if (envelope.dados == null) {
      throw ProdutoServiceException('Resposta sem dados',
          statusCode: response.statusCode);
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

  // ── Produtos ─────────────────────────────────────────────────────────────

  /// Lista produtos disponíveis (estoque ativo)
  Future<List<DisponibilidadeProdutoModel>> listarProdutos() async {
    final uri = Uri.parse(ApiConfig.produtosUrl);
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseLista(res, DisponibilidadeProdutoModel.fromJson);
  }

  

  /// Lista absolutamente todos os produtos do cadastro
  Future<List<ProdutoModel>> listarTodos() async {
    final uri = Uri.parse('${ApiConfig.produtosUrl}/todos');
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseLista(res, ProdutoModel.fromJson);
  }

  Future<DisponibilidadeProdutoModel> buscarPorId(int id) async {
    final uri = Uri.parse('${ApiConfig.produtosUrl}/$id');
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseDados(
        res,
        (json) =>
            DisponibilidadeProdutoModel.fromJson(json as Map<String, dynamic>));
  }

  Future<ProdutoModel> criar(ProdutoRequest request) async {
    final uri = Uri.parse(ApiConfig.produtosUrl);
    final payload = jsonEncode(request.toJson());
    AppLogger.info(_tag, 'POST $uri → $payload');
    final res = await _client.post(uri, headers: _headers, body: payload);
    return _parseDados(
        res, (json) => ProdutoModel.fromJson(json as Map<String, dynamic>));
  }

  Future<ProdutoModel> atualizar(int id, ProdutoRequest request) async {
    final uri = Uri.parse('${ApiConfig.produtosUrl}/$id');
    final payload = jsonEncode(request.toJson());
    AppLogger.info(_tag, 'PUT $uri → $payload');
    final res = await _client.put(uri, headers: _headers, body: payload);
    return _parseDados(
        res, (json) => ProdutoModel.fromJson(json as Map<String, dynamic>));
  }

  Future<ProdutoModel> ativar(int id) async {
    final uri = Uri.parse('${ApiConfig.produtosUrl}/$id/ativar');
    AppLogger.info(_tag, 'PATCH $uri');
    final res = await _client.patch(uri, headers: _headers);
    return _parseDados(
        res, (json) => ProdutoModel.fromJson(json as Map<String, dynamic>));
  }

  Future<ProdutoModel> desativar(int id) async {
    final uri = Uri.parse('${ApiConfig.produtosUrl}/$id/desativar');
    AppLogger.info(_tag, 'PATCH $uri');
    final res = await _client.patch(uri, headers: _headers);
    return _parseDados(
        res, (json) => ProdutoModel.fromJson(json as Map<String, dynamic>));
  }

  Future<PrecoProdutoModel> calcularPreco({
    required int idProduto,
    required int idOperacao,
  }) async {
    final uri = Uri.parse('${ApiConfig.produtosUrl}/$idProduto/preco')
        .replace(queryParameters: {'operacaoId': idOperacao.toString()});
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseDados(res,
        (json) => PrecoProdutoModel.fromJson(json as Map<String, dynamic>));
  }

  // ── Operações ─────────────────────────────────────────────────────────────

  Future<List<OperacaoModel>> listarOperacoes() async {
    final uri = Uri.parse(ApiConfig.operacoesUrl);
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseLista(res, OperacaoModel.fromJson);
  }

  Future<OperacaoModel> buscarOperacaoPorId(int id) async {
    final uri = Uri.parse('${ApiConfig.operacoesUrl}/$id');
    AppLogger.info(_tag, 'GET $uri');
    final res = await _client.get(uri, headers: _headers);
    return _parseDados(
        res, (json) => OperacaoModel.fromJson(json as Map<String, dynamic>));
  }

  void dispose() {
    AppLogger.info(_tag, 'dispose — fechando http.Client');
    _client.close();
  }
}