import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/ble/ble_client.dart';
import 'package:kiln/features/portable/data/data_sources/portable_ble_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockBleClient extends Mock implements BleClient {}

const _service = '00000000-5354-4f52-5a26-4249434b454c';
const _characteristic = '00000001-5354-4f52-5a26-4249434b454c';

void main() {
  late MockBleClient ble;
  late PortableBleDataSource dataSource;

  setUp(() {
    ble = MockBleClient();
    dataSource = PortableBleDataSource(ble);
  });

  test('subscribes to the Venty/Veazy characteristic', () {
    final stream = Stream<List<int>>.value(const [1]);
    when(
      () => ble.subscribe('id', _service, _characteristic),
    ).thenAnswer((_) => stream);

    expect(dataSource.subscribe('id'), same(stream));
  });

  test('enables notifications on the Venty/Veazy characteristic', () async {
    when(
      () => ble.enableNotifications('id', _service, _characteristic),
    ).thenAnswer((_) async {});

    await dataSource.enableNotifications('id');

    verify(
      () => ble.enableNotifications('id', _service, _characteristic),
    ).called(1);
  });

  test('writes to the Venty/Veazy characteristic', () async {
    when(
      () => ble.write('id', _service, _characteristic, const [1, 0]),
    ).thenAnswer((_) async {});

    await dataSource.write('id', const [1, 0]);

    verify(
      () => ble.write('id', _service, _characteristic, const [1, 0]),
    ).called(1);
  });
}
