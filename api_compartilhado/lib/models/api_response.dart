/// Espelha o envelope [ApiResponse<T>] do backend Java.
/// Todas as respostas chegam no formato:
///   { "sucesso": true/false, "dados": {...}, "erro": "...", "timestamp": "..." }
class ApiResponse<T> {
  final bool sucesso;
  final T? dados;
  final String? erro;
  final String? timestamp;

  const ApiResponse({
    required this.sucesso,
    this.dados,
    this.erro,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      sucesso: json['sucesso'] as bool,
      dados: json['dados'] != null ? fromJsonT(json['dados']) : null,
      erro: json['erro'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }

  bool get temErro => !sucesso || erro != null;

  @override
  String toString() =>
      'ApiResponse(sucesso: $sucesso, erro: $erro)';
}