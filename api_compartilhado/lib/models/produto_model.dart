import 'package:decimal/decimal.dart';

/// Espelha [ProdutoDTO.Response] do backend Java.
class ProdutoModel {
  final int idProduto;
  final String nomeProduto;
  final String? descricao;
  final Decimal precoCompra;
  final Decimal precoReenchimento;
  final Decimal capacidadeLitros;
  final bool ativo;

  const ProdutoModel({
    required this.idProduto,
    required this.nomeProduto,
    this.descricao,
    required this.precoCompra,
    required this.precoReenchimento,
    required this.capacidadeLitros,
    required this.ativo,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      idProduto: json['idProduto'] as int,
      nomeProduto: json['nomeProduto'] as String,
      descricao: json['descricao'] as String?,
      precoCompra: Decimal.parse(json['precoCompra'].toString()),
      precoReenchimento: Decimal.parse(json['precoReenchimento'].toString()),
      capacidadeLitros: Decimal.parse(json['capacidadeLitros'].toString()),
      ativo: json['ativo'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'idProduto': idProduto,
        'nomeProduto': nomeProduto,
        'descricao': descricao,
        'precoCompra': precoCompra.toString(),
        'precoReenchimento': precoReenchimento.toString(),
        'capacidadeLitros': capacidadeLitros.toString(),
        'ativo': ativo,
      };

  ProdutoModel copyWith({
    int? idProduto,
    String? nomeProduto,
    String? descricao,
    Decimal? precoCompra,
    Decimal? precoReenchimento,
    Decimal? capacidadeLitros,
    bool? ativo,
  }) {
    return ProdutoModel(
      idProduto: idProduto ?? this.idProduto,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      descricao: descricao ?? this.descricao,
      precoCompra: precoCompra ?? this.precoCompra,
      precoReenchimento: precoReenchimento ?? this.precoReenchimento,
      capacidadeLitros: capacidadeLitros ?? this.capacidadeLitros,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() =>
      'ProdutoModel(id: $idProduto, nome: $nomeProduto, ativo: $ativo)';
}