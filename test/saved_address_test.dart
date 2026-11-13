import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/models/saved_address.dart';

void main() {
  test('saved address JSON round trip preserves location details', () {
    const address = SavedAddress(
      id: 7,
      label: 'Work',
      country: 'Morocco',
      city: 'Casablanca',
      street: 'Main Street',
      building: '12',
      premises: 'Floor 3',
      isDefault: true,
    );

    final decoded = SavedAddress.fromJson({
      'id': address.id,
      ...address.toJson(),
    });

    expect(decoded.id, address.id);
    expect(decoded.label, address.label);
    expect(
      decoded.formattedAddress,
      'Main Street, 12, Floor 3, Casablanca, Morocco',
    );
    expect(decoded.isDefault, isTrue);
  });

  test('saved address can be serialized as non-default', () {
    const address = SavedAddress(
      id: 1,
      label: 'Home',
      country: 'Morocco',
      city: 'Rabat',
      street: 'Oak Street',
      building: '4',
      isDefault: true,
    );

    expect(address.toJson(defaultOverride: false)['isDefault'], isFalse);
  });
}
