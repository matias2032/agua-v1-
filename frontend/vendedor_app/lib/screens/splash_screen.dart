// lib/screens/splash_screen.dart

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

import '../firebase_options.dart';
import '../widgets/connection_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta — idêntica ao LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

const _kBg            = Color(0xFF0A0E1A);
const _kSurface       = Color(0xFF111827);
const _kCard          = Color(0xFF161D2E);
const _kCardBorder    = Color(0xFF1E2A42);
const _kAccent        = Color(0xFF00C9FF);
const _kAccentDeep    = Color(0xFF0099CC);
const _kTextPrimary   = Color(0xFFF0F4FF);
const _kTextSecondary = Color(0xFF8899BB);
const _kSuccess       = Color(0xFF00E5A0);
const _kWarning       = Color(0xFFFFB547);
const _kDanger        = Color(0xFFFF4D6A);

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de log
// ─────────────────────────────────────────────────────────────────────────────

enum _LogLevel { info, success, warning, error }

class _LogEntry {
  final String message;
  final _LogLevel level;
  final DateTime timestamp;
  const _LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animações ──────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _fillCtrl;
  late final AnimationController _dropCtrl;
  late final AnimationController _checkCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _waveAnim;
  late final Animation<double> _fillAnim;
  late final Animation<double> _dropPulse;
  late final Animation<double> _checkScale;

  // ── Estado ─────────────────────────────────────────────────────────────────
  double _progress    = 0.0;
  String _statusLabel = 'A iniciar…';
  final List<_LogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();
  bool _concluido   = false;
  bool _semConexao  = false;
  bool _modoOffline = false;

