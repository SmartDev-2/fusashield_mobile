import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

// ─── Model Pesan ──────────────────────────────────────────────────────────────
class _Msg {
  final bool isUser;
  final String text;
  final DateTime time;

  const _Msg({required this.isUser, required this.text, required this.time});
}

// ─── Quick Chip berdasarkan kondisi lapangan ───────────────────────────────────
List<String> _quickChips(LiveStore ls) {
  final sens = ls.status?['sensors'] as Map? ?? {};
  final dec  = ls.status?['decision'] as Map? ?? {};
  final chips = <String>[];

  chips.add('Apa status tanaman saya sekarang?');

  final hum = sens['humidity'];
  if (hum is num && hum > 75) {
    chips.add('Kelembapan ${hum.toStringAsFixed(0)}% — apakah berbahaya?');
  }

  final tingkat = dec['tingkat_dosis']?.toString() ?? '';
  if (tingkat.isNotEmpty && tingkat != '–') {
    chips.add('Kenapa keputusan fuzzy: $tingkat?');
  }

  final cnn = dec['cnn_label']?.toString() ?? '';
  if (cnn.isNotEmpty && cnn != '–') {
    chips.add('Jelaskan hasil CNN: $cnn');
  }

  final cooldown = dec['sisa_cooldown_detik'];
  if (cooldown is num && cooldown > 0) {
    chips.add('Kenapa pompa cooldown ${cooldown.toInt()} detik?');
  }

  chips.add('Cara mencegah Fusarium dengan Trichoderma?');
  chips.add('Kapan waktu terbaik menyiram tanaman?');

  return chips.take(5).toList();
}

// ─── ChatPage ─────────────────────────────────────────────────────────────────
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final _msgs   = <_Msg>[];

  bool _loading = false;

  // History dalam format Groq (maks 20 pesan = 10 giliran)
  List<Map<String, String>> get _history {
    final recent = _msgs.length > 20 ? _msgs.sublist(_msgs.length - 20) : _msgs;
    return recent
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _loading) return;

    HapticFeedback.selectionClick();
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(isUser: true, text: msg, time: DateTime.now()));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiService.instance.chat(
        message: msg,
        history: _history.length >= 2
            ? _history.sublist(0, _history.length - 1) // kirim history sebelum pesan ini
            : [],
      );
      final reply = (res['reply'] as String? ?? '').trim();
      setState(() {
        _msgs.add(_Msg(isUser: false, text: reply.isEmpty ? '(tidak ada respons)' : reply, time: DateTime.now()));
      });
    } on ApiException catch (e) {
      setState(() {
        _msgs.add(_Msg(isUser: false, text: '⚠️ ${e.message}', time: DateTime.now()));
      });
    } catch (e) {
      setState(() {
        _msgs.add(_Msg(isUser: false, text: '⚠️ Koneksi bermasalah. Coba lagi.', time: DateTime.now()));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveStore.instance,
      builder: (context, _) {
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _msgs.isEmpty ? _buildWelcome() : _buildMessageList(),
            ),
            if (_msgs.isEmpty) _buildChips(),
            _buildInputBar(),
          ],
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: AppColors.primary.o(0.4), blurRadius: 12)],
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FusaBot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Text('Asisten Agronomi Presisi · Realtime',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
            const Spacer(),
            if (_msgs.isNotEmpty)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _msgs.clear());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.o(0.10)),
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Halaman sambutan saat belum ada chat ─────────────────────────────────────
  Widget _buildWelcome() {
    final ls   = LiveStore.instance;
    final sens = ls.status?['sensors'] as Map? ?? {};
    final dec  = ls.status?['decision'] as Map? ?? {};

    final suhu = sens['temperature'];
    final hum  = sens['humidity'];
    final tingkat = dec['tingkat_dosis']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Kartu konteks sensor realtime
          if (ls.status != null)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.sensors_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text('Konteks Realtime FusaBot',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 10),
                  _SensorRow(icon: Icons.thermostat_rounded,
                      label: 'Suhu',
                      value: suhu != null ? '${LiveStore.fmt(suhu)}°C' : '–'),
                  _SensorRow(icon: Icons.water_drop_outlined,
                      label: 'Kelembapan',
                      value: hum != null ? '${LiveStore.fmt(hum)}%' : '–',
                      danger: hum is num && hum > 75),
                  if (tingkat != null && tingkat.isNotEmpty)
                    _SensorRow(icon: Icons.science_outlined,
                        label: 'Fuzzy',
                        value: tingkat),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Tanya apa saja tentang\ntanaman cabaimu 🌶️',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.3),
          ),
          const SizedBox(height: 8),
          const Text(
            'FusaBot membaca data sensor & hasil AI secara realtime\nsebelum menjawab pertanyaanmu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Quick chips ─────────────────────────────────────────────────────────────
  Widget _buildChips() {
    final chips = _quickChips(LiveStore.instance);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(chips[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.o(0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.o(0.30)),
            ),
            child: Text(
              chips[i],
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // ── Daftar gelembung chat ───────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _msgs.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (_loading && i == _msgs.length) return const _TypingBubble();
        return _ChatBubble(msg: _msgs[i]);
      },
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          radius: 36,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: AppColors.ink, fontSize: 14),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _loading ? null : _send,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tanya tentang tanaman cabaimu…',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _loading ? null : () => _send(_ctrl.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _loading
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.primaryLight, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _loading ? AppColors.muted.withAlpha(60) : null,
                    ),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gelembung chat ───────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]),
                boxShadow: [BoxShadow(color: AppColors.primary.o(0.3), blurRadius: 8)],
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : const Color(0xFF1A2E22),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4  : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.primary : Colors.black).o(0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isUser ? null : Border.all(color: Colors.white.o(0.08)),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isUser ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Animasi mengetik (tiga titik berdenyut) ─────────────────────────────────
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E22),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.white.o(0.08)),
            ),
            child: AnimatedBuilder(
              animation: _ac,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final t     = (_ac.value - delay).clamp(0.0, 1.0);
                    final alpha = (0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0));
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.o(alpha),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Baris sensor kecil di kartu konteks ────────────────────────────────────
class _SensorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool danger;

  const _SensorRow({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFB923C) : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: danger ? color : AppColors.ink)),
          if (danger) ...[
            const SizedBox(width: 4),
            Text('⚠️', style: const TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
