import 'package:elements/models/element_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ElementType has four forms with distinct core colors', () {
    expect(ElementType.values, hasLength(4));
    final cores = ElementType.values.map((e) => e.coreColor).toSet();
    expect(cores, hasLength(4));
    expect(ElementType.fire.coreColor, 0xFFC0392B);
    expect(ElementType.water.coreColor, 0xFF1F6FB2);
    expect(ElementType.earth.coreColor, 0xFF8A5A32);
    expect(ElementType.wood.coreColor, 0xFF3D7A3D);
  });
}
