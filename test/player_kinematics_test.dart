import 'dart:ui';

import 'package:elements/game/systems/player_kinematics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = PlayerMotionConfig();

  MotionBody standingOnGround() {
    return MotionBody(
      x: 100,
      y: 200,
      width: config.width,
      height: config.height,
      grounded: true,
      coyote: config.coyoteTime,
    );
  }

  final ground = Rect.fromLTWH(0, 248, 800, 80);

  test('player cannot fall through a floor', () {
    final body = standingOnGround();
    body.grounded = false;
    for (var i = 0; i < 20; i++) {
      PlayerKinematics.step(
        body: body,
        config: config,
        dt: 1 / 60,
        horizontal: 0,
        jumpRequested: false,
        solids: [ground],
      );
    }
    expect(body.y + body.height, closeTo(ground.top, 0.01));
    expect(body.grounded, isTrue);
    expect(body.vy, 0);
  });

  test('player cannot walk through a wall', () {
    final wall = Rect.fromLTWH(200, 0, 40, 400);
    final body = standingOnGround();
    for (var i = 0; i < 40; i++) {
      PlayerKinematics.step(
        body: body,
        config: config,
        dt: 1 / 60,
        horizontal: 1,
        jumpRequested: false,
        solids: [ground, wall],
      );
    }
    expect(body.x + body.width, closeTo(wall.left, 0.01));
    expect(body.vx, 0);
  });

  test('jump leaves the ground then lands again', () {
    final body = standingOnGround();
    PlayerKinematics.step(
      body: body,
      config: config,
      dt: 1 / 60,
      horizontal: 0,
      jumpRequested: true,
      solids: [ground],
    );
    expect(body.grounded, isFalse);
    expect(body.vy, lessThan(0));

    final peakY = body.y;
    var minY = body.y;
    for (var i = 0; i < 180; i++) {
      PlayerKinematics.step(
        body: body,
        config: config,
        dt: 1 / 60,
        horizontal: 0,
        jumpRequested: false,
        solids: [ground],
      );
      if (body.y < minY) {
        minY = body.y;
      }
    }
    expect(minY, lessThan(peakY - 80));
    expect(body.grounded, isTrue);
    expect(body.y + body.height, closeTo(ground.top, 0.01));
  });
}
