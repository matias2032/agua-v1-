import 'package:decimal/decimal.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


/// Espelha [PrecoProdutoDTO] do backend Java.
/// Retornado por GET /api/produtos/{id}/preco?operacaoId={idOperacao}
///
/// precoFinal = precoBase × fatorPreco  (arredondado a 2 casas pelo Java)
class PrecoProdutoModel {
  final int idProduto;
  final String nomeProduto;
  final int idOperacao;
  final String nomeOperacao;
  final Decimal precoBase;
  final Decimal fatorPreco;
  final Decimal precoFinal;

  const PrecoProdutoModel({
    required this.idProduto,
    required this.nomeProduto,
    required this.idOperacao,
    required this.nomeOperacao,
    required this.precoBase,
    required this.fatorPreco,
    required this.precoFinal,
  });

  factory PrecoProdutoModel.fromJson(Map<String, dynamic> json) {
    return PrecoProdutoModel(
      idProduto: json['idProduto'] as int,
      nomeProduto: json['nomeProduto'] as String,
      idOperacao: json['idOperacao'] as int,
      nomeOperacao: json['nomeOperacao'] as String,
      precoBase: Decimal.parse(json['precoBase'].toString()),
      fatorPreco: Decimal.parse(json['fatorPreco'].toString()),
      precoFinal: Decimal.parse(json['precoFinal'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'idProduto': idProduto,
        'nomeProduto': nomeProduto,
        'idOperacao': idOperacao,
        'nomeOperacao': nomeOperacao,
        'precoBase': precoBase.toString(),
        'fatorPreco': fatorPreco.toString(),
        'precoFinal': precoFinal.toString(),
      };

  @override
  String toString() =>
      'PrecoProdutoModel($nomeProduto / $nomeOperacao → $precoFinal MT)';
}