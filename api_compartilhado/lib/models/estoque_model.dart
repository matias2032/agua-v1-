class EstoqueModel {
  final int idEstoque;
  final double litrosDisponiveis;
  final DateTime? ultimaAtualizacao;
  final String? observacao;

  const EstoqueModel({
    required this.idEstoque,
    required this.litrosDisponiveis,
    this.ultimaAtualizacao,
    this.observacao,
  });

  factory EstoqueModel.fromJson(Map<String, dynamic> json) {
    return EstoqueModel(
      idEstoque: json['idEstoque'] as int,
      litrosDisponiveis: (json['litrosDisponiveis'] as num).toDouble(),
      ultimaAtualizacao: json['ultimaAtualizacao'] != null
          ? DateTime.parse(json['ultimaAtualizacao'] as String)
          : null,
      observacao: json['observacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idEstoque': idEstoque,
      'litrosDisponiveis': litrosDisponiveis,
      'ultimaAtualizacao': ultimaAtualizacao?.toIso8601String(),
      'observacao': observacao,
    };
  }

  EstoqueModel copyWith({
    int? idEstoque,
    double? litrosDisponiveis,
    DateTime? ultimaAtualizacao,
    String? observacao,
  }) {
    return EstoqueModel(
      idEstoque: idEstoque ?? this.idEstoque,
      litrosDisponiveis: litrosDisponiveis ?? this.litrosDisponiveis,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      observacao: observacao ?? this.observacao,
    );
  }

  @override
  String toString() =>
      'EstoqueModel(idEstoque: $idEstoque, litrosDisponiveis: $litrosDisponiveis)';
}