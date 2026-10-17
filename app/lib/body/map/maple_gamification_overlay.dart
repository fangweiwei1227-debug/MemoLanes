import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:memolanes/common/gps_manager.dart';

class MapleGamificationOverlay extends StatefulWidget {
  const MapleGamificationOverlay({super.key});

  @override
  State<MapleGamificationOverlay> createState() => _MapleGamificationOverlayState();
}

class _MapleGamificationOverlayState extends State<MapleGamificationOverlay> {
  int _mesos = 0;
  final List<_Mob> _mobs = [];
  final List<_Dmg> _dmgs = [];
  double _lastCheckedDist = 0;

  @override
  void initState() {
    super.initState();
    // 初始在角色周围刷一只绿水灵和一只花蘑菇
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
      _mobs.add(_Mob(id: DateTime.now().microsecondsSinceEpoch, type: type, pos: Offset(x, y)));
    });
  }

  void _hitMob(_Mob mob) {
    HapticFeedback.heavyImpact(); // 15u 线性马达震动，打击感拉满
    final dmgVal = 77777 + Random().nextInt(22222);

    setState(() {
      _dmgs.add(_Dmg(id: DateTime.now().microsecondsSinceEpoch, text: '$dmgVal', pos: Offset(mob.pos.dx, mob.pos.dy - 20)));
      _mobs.remove(mob);
      _mesos += 100 + Random().nextInt(250);
    });

    // 延时清除伤害数字
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _dmgs.removeWhere((d) => DateTime.now().microsecondsSinceEpoch - d.id > 800000);
        });
      }
    });

    // 几秒后在附近刷新下一只
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _spawnMob(Random().nextBool() ? 'slime' : 'mushroom');
    });
  }

  @override
  Widget build(BuildContext context) {
    final gps = Provider.of<GpsManager>(context);
    final speed = (gps.latestPosition?.speed ?? 0.0) * 3.6;

    return Stack(
      children: [
        // 1. 屏幕正中心：冒险岛像素主角小人
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
                    speed > 15 ? '🐗' : (speed > 2 ? '🏃' : '🚶'),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.top: 4,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  speed > 15 ? '乘骑野猪' : (speed > 2 ? '飞奔中' : '冒险者'),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // 2. 刷出的怪物（绿水灵 / 花蘑菇）
        ..._mobs.map((m) => Positioned(
          left: m.pos.dx,
          top: m.pos.dy,
          child: GestureDetector(
            onTap: () => _hitMob(m),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: Text(
                m.type == 'slime' ? '🟢' : '🍄',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        )),

        // 3. 经典暴击橙黄大字
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
                Shadow(color: Colors.red, offset: Offset(2, 2), blurRadius: 2),
                Shadow(color: Colors.black, offset: Offset(-1, -1), blurRadius: 2),
              ],
            ),
          ),
        )),

        // 4. 左上角复古枫币统计栏
        Positioned(
          top: 60,
          left: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xE61E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '$_mesos 枫币',
                  style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),
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