  static const _etapas = [
    (label: 'Verificar conectividade',  peso: 0.10),
    (label: 'Inicializar Firebase',     peso: 0.20),
    (label: 'Carregar configuração',    peso: 0.10),
    (label: 'Verificar estoque',        peso: 0.20),
    (label: 'Sincronizar pedidos',      peso: 0.20),
    (label: 'Processar fila offline',   peso: 0.10),
    (label: 'Finalizar',                peso: 0.10),
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2400))..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_waveCtrl);

    _fillCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _fillAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut));

    _dropCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _dropPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _dropCtrl, curve: Curves.easeInOut));

    _checkCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(
        parent: _checkCtrl, curve: Curves.elasticOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _waveCtrl.dispose();
    _fillCtrl.dispose();
    _dropCtrl.dispose();
    _checkCtrl.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  // ── Utilitários ────────────────────────────────────────────────────────────

  void _addLog(String msg, {_LogLevel level = _LogLevel.info}) {
    if (!mounted) return;
    setState(() {
      _logs.add(_LogEntry(
          message: msg, level: level, timestamp: DateTime.now()));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(_logScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _setProgress(double target, String label) async {
    if (!mounted) return;
    final clamped = target.clamp(0.0, 1.0);
    setState(() {
      _progress = clamped;
      _statusLabel = label;
    });
    _fillCtrl.animateTo(clamped,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOut);
    await Future.delayed(const Duration(milliseconds: 130));
  }

  // ── Fluxo de inicialização ─────────────────────────────────────────────────

  Future<void> _inicializar() async {
    double acumulado = 0.0;
    try {
      // ETAPA 1 — Conectividade
      acumulado += _etapas[0].peso;
      await _setProgress(acumulado, _etapas[0].label);
      _addLog('🔌 Verificando estado da rede…');
      await ConnectivityService.instance.inicializar();
      final online = ConnectivityService.instance.estaOnline;
      if (online) {
        _addLog('✅ Rede disponível.', level: _LogLevel.success);
      } else {
        _addLog('⚠️  Sem ligação — modo offline activado.',
            level: _LogLevel.warning);
        setState(() => _modoOffline = true);
      }

      // ETAPA 2 — Firebase
      acumulado += _etapas[1].peso;
      await _setProgress(acumulado, _etapas[1].label);
      _addLog('🔥 A inicializar Firebase…');
  try {
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
        _addLog('✅ Firebase inicializado.', level: _LogLevel.success);
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _addLog('💾 Persistência offline activada.', level: _LogLevel.info);
      } on FirebaseException catch (e) {
        _addLog('❌ Falha Firebase: ${e.message}', level: _LogLevel.error);
        if (!online) {
          _addLog('🔄 Continuando em modo offline…',
              level: _LogLevel.warning);
        } else {
          rethrow;
        }
      }

      // ETAPA 3 — Configuração API
      acumulado += _etapas[2].peso;
      await _setProgress(acumulado, _etapas[2].label);
      _addLog('⚙️  Carregando configuração do servidor…');
      _addLog('   ↳ host: localhost:8080 | db: agua(v1)',
          level: _LogLevel.info);
      _addLog('   ↳ fuso: Africa/Maputo (UTC+2)', level: _LogLevel.info);
      await Future.delayed(const Duration(milliseconds: 280));
      _addLog('✅ Configuração carregada.', level: _LogLevel.success);

      // ETAPA 4 — Estoque
      acumulado += _etapas[3].peso;
      await _setProgress(acumulado, _etapas[3].label);
      _addLog('📦 Lendo snapshot de estoque…');
      try {
        final estoque =
            await FirebaseListenerService.instance.lerEstoqueUmaVez();
        if (estoque != null) {
          _addLog(
              '✅ Estoque: ${estoque.litrosDisponiveis.toStringAsFixed(0)} L disponíveis.',
              level: _LogLevel.success);
        } else {
          _addLog('⚠️  Estoque não encontrado (cache/servidor).',
              level: _LogLevel.warning);
        }
      } catch (e) {
        _addLog('⚠️  Estoque indisponível: $e', level: _LogLevel.warning);
      }

      // ETAPA 5 — Pedidos
      acumulado += _etapas[4].peso;
      await _setProgress(acumulado, _etapas[4].label);
      _addLog('📋 Sincronizando pedidos pendentes…');
      try {
        final pedidos = await FirebaseListenerService.instance
            .lerPedidosUmaVez(status: 'pendente');
        _addLog('✅ ${pedidos.length} pedido(s) carregado(s).',
            level: _LogLevel.success);
      } catch (e) {
        _addLog('⚠️  Pedidos indisponíveis: $e', level: _LogLevel.warning);
      }

      // ETAPA 6 — Fila offline
      acumulado += _etapas[5].peso;
      await _setProgress(acumulado, _etapas[5].label);
      _addLog('🔄 Inicializando fila de sincronização…');
      await SyncQueueService.instance.inicializar();
      final pendentes = SyncQueueService.instance.totalPendentes;
      if (pendentes > 0) {
        _addLog('⚠️  $pendentes operação(ões) aguardam sync.',
            level: _LogLevel.warning);
        if (online) {
          _addLog('🚀 Reenviando operações pendentes…',
              level: _LogLevel.info);
          await SyncQueueService.instance.retentar();
        }
      } else {
        _addLog('✅ Fila de sync limpa.', level: _LogLevel.success);
      }

      // ETAPA 7 — Finalizar
      acumulado = 1.0;
      await _setProgress(acumulado, 'Pronto!');
      _addLog('🎉 AquaStore pronta!', level: _LogLevel.success);

      _dropCtrl.stop();
      _waveCtrl.stop();
      setState(() => _concluido = true);
      _checkCtrl.forward();
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _addLog('❌ Erro crítico: $e', level: _LogLevel.error);
      setState(() => _semConexao = true);
    }
  }

  // ── Acções do banner ───────────────────────────────────────────────────────

  Future<void> _onReconectar() async {
    setState(() {
      _semConexao = false;
      _logs.clear();
      _progress = 0.0;
      _statusLabel = 'A reiniciar…';
      _concluido = false;
    });
    _fillCtrl.reset();
    _checkCtrl.reset();
    _dropCtrl.repeat(reverse: true);
    _waveCtrl.repeat();
    await _inicializar();
  }

  void _onContinuarOffline() {
    setState(() {
      _semConexao = false;
      _modoOffline = true;
    });
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          children: [
            // Gradiente radial de fundo — igual ao mood da login
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 1.1,
                    colors: [
                      _kAccent.withOpacity(0.06),
                      _kBg,
                    ],
                  ),
                ),
              ),
            ),

            FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // ── Marca da app ─────────────────────────────────────
                    _buildBrand(),

                    const SizedBox(height: 32),

                    // ── Gota d'água ──────────────────────────────────────
                    _buildDropIndicator(),

                    const SizedBox(height: 18),

                    // ── Status + percentagem ─────────────────────────────
                    _buildStatusArea(),

                    const SizedBox(height: 16),

                    // ── Pontos de etapas ─────────────────────────────────
                    _buildStepDots(),

                    const SizedBox(height: 18),

                    // ── Painel de logs ───────────────────────────────────
                    Expanded(child: _buildLogPanel()),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Banner de conexão
            if (_semConexao)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: ConnectionBanner(
                  onReconnect: _onReconectar,
                  onContinueOffline: _onContinuarOffline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Marca da app ───────────────────────────────────────────────────────────

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _kAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.15),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.water_drop_outlined,
              color: _kAccent, size: 26),
        ),
        const SizedBox(height: 12),
        const Text(
          'AquaStore',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'A carregar o sistema…',
          style: TextStyle(fontSize: 12, color: _kTextSecondary),
        ),
      ],
    );
  }

  // ── Gota d'água com nível animado ──────────────────────────────────────────

  Widget _buildDropIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_waveAnim, _fillAnim, _dropPulse, _checkScale]),
      builder: (_, __) {
        return Transform.scale(
          scale: _concluido ? 1.0 : _dropPulse.value,
          child: SizedBox(
            width: 136,
            height: 136,
            child: CustomPaint(
              painter: _WaterDropPainter(
                progress: _fillAnim.value,
                wavePhase: _waveAnim.value,
                isDone: _concluido,
                checkProgress: _checkScale.value,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Label de status e percentagem ─────────────────────────────────────────

  Widget _buildStatusArea() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            _statusLabel,
            key: ValueKey(_statusLabel),
            style: const TextStyle(
              fontSize: 13,
              color: _kTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${(_progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _concluido ? _kSuccess : _kAccent,
            fontFamily: 'Georgia',
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  // ── Pontos indicadores de etapa ────────────────────────────────────────────

  Widget _buildStepDots() {
    double acumulado = 0.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_etapas.length, (i) {
        final antes = acumulado;
        acumulado += _etapas[i].peso;
        final done   = _progress >= acumulado - 0.005;
        final active = !done && _progress > antes;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width:  active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: done
                ? _kSuccess
                : active
                    ? _kAccent
                    : _kCardBorder,
            boxShadow: active || done
                ? [BoxShadow(
                    color: (done ? _kSuccess : _kAccent).withOpacity(0.4),
                    blurRadius: 6,
                  )]
                : null,
          ),
        );
      }),
    );
  }

  // ── Painel de logs ─────────────────────────────────────────────────────────

  Widget _buildLogPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.terminal_rounded,
                      size: 13, color: _kAccent),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sistema de Arranque',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: _kTextSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kCardBorder),
                  ),
                  child: Text(
                    '${_logs.length} logs',
                    style: const TextStyle(
                      fontSize: 10,
                      color: _kTextSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _kCardBorder),

          // Área de logs
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Aguardando…',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: _kTextSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _logScroll,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) => _buildLogItem(_logs[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(_LogEntry entry) {
    Color textColor;
    switch (entry.level) {
      case _LogLevel.success: textColor = _kSuccess;
      case _LogLevel.warning: textColor = _kWarning;
      case _LogLevel.error:   textColor = _kDanger;
      default:                textColor = _kTextSecondary;
    }

    final t = entry.timestamp;
    final ts = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ts,
              style: TextStyle(
                fontSize: 9.5,
                fontFamily: 'monospace',
                color: _kTextSecondary.withOpacity(0.4),
              )),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.message,
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  color: textColor,
                  height: 1.45,
                )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter — Gota d'água com nível de água animado
// ─────────────────────────────────────────────────────────────────────────────

class _WaterDropPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final bool isDone;
  final double checkProgress;

  const _WaterDropPainter({
    required this.progress,
    required this.wavePhase,
    required this.isDone,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final activeColor = isDone ? _kSuccess : _kAccent;

    // 1. Glow exterior
    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 2),
          width: size.width * 0.78,
          height: size.height * 0.78),
      glowPaint,
    );

    // 2. Caminho da gota
    final dropPath = _buildDropPath(size);

    // Fundo da gota
    canvas.drawPath(dropPath, Paint()..color = _kSurface);

    // Borda brilhante
    canvas.drawPath(
      dropPath,
      Paint()
        ..color = activeColor.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 3. Água com onda (clipada à gota)
    if (progress > 0.005) {
      canvas.save();
      canvas.clipPath(dropPath);

      final bounds = dropPath.getBounds();
      final waterTop = bounds.bottom - (bounds.height * progress);

      final waveAmplitude = isDone ? 1.5 : 4.5;
      final waterPath = Path()
        ..moveTo(bounds.left - 10, waterTop);

      const steps = 80;
      for (int i = 0; i <= steps; i++) {
        final x = bounds.left + (bounds.width * i / steps);
        final t = i / steps;
        final y = waterTop +
            math.sin(wavePhase + t * 3.2 * math.pi) * waveAmplitude +
            math.sin(wavePhase * 1.4 + t * 2.1 * math.pi) *
                (waveAmplitude * 0.45);
        waterPath.lineTo(x, y);
      }

      waterPath
        ..lineTo(bounds.right + 10, bounds.bottom + 10)
        ..lineTo(bounds.left - 10, bounds.bottom + 10)
        ..close();

      canvas.drawPath(
        waterPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDone
                ? [_kSuccess.withOpacity(0.88), _kSuccess.withOpacity(0.55)]
                : [_kAccent.withOpacity(0.88), _kAccentDeep.withOpacity(0.65)],
          ).createShader(Rect.fromLTWH(
              bounds.left, waterTop, bounds.width, bounds.bottom - waterTop)),
      );

      canvas.restore();
    }

    // 4. Conteúdo central
    if (isDone && checkProgress > 0) {
      final s = 18.0 * checkProgress.clamp(0.0, 1.0);
      canvas.drawPath(
        Path()
          ..moveTo(cx - s * 0.55, cy + 2)
          ..lineTo(cx - s * 0.08, cy + s * 0.55)
          ..lineTo(cx + s * 0.55, cy - s * 0.45),
        Paint()
          ..color = Colors.white.withOpacity(checkProgress.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (!isDone && progress > 0.02) {
      final pct = (progress * 100).toInt();
      final tp = TextPainter(
        text: TextSpan(
          text: '$pct',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: progress > 0.52
                ? Colors.white.withOpacity(0.92)
                : _kAccent.withOpacity(0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(cx - tp.width / 2, cy - tp.height / 2 + 5));
    }
  }

  Path _buildDropPath(Size size) {
    final w  = size.width  * 0.70;
    final h  = size.height * 0.82;
    final cx = size.width  / 2;
    final top = (size.height - h) / 2 - 2.0;

    return Path()
      ..moveTo(cx, top)
      ..cubicTo(
        cx - w * 0.04, top + h * 0.22,
        cx - w / 2,    top + h * 0.44,
        cx - w / 2,    top + h * 0.70,
      )
      ..quadraticBezierTo(cx - w / 2, top + h, cx, top + h)
      ..quadraticBezierTo(cx + w / 2, top + h, cx + w / 2, top + h * 0.70)
      ..cubicTo(
        cx + w / 2,    top + h * 0.44,
        cx + w * 0.04, top + h * 0.22,
        cx,            top,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_WaterDropPainter old) =>
      old.progress != progress ||
      old.wavePhase != wavePhase ||
      old.isDone    != isDone    ||
      old.checkProgress != checkProgress;
}