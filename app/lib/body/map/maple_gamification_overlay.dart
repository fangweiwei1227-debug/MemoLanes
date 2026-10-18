import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:memolanes/common/gps_manager.dart';

class MapleGamificationOverlay extends StatefulWidget {
  const MapleGamificationOverlay({super.key});

  @override
  State<MapleGamificationOverlay> createState() =>
      _MapleGamificationOverlayState();
}

class _MapleGamificationOverlayState extends State<MapleGamificationOverlay> {
  int _mesos = 0;
  final List<_Mob> _mobs = [];
  final List<_Dmg> _dmgs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _spawnMob('slime');
      _spawnMob('mushroom');
    });
  }

  void _spawnMob(String type) {
    if (_mobs.length >= 4) return;
    final r = Random();
    final size = MediaQuery.of(context).size;
    final angle = r.nextDouble() * 2 * pi;
    final dist = 90.0 + r.nextDouble() * 110.0;
    final x = (size.width / 2) + cos(angle) * dist - 25;
    final y = (size.height / 2) + sin(angle) * dist - 25;

    setState(() {
      _mobs.add(_Mob(
        id: DateTime.now().microsecondsSinceEpoch,
        type: type,
        pos: Offset(x, y),
      ));
    });
  }

  void _hitMob(_Mob mob) {
    HapticFeedback.heavyImpact();
    final dmgVal = 77777 + Random().nextInt(22222);

    setState(() {
      _dmgs.add(_Dmg(
        id: DateTime.now().microsecondsSinceEpoch,
        text: '$dmgVal',
        pos: Offset(mob.pos.dx, mob.pos.dy - 20),
      ));
      _mobs.remove(mob);
      _mesos += 100 + Random().nextInt(250);
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _dmgs.removeWhere(
              (d) => DateTime.now().microsecondsSinceEpoch - d.id > 800000);
        });
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _spawnMob(Random().nextBool() ? 'slime' : 'mushroom');
    });
  }

  @override
  Widget build(BuildContext context) {
    final gps = Provider.of<GpsManager>(context);
    final speed = (gps.latestPosition?.speed ?? 0.0) * 3.6;

    final avatarIcon =
        speed > 15 ? '\u{1F417}' : (speed > 2 ? '\u{1F3C3}' : '\u{1F6B6}');
    final avatarTitle = speed > 15
        ? '\u4E58\u9A91\u91CE\u732A'
        : (speed > 2 ? '\u98DE\u5954\u4E2D' : '\u5192\u9669\u8005');

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.2),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Center(
                  child: Text(
                    avatarIcon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.top(4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  avatarTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._mobs.map((m) => Positioned(
              left: m.pos.dx,
              top: m.pos.dy,
              child: GestureDetector(
                onTap: () => _hitMob(m),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    m.type == 'slime' ? '\u{1F7E2}' : '\u{1F344}',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            )),
        ..._dmgs.map((d) => Positioned(
              left: d.pos.dx,
              top: d.pos.dy,
              child: Text(
                'CRITICAL! ${d.text}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.orangeAccent,
                  shadows: [
                    Shadow(
                        color: Colors.red,
                        offset: Offset(2, 2),
                        blurRadius: 2),
                    Shadow(
                        color: Colors.black,
                        offset: Offset(-1, -1),
                        blurRadius: 2),
                  ],
                ),
              ),
            )),
        Positioned(
          top: 60,
          left: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xE61E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1FA99}', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '$_mesos \u67AB\u5E01',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Mob {
  final int id;
  final String type;
  final Offset pos;
  _Mob({required this.id, required this.type, required this.pos});
}

class _Dmg {
  final int id;
  final String text;
  final Offset pos;
  _Dmg({required this.id, required this.text, required this.pos});
}
