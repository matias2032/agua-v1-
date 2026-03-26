import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/estoque_model.dart';
import '../models/movimento_estoque_model.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


class PaginaMovimentos {
  final List<MovimentoEstoqueModel> conteudo;
  final int totalElementos;
  final int totalPaginas;
  final int paginaActual;

  const PaginaMovimentos({
    required this.conteudo,
    required this.totalElementos,
    required this.totalPaginas,
    required this.paginaActual,
  });

  bool get temProxima => paginaActual < totalPaginas - 1;

  factory PaginaMovimentos.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List<dynamic>)
        .map((e) => MovimentoEstoqueModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginaMovimentos(
      conteudo: content,
      totalElementos: json['totalElements'] as int,
      totalPaginas: json['totalPages'] as int,
      paginaActual: json['number'] as int,
    );
  }
}

class EstoqueService {
  // ─── Estoque ────────────────────────────────────────────────────────────────

  Future<EstoqueModel> buscarActual() async {
    final response = await http.get(
      Uri.parse(ApiConfig.estoqueUrl),
      headers: ApiConfig.defaultHeaders,
    );
    final body = _parseResponse(response);
    return EstoqueModel.fromJson(body['dados'] as Map<String, dynamic>);
  }

  Future<EstoqueModel> adicionar(
    double litros,
    int idUsuario, {
    String? motivo,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.estoqueUrl}/adicionar'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        'litros': litros,
        'idUsuario': idUsuario,
        if (motivo != null) 'motivo': motivo,
      }),
    );
    final body = _parseResponse(response);
    return EstoqueModel.fromJson(body['dados'] as Map<String, dynamic>);
  }

  Future<EstoqueModel> remover(
    double litros,
    int idUsuario, {
    String? motivo,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.estoqueUrl}/remover'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        'litros': litros,
        'idUsuario': idUsuario,
        if (motivo != null) 'motivo': motivo,
      }),
    );
    final body = _parseResponse(response);
    return EstoqueModel.fromJson(body['dados'] as Map<String, dynamic>);
  }

  Future<EstoqueModel> definir(
    double litrosDisponiveis,
    int idUsuario, {
    String? observacao,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.estoqueUrl),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        'litrosDisponiveis': litrosDisponiveis,
        'idUsuario': idUsuario,
        if (observacao != null) 'observacao': observacao,
      }),
    );
    final body = _parseResponse(response);
    return EstoqueModel.fromJson(body['dados'] as Map<String, dynamic>);
  }

  // ─── Movimentos ─────────────────────────────────────────────────────────────

  Future<PaginaMovimentos> listarTodos({int page = 0, int size = 20}) async {
    final uri = Uri.parse(ApiConfig.movimentosEstoqueUrl)
        .replace(queryParameters: {'page': '$page', 'size': '$size'});
    final response = await http.get(uri, headers: ApiConfig.defaultHeaders);
    final body = _parseResponse(response);
    return PaginaMovimentos.fromJson(body['dados'] as Map<String, dynamic>);
  }

  Future<PaginaMovimentos> listarManuais({int page = 0, int size = 20}) async {
    final uri = Uri.parse('${ApiConfig.movimentosEstoqueUrl}/manuais')
        .replace(queryParameters: {'page': '$page', 'size': '$size'});
    final response = await http.get(uri, headers: ApiConfig.defaultHeaders);
    final body = _parseResponse(response);
    return PaginaMovimentos.fromJson(body['dados'] as Map<String, dynamic>);
  }

  Future<PaginaMovimentos> listarPorTipo(
    String tipo, {
    int page = 0,
    int size = 20,
  }) async {
    final uri = Uri.parse('${ApiConfig.movimentosEstoqueUrl}/tipo/$tipo')
        .replace(queryParameters: {'page': '$page', 'size': '$size'});
    final response = await http.get(uri, headers: ApiConfig.defaultHeaders);
    final body = _parseResponse(response);
    return PaginaMovimentos.fromJson(body['dados'] as Map<String, dynamic>);
  }

  // ─── Auxiliar ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['sucesso'] != true) {
      throw Exception(body['erro'] ?? 'Erro desconhecido');
    }
    return body;
  }
}