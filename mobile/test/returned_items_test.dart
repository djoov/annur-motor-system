import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/returns/return_provider.dart';

void main() {
  test('reads nested returned_items', () {
    expect(
      ReturnProvider.returnedItemsOf({
        'returned_items': {'a': 2, 'b': 1},
      }),
      {'a': 2, 'b': 1},
    );
  });

  test('counts legacy literal "returned_items.<id>" fields', () {
    expect(
      ReturnProvider.returnedItemsOf({
        'has_return': true,
        'returned_items.a': 1,
        'returned_items': {'a': 2},
      }),
      {'a': 3},
    );
  });

  test('no returns', () {
    expect(ReturnProvider.returnedItemsOf({'items': []}), isEmpty);
  });
}
