import 'package:decimal/decimal.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


/// Espelha [OperacaoDTO.Response] do backend Java.
/// Os dois tipos de operação (dados iniciais do banco):
///   id=1 → "Compra com recipiente novo"  fator=1.000
///   id=2 → "Reenchimento de recipiente"  fator=0.700
class OperacaoModel {
  final int idOperacao;
  final String nomeOperacao;
  final Decimal fatorPreco;
  final String? descricao;

  const OperacaoModel({
    required this.idOperacao,
    required this.nomeOperacao,
    required this.fatorPreco,
    this.descricao,
  });

  /// True quando é reenchimento (cliente traz o próprio recipiente).
  bool get isReenchimento => fatorPreco < Decimal.one;

  factory OperacaoModel.fromJson(Map<String, dynamic> json) {
    return OperacaoModel(
      idOperacao: json['idOperacao'] as int,
      nomeOperacao: json['nomeOperacao'] as String,
      fatorPreco: Decimal.parse(json['fatorPreco'].toString()),
      descricao: json['descricao'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'idOperacao': idOperacao,
        'nomeOperacao': nomeOperacao,
        'fatorPreco': fatorPreco.toString(),
        'descricao': descricao,
      };

  @override
  String toString() =>
      'OperacaoModel(id: $idOperacao, nome: $nomeOperacao, fator: $fatorPreco)';
}