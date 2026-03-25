import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_compartilhado.dart';
import '../models/usuario_model.dart';
 
class UsuarioService {
 
  Uri _uri([String path = '']) =>
      Uri.parse('${ApiConfig.usuariosUrl}$path');
 
  Uri _authUri(String path) =>
      Uri.parse('${ApiConfig.authUrl}$path');
 
  // ── POST /api/auth/login ──────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String credencial,
    required String senha,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({'credencial': credencial, 'senha': senha}),
    ).timeout(ApiConfig.timeout);
 
    final json = jsonDecode(utf8.decode(response.bodyBytes));
 
    if (response.statusCode == 200) {
      return {
        'usuario':       UsuarioModel.fromJson(json['usuario']),
        'primeiraSenha': json['primeiraSenha'] as bool,
      };
    }
 
    throw Exception(json['message'] ?? 'Erro ao fazer login (${response.statusCode})');
  }
 
  // ── PATCH /api/auth/{id}/trocar-senha ─────────────────────────────
  Future<void> trocarSenha({required int id, required String novaSenha}) async {
    final response = await http.patch(
      _authUri('/$id/trocar-senha'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({'novaSenha': novaSenha}),
    ).timeout(ApiConfig.timeout);
 
    if (response.statusCode != 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['message'] ?? 'Erro ao trocar senha (${response.statusCode})');
    }
  }
 
  // ── PATCH /api/auth/{id}/alterar-senha ────────────────────────────
  Future<void> alterarSenha({
    required int    id,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final response = await http.patch(
      _authUri('/$id/alterar-senha'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
    ).timeout(ApiConfig.timeout);
 
    if (response.statusCode != 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['message'] ?? 'Erro ao alterar senha (${response.statusCode})');
    }
  }
 
  // ── GET /api/usuarios?perfil=2&ativo=true ─────────────────────────
  Future<List<UsuarioModel>> listarUsuarios({int? perfil, bool? ativo}) async {
    final params = <String, String>{};
    if (perfil != null) params['perfil'] = '$perfil';
    if (ativo  != null) params['ativo']  = '$ativo';
 
    final uri = _uri().replace(queryParameters: params.isEmpty ? null : params);
    final response = await http
        .get(uri, headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);
 
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((e) => UsuarioModel.fromJson(e)).toList();
    }
    throw Exception('Erro ao listar usuários (${response.statusCode})');
  }
 
  // ── GET /api/usuarios/{id} ────────────────────────────────────────
  Future<UsuarioModel> buscarPorId(int id) async {
    final response = await http
        .get(_uri('/$id'), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);
 
    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Usuário não encontrado (${response.statusCode})');
  }
 
  // ── POST /api/usuarios ────────────────────────────────────────────
  Future<UsuarioModel> criarUsuario({
  required String nome,
  required String apelido,
  required String email,
  String? telefone,
  String? senha,        // ← ADICIONAR
  int idPerfil = 3,
}) async {
  final body = jsonEncode({
    'nome': nome,
    'apelido': apelido,
    'email': email,
    'senha': senha ?? '12345678', // senha passada ou padrão para admin
    'telefone': telefone,
    'idPerfil': idPerfil,
  });

    final response = await http
        .post(
          _uri(),
          headers: ApiConfig.defaultHeaders,
          body: body,
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }

    // Extrai mensagem de erro do backend
    String erro = 'Erro ao cadastrar usuário (${response.statusCode})';
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      erro = json['message'] ?? json['error'] ?? erro;
    } catch (_) {}

    throw Exception(erro);
  }
 
  // ── PUT /api/usuarios/{id} ────────────────────────────────────────
  Future<UsuarioModel> atualizarUsuario({
    required int    id,
    required String nome,
    String?         apelido,
    required String email,
    String?         telefone,
    required int    idPerfil,
  }) async {
    final response = await http.put(
      _uri('/$id'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        'nome':     nome,
        'apelido':  apelido,
        'email':    email,
        'telefone': telefone,
        'idPerfil': idPerfil,
      }),
    ).timeout(ApiConfig.timeout);
 
    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Erro ao atualizar usuário (${response.statusCode})');
  }
 
  // ── PATCH /api/usuarios/{id}/toggle-status ────────────────────────
  Future<UsuarioModel> toggleStatus(int id) async {
    final response = await http
        .patch(_uri('/$id/toggle-status'), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);
 
    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Erro ao alterar status (${response.statusCode})');
  }
 
  // ── PATCH /api/usuarios/{id}/reset-password ───────────────────────
  Future<UsuarioModel> resetarSenha(int id) async {
    final response = await http
        .patch(_uri('/$id/reset-password'), headers: ApiConfig.defaultHeaders)
        .timeout(ApiConfig.timeout);
 
    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Erro ao resetar senha (${response.statusCode})');
  }
}
 
