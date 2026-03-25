import 'package:decimal/decimal.dart';

/// Espelha [ProdutoDTO.Disponibilidade] do backend Java.
/// A quantidade_disponivel é calculada pelo banco:
///   FLOOR(litros_disponiveis / capacidade_litros)
///
/// Exemplo com 40 L de estoque:
///   Galão 6L  → quantidadeDisponivel = 6  (sobram 4 L)
///   Galão 18L → quantidadeDisponivel = 2  (sobram 4 L)
class DisponibilidadeProdutoModel {
  final int idProduto;
  final String nomeProduto;
  final Decimal capacidadeLitros;
  final Decimal precoCompra;
  final Decimal precoReenchimento;
  final Decimal litrosDisponiveis;
  final int quantidadeDisponivel;

  const DisponibilidadeProdutoModel({
    required this.idProduto,
    required this.nomeProduto,
    required this.capacidadeLitros,
    required this.precoCompra,
    required this.precoReenchimento,
    required this.litrosDisponiveis,
    required this.quantidadeDisponivel,
  });

  bool get temEstoque => quantidadeDisponivel > 0;

  factory DisponibilidadeProdutoModel.fromJson(Map<String, dynamic> json) {
    return DisponibilidadeProdutoModel(
      idProduto: json['idProduto'] as int,
      nomeProduto: json['nomeProduto'] as String,
      capacidadeLitros: Decimal.parse(json['capacidadeLitros'].toString()),
      precoCompra: Decimal.parse(json['precoCompra'].toString()),
      precoReenchimento: Decimal.parse(json['precoReenchimento'].toString()),
      litrosDisponiveis: Decimal.parse(json['litrosDisponiveis'].toString()),
      quantidadeDisponivel: json['quantidadeDisponivel'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'idProduto': idProduto,
        'nomeProduto': nomeProduto,
        'capacidadeLitros': capacidadeLitros.toString(),
        'precoCompra': precoCompra.toString(),
        'precoReenchimento': precoReenchimento.toString(),
        'litrosDisponiveis': litrosDisponiveis.toString(),
        'quantidadeDisponivel': quantidadeDisponivel,
      };

  @override
  String toString() =>
      'DisponibilidadeProdutoModel(id: $idProduto, nome: $nomeProduto, '
      'disponivel: $quantidadeDisponivel un.)';
}