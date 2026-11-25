import 'package:flutter_riverpod/flutter_riverpod.dart';

class EconomyState {
  const EconomyState({this.elementShardBalance = 0});

  final int elementShardBalance;
}

final economyProvider = Provider<EconomyState>((ref) => const EconomyState());
