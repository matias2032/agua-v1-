// lib/widgets/connection_banner.dart
//
// Widget reutilizável de notificação de conexão — tema AquaStore escuro.
// Paleta idêntica ao LoginScreen e SplashScreen.
//
// Uso:
//   ConnectionBanner(
//     onReconnect:       () async { … },
//     onContinueOffline: () { … },
//   )
//
// Variantes:
//   ConnectionBannerStyle.bottom     — barra fixa no fundo (padrão)
//   ConnectionBannerStyle.floating   — card flutuante com sombra
//   ConnectionBannerStyle.fullscreen — ocupa espaço disponível

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta — idêntica ao LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

const _kBg          = Color(0xFF0A0E1A);
const _kCard        = Color(0xFF161D2E);
const _kCardBorder  = Color(0xFF1E2A42);
const _kAccent      = Color(0xFF00C9FF);
const _kAccentDeep  = Color(0xFF0099CC);
const _kTextPrimary = Color(0xFFF0F4FF);
const _kTextSec     = Color(0xFF8899BB);
const _kDanger      = Color(0xFFFF4D6A);
const _kSuccess     = Color(0xFF00E5A0);

// ─────────────────────────────────────────────────────────────────────────────

enum ConnectionBannerStyle { bottom, floating, fullscreen }

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────

class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({
    super.key,
    required this.onReconnect,
    this.onContinueOffline,
    this.message,
    this.subtitle,
    this.showOfflineOption = true,
    this.style = ConnectionBannerStyle.bottom,
    this.isReconnecting = false,
  });

  final Future<void> Function() onReconnect;
  final VoidCallback? onContinueOffline;
  final String? message;
  final String? subtitle;
  final bool showOfflineOption;
  final ConnectionBannerStyle style;
  final bool isReconnecting;

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner>
    with SingleTickerProviderStateMixin {
  bool _reconnecting = false;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _reconnecting = widget.isReconnecting;

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(ConnectionBanner old) {
    super.didUpdateWidget(old);
    if (widget.isReconnecting != old.isReconnecting) {
      setState(() => _reconnecting = widget.isReconnecting);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReconnect() async {
    if (_reconnecting) return;
    setState(() => _reconnecting = true);
    try {
      await widget.onReconnect();
    } finally {
      if (mounted) setState(() => _reconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    switch (widget.style) {
      case ConnectionBannerStyle.bottom:
        return SlideTransition(position: _slideAnim, child: content);
      case ConnectionBannerStyle.floating:
        return SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              elevation: 8,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.hardEdge,
              child: content,
            ),
          ),
        );
      case ConnectionBannerStyle.fullscreen:
        return content;
    }
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kDanger, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ícone + Texto ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PulsingWifiIcon(reconnecting: _reconnecting),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message ?? 'Sem ligação à internet',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle ??
                          'Verifique a sua conexão e tente reconectar.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextSec,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Botões ─────────────────────────────────────────────────────
          Row(
            children: [
              // Reconectar — gradiente igual ao botão de login
              Expanded(
                child: GestureDetector(
                  onTap: _reconnecting ? null : _handleReconnect,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: _reconnecting
                          ? null
                          : const LinearGradient(
                              colors: [_kAccent, _kAccentDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _reconnecting ? _kCardBorder : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _reconnecting
                          ? null
                          : [
                              BoxShadow(
                                color: _kAccent.withOpacity(0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _reconnecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: _kTextSec, strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded,
                                    color: _kBg, size: 16),
                                SizedBox(width: 6),
                                Text('Reconectar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _kBg,
                                    )),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              // Continuar Offline
              if (widget.showOfflineOption) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _reconnecting ? null : widget.onContinueOffline,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _reconnecting
                              ? _kCardBorder
                              : _kCardBorder,
                        ),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_rounded,
                                color: _kTextSec, size: 15),
                            SizedBox(width: 6),
                            Text('Modo Offline',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextSec,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Barra de progresso durante reconexão
          if (_reconnecting)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: _kCardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ícone de wifi pulsante
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingWifiIcon extends StatefulWidget {
  const _PulsingWifiIcon({required this.reconnecting});
  final bool reconnecting;

  @override
  State<_PulsingWifiIcon> createState() => _PulsingWifiIconState();
}

class _PulsingWifiIconState extends State<_PulsingWifiIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.45, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = widget.reconnecting ? _kAccent : _kDanger;
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(_anim.value * 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withOpacity(_anim.value * 0.4)),
          ),
          child: Icon(
            widget.reconnecting
                ? Icons.wifi_find_rounded
                : Icons.wifi_off_rounded,
            color: color.withOpacity(0.9),
            size: 20,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OfflineChip — para AppBar ou qualquer tela
// ─────────────────────────────────────────────────────────────────────────────

/// Chip compacto com ícone para embutir na AppBar.
///
/// Exemplo:
///   actions: [ if (!isOnline) const OfflineChip() ]
class OfflineChip extends StatelessWidget {
  const OfflineChip({super.key, this.label = 'Offline', this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _kDanger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kDanger.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 12, color: _kDanger.withOpacity(0.9)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kDanger.withOpacity(0.9),
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mixin ConnectionAwareMixin
// ─────────────────────────────────────────────────────────────────────────────

/// Adicionar a qualquer State para reagir a mudanças de conectividade.
///
/// Exemplo:
///   class _MinhaTelaState extends State<MinhaTela>
///       with ConnectionAwareMixin<MinhaTela> { … }
mixin ConnectionAwareMixin<T extends StatefulWidget> on State<T> {
  bool get isOnline => _online;
  bool _online = true;

  void _handleChange(bool online) {
    if (!mounted) return;
    setState(() => _online = online);
    onConnectionChanged(online);
  }

  /// Sobrescrever para reagir a mudanças.
  void onConnectionChanged(bool online) {}
}