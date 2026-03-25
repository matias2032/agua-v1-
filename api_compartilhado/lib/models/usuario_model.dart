class UsuarioModel {
  final int     idUsuario;
  final String  nome;
  final String? apelido;
  final String  email;
  final String? telefone;
  final bool    ativo;
  final String  statusDescricao;
  final DateTime dataCadastro;
  final int     idPerfil;
  final bool    primeiraSenha;
 
  const UsuarioModel({
    required this.idUsuario,
    required this.nome,
    this.apelido,
    required this.email,
    this.telefone,
    required this.ativo,
    required this.statusDescricao,
    required this.dataCadastro,
    required this.idPerfil,
    required this.primeiraSenha,
  });
 
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      idUsuario:       json['idUsuario']       as int,
      nome:            json['nome']            as String,
      apelido:         json['apelido']         as String?,
      email:           json['email']           as String,
      telefone:        json['telefone']        as String?,
      ativo:           json['ativo']           as bool,
      statusDescricao: json['statusDescricao'] as String,
      dataCadastro:    DateTime.parse(json['dataCadastro'] as String),
      idPerfil:        json['idPerfil']        as int,
      primeiraSenha:   json['primeiraSenha']   as bool,
    );
  }
 
  Map<String, dynamic> toJson() => {
    'idUsuario':       idUsuario,
    'nome':            nome,
    'apelido':         apelido,
    'email':           email,
    'telefone':        telefone,
    'ativo':           ativo,
    'statusDescricao': statusDescricao,
    'dataCadastro':    dataCadastro.toIso8601String(),
    'idPerfil':        idPerfil,
    'primeiraSenha':   primeiraSenha,
  };
}