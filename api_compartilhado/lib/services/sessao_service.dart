import '../models/usuario_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class SessaoService {
  static final SessaoService instance = SessaoService._init();
  SessaoService._init();

  // Propriedades privadas
  UsuarioModel? _usuarioAtual;
  int? _idUsuario;
  String? _nomeUsuario;
  bool _isLogado = false;
  String? _token;
String? get token => _token;


  // Controle de sessão
  static const String _keyUltimaSessao = 'ultima_sessao_timestamp';
  static const String _keyPrimeiroAcesso = 'primeiro_acesso_apos_init';

  // Timeout de sessão (30 minutos — ajustável)
  static const Duration _timeoutSessao = Duration(minutes: 30);

  // ── Getters públicos ──────────────────────────────────────────────────────

  UsuarioModel? get usuarioAtual => _usuarioAtual;
  int? get idUsuario => _idUsuario;
  String? get nomeUsuario => _nomeUsuario;
  bool get isLogado => _isLogado;

  // ── Controle de actividade ────────────────────────────────────────────────

  Future<void> marcarAppAtivo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _keyUltimaSessao,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('✅ Timestamp atualizado');
    } catch (e) {
      print('⚠️ Erro ao atualizar timestamp: $e');
    }
  }

  // ── Inicialização da sessão ───────────────────────────────────────────────

  /// Detecta task removal e restaura/invalida sessão conforme necessário.
  /// Lógica idêntica ao original — apenas o tipo do utilizador foi alterado.
  Future<void> inicializarSessao() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Verificar se é o primeiro acesso após task removal
      final primeiroAcesso = prefs.getBool(_keyPrimeiroAcesso) ?? true;

      if (primeiroAcesso) {
        print('🔄 Primeira inicialização detectada - limpando sessão anterior');
        await limparSessao();
        await prefs.setBool(_keyPrimeiroAcesso, false);
        return;
      }

      // 2. Verificar se existe sessão activa em memória
      final existeSessaoEmMemoria = _isLogado && _idUsuario != null;
      final idUsuarioSalvo = prefs.getInt('id_usuario');

      // 3. App foi morto pelo sistema (task removal) → invalida sessão
      if (!existeSessaoEmMemoria && idUsuarioSalvo != null) {
        print('⚠️ App foi encerrado pelo sistema - sessão invalidada');
        await limparSessao();
        await prefs.setBool(_keyPrimeiroAcesso, true);
        return;
      }

      // 4. Verificar timeout da sessão
      if (existeSessaoEmMemoria) {
        final ultimaSessaoTimestamp = prefs.getInt(_keyUltimaSessao);

        if (ultimaSessaoTimestamp != null) {
          final ultimaSessao =
              DateTime.fromMillisecondsSinceEpoch(ultimaSessaoTimestamp);
          final diferenca = DateTime.now().difference(ultimaSessao);

          if (diferenca > _timeoutSessao) {
            print(
              '⏱️ Sessão expirada (${diferenca.inMinutes} min) - requer novo login',
            );
            await limparSessao();
            return;
          }
        }
      }

      // 5. Restaurar ou manter sessão
      if (existeSessaoEmMemoria) {
        await marcarAppAtivo();
        print('✅ Sessão mantida: $_nomeUsuario (ID: $_idUsuario)');
      } else {
        if (idUsuarioSalvo != null) {
          final nomeUsuarioSalvo = prefs.getString('nome_usuario');

          if (nomeUsuarioSalvo != null) {
            _idUsuario = idUsuarioSalvo;
            _nomeUsuario = nomeUsuarioSalvo;
          
            _isLogado = true;

            await marcarAppAtivo();
            print('✅ Sessão restaurada: $_nomeUsuario (ID: $_idUsuario)');
          }
        } else {
          print('ℹ️ Nenhuma sessão encontrada');
          _isLogado = false;
        }
      }
    } catch (e) {
      print('❌ Erro ao inicializar sessão: $e');
      _isLogado = false;
    }
  }

  // ── Definir utilizador logado ─────────────────────────────────────────────

  /// Recebe UsuarioModel (novo) — assinatura equivalente ao original.
Future<void> setUsuario(UsuarioModel usuario, {String? token}) async {
  _usuarioAtual = usuario;
  _idUsuario = usuario.idUsuario;
  _nomeUsuario = usuario.nome;
  _isLogado = true;
  _token = token;

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('id_usuario', usuario.idUsuario);
    await prefs.setString('nome_usuario', usuario.nome);
    await prefs.setBool(_keyPrimeiroAcesso, false);
    if (token != null) await prefs.setString('token', token);
    await marcarAppAtivo();


    // Se não há sessionId, o carrinho será criado naturalmente ao adicionar produto
    // e associado ao utilizador via sessionId nesse momento

    print('✅ Sessão iniciada para ${usuario.nome} (ID: ${usuario.idUsuario})');
  } catch (e) {
    print('⚠️ Erro ao salvar sessão: $e');
  }
}

// Tornar público para ser chamável do CarrinhoService




  // ── Logout ────────────────────────────────────────────────────────────────

Future<void> limparSessao() async {
  _usuarioAtual = null;
  _idUsuario = null;
  _nomeUsuario = null;
  _isLogado = false;
  _token = null;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('id_usuario');
    await prefs.remove('nome_usuario');
    await prefs.remove(_keyUltimaSessao);
        print('✅ Sessão limpa');
  } catch (e) {
    print('⚠️ Erro ao limpar sessão: $e');
  }
}
  // ── Validação de sessão activa ────────────────────────────────────────────

  Future<bool> validarSessao() async {
    if (!_isLogado) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimaSessaoTimestamp = prefs.getInt(_keyUltimaSessao);

      if (ultimaSessaoTimestamp == null) return false;

      final ultimaSessao =
          DateTime.fromMillisecondsSinceEpoch(ultimaSessaoTimestamp);
      final diferenca = DateTime.now().difference(ultimaSessao);

      if (diferenca > _timeoutSessao) {
        print('⏱️ Sessão expirada durante validação');
        await limparSessao();
        return false;
      }

      await marcarAppAtivo();
      return true;
    } catch (e) {
      print('❌ Erro ao validar sessão: $e');
      return false;
    }
  }
}
