class MovimentoEstoqueModel {
  final int idMovimento;
  final int idUsuario;
  final int? idPedido;
  final String tipoMovimento;
  final double litrosMovimentados;
  final double litrosAnterior;
  final double litrosNovo;
  final String? motivo;
  final DateTime dataMovimento;
  final bool manual;

  const MovimentoEstoqueModel({
    required this.idMovimento,
    required this.idUsuario,
    this.idPedido,
    required this.tipoMovimento,
    required this.litrosMovimentados,
    required this.litrosAnterior,
    required this.litrosNovo,
    this.motivo,
    required this.dataMovimento,
    required this.manual,
  });

  bool get isEntrada => tipoMovimento == 'entrada';

  factory MovimentoEstoqueModel.fromJson(Map<String, dynamic> json) {
    return MovimentoEstoqueModel(
      idMovimento: json['idMovimento'] as int,
      idUsuario: json['idUsuario'] as int,
      idPedido: json['idPedido'] as int?,
      tipoMovimento: json['tipoMovimento'] as String,
      litrosMovimentados: (json['litrosMovimentados'] as num).toDouble(),
      litrosAnterior: (json['litrosAnterior'] as num).toDouble(),
      litrosNovo: (json['litrosNovo'] as num).toDouble(),
      motivo: json['motivo'] as String?,
      dataMovimento: DateTime.parse(json['dataMovimento'] as String),
      manual: json['manual'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMovimento': idMovimento,
      'idUsuario': idUsuario,
      'idPedido': idPedido,
      'tipoMovimento': tipoMovimento,
      'litrosMovimentados': litrosMovimentados,
      'litrosAnterior': litrosAnterior,
      'litrosNovo': litrosNovo,
      'motivo': motivo,
      'dataMovimento': dataMovimento.toIso8601String(),
      'manual': manual,
    };
  }

  @override
  String toString() =>
      'MovimentoEstoqueModel(idMovimento: $idMovimento, tipo: $tipoMovimento, litros: $litrosMovimentados)';
}