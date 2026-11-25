import 'dart:math' as math;
import 'dart:ui';

import 'package:elements/models/element_type.dart';

/// Tunable platformer numbers for the Sprint 1 grey-box character.
class PlayerMotionConfig {
  const PlayerMotionConfig({
    this.gravity = 2000,
    this.moveSpeed = 220,
    this.jumpSpeed = 720,
    this.maxFallSpeed = 1400,
    this.coyoteTime = 0.08,
    this.width = 36,
    this.height = 48,
    this.maxStep = 1 / 30,
  });

  final double gravity;
  final double moveSpeed;
  final double jumpSpeed;
  final double maxFallSpeed;
  final double coyoteTime;
  final double width;
  final double height;
  final double maxStep;

  Size get size => Size(width, height);
}

class MotionBody {
  MotionBody({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    required this.width,
    required this.height,
    this.grounded = false,
    this.coyote = 0,
    this.facing = 1,
  });

  double x;
  double y;
  double vx;
  double vy;
  double width;
  double height;
  bool grounded;
  double coyote;
  int facing;

  Rect get aabb => Rect.fromLTWH(x, y, width, height);
}

/// Axis-aligned kinematic step, kept free of Flame so it can be unit-tested.
class PlayerKinematics {
  PlayerKinematics._();

  /// Returns true when a jump request was applied this step.
  static bool step({
    required MotionBody body,
    required PlayerMotionConfig config,
    required double dt,
    required double horizontal,
    required bool jumpRequested,
    required List<Rect> solids,
    ElementType element = ElementType.fire,
    bool inWater = false,
    double? waterSurfaceY,
    bool climbing = false,
    bool applyElementStats = true,
  }) {
    final clampedDt = math.min(dt, config.maxStep);
    final axis = horizontal.clamp(-1.0, 1.0).toDouble();

    if (axis.abs() > 0.01) {
      body.facing = axis > 0 ? 1 : -1;
    }

    var consumedJump = false;
    if (climbing && jumpRequested) {
      body.vy = -config.jumpSpeed * 0.82;
      body.grounded = false;
      body.coyote = 0;
      consumedJump = true;
      climbing = false;
    }

    if (climbing) {
      body.vx = 0;
      body.vy = -config.moveSpeed * 0.72;
      body.x += body.vx * clampedDt;
      body.y += body.vy * clampedDt;
      body.grounded = false;
      _resolveAxis(body, solids, horizontal: false);
      body.coyote = 0;
      return false;
    }

    final canSwimUp = inWater && element == ElementType.water;
    if (!consumedJump &&
        jumpRequested &&
        (body.grounded || body.coyote > 0 || canSwimUp)) {
      body.vy = inWater && element == ElementType.water
          ? -config.jumpSpeed * 0.55
          : -config.jumpSpeed *
                (applyElementStats ? element.jumpMultiplier : 1);
      body.grounded = false;
      body.coyote = 0;
      consumedJump = true;
    }

    final isSwimming = inWater && element == ElementType.water;
    body.vx =
        axis *
        config.moveSpeed *
        (applyElementStats ? element.speedMultiplier : 1) *
        (isSwimming ? 0.82 : 1);
    final gravity = isSwimming
        ? config.gravity * 0.3
        : config.gravity * (applyElementStats ? element.gravityMultiplier : 1);
    if (isSwimming && waterSurfaceY != null) {
      final submerged = ((body.y + body.height - waterSurfaceY) / body.height)
          .clamp(0.0, 1.0)
          .toDouble();
      final buoyancy = config.gravity * (0.20 + submerged * 0.20);
      body.vy += (gravity - buoyancy) * clampedDt;
      body.vy *= math.pow(0.16, clampedDt).toDouble();
    } else {
      body.vy += gravity * clampedDt;
    }
    final maxFallSpeed = isSwimming ? 110.0 : config.maxFallSpeed;
    if (body.vy > maxFallSpeed) {
      body.vy = maxFallSpeed;
    }
    if (isSwimming && body.vy < -config.jumpSpeed * 0.45) {
      body.vy = -config.jumpSpeed * 0.45;
    }

    body.x += body.vx * clampedDt;
    _resolveAxis(body, solids, horizontal: true);

    body.y += body.vy * clampedDt;
    body.grounded = false;
    _resolveAxis(body, solids, horizontal: false);

    if (body.grounded) {
      body.coyote = config.coyoteTime;
    } else {
      body.coyote = math.max(0, body.coyote - clampedDt);
    }
    return consumedJump;
  }

  static void _resolveAxis(
    MotionBody body,
    List<Rect> solids, {
    required bool horizontal,
  }) {
    var rect = body.aabb;
    for (final solid in solids) {
      if (!rect.overlaps(solid)) {
        continue;
      }
      if (horizontal) {
        if (body.vx > 0) {
          body.x = solid.left - body.width;
        } else if (body.vx < 0) {
          body.x = solid.right;
        } else {
          final overlapLeft = rect.right - solid.left;
          final overlapRight = solid.right - rect.left;
          body.x = overlapLeft < overlapRight
              ? solid.left - body.width
              : solid.right;
        }
        body.vx = 0;
      } else {
        if (body.vy > 0) {
          body.y = solid.top - body.height;
          body.vy = 0;
          body.grounded = true;
        } else if (body.vy < 0) {
          body.y = solid.bottom;
          body.vy = 0;
        } else {
          final overlapTop = rect.bottom - solid.top;
          final overlapBottom = solid.bottom - rect.top;
          if (overlapTop < overlapBottom) {
            body.y = solid.top - body.height;
            body.grounded = true;
          } else {
            body.y = solid.bottom;
          }
        }
      }
      rect = body.aabb;
    }
  }
}
