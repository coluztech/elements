import 'package:elements/models/element_type.dart';
import 'package:elements/models/player_progress_model.dart';
import 'package:elements/state/progress_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  static const _skinPrice = 12;

  static const _skinNames = <ElementType, String>{
    ElementType.fire: 'Ember',
    ElementType.water: 'Glacier',
    ElementType.earth: 'Copper',
    ElementType.wood: 'Jade',
  };

  static const _skinColors = <ElementType, Color>{
    ElementType.fire: Color(0xFFFFB45C),
    ElementType.water: Color(0xFF9DEBFF),
    ElementType.earth: Color(0xFFE7A768),
    ElementType.wood: Color(0xFF8EE6A7),
  };

  static const _skinDescriptions = <ElementType, String>{
    ElementType.fire: 'Ember crown and a bright gold sash',
    ElementType.water: 'Glacier crystals and a cool halo',
    ElementType.earth: 'Copper shoulder guards and a crest',
    ElementType.wood: 'Jade leaf crown and living cuffs',
  };

  String _skinId(ElementType element) =>
      '${element.name}_${_skinNames[element]!.toLowerCase()}';

  Future<void> _onSkinPressed(
    BuildContext context,
    WidgetRef ref,
    PlayerProgressModel progress,
    ElementType element,
  ) async {
    final id = _skinId(element);
    try {
      final service = ref.read(saveServiceProvider);
      if (progress.ownedSkins.contains(id)) {
        await service.equipSkin(id);
      } else {
        await service.purchaseSkin(skinId: id, price: _skinPrice);
      }
      ref.invalidate(progressProvider);
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cosmetic could not be saved: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Store could not load: $error')),
        data: (playerProgress) => LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 4 : 2;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Element Shards  ${playerProgress.elementShardBalance}  ✦',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Collect shards in levels to unlock elemental looks.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth < 600 ? 0.92 : 1.18,
                  children: ElementType.values.map((element) {
                    final id = _skinId(element);
                    final owned = playerProgress.ownedSkins.contains(id);
                    final equipped =
                        playerProgress.equippedSkins[element.name] == id;
                    return _CosmeticCard(
                      element: element,
                      name: _skinNames[element]!,
                      description: _skinDescriptions[element]!,
                      tint: _skinColors[element]!,
                      owned: owned,
                      equipped: equipped,
                      canAfford:
                          playerProgress.elementShardBalance >= _skinPrice,
                      price: _skinPrice,
                      onPressed: () =>
                          _onSkinPressed(context, ref, playerProgress, element),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.element,
    required this.name,
    required this.description,
    required this.tint,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.price,
    required this.onPressed,
  });

  final ElementType element;
  final String name;
  final String description;
  final Color tint;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final int price;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Color(element.highlightColor);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint.withValues(alpha: 0.22),
                    border: Border.all(color: tint, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    element.iconName,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${element.displayName} · $name',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: equipped || (!owned && !canAfford)
                    ? null
                    : onPressed,
                icon: Icon(
                  equipped
                      ? Icons.check_circle
                      : owned
                      ? Icons.checkroom
                      : Icons.shopping_bag,
                ),
                label: Text(
                  equipped
                      ? 'Equipped'
                      : owned
                      ? 'Equip'
                      : '$price ✦  Buy',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.85),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
