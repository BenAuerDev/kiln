import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/background/data/data_sources/background_service_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(BackgroundServiceDataSource.channelName);
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'requestNotificationPermission' ? true : null;
        });
  });

  test('sends start, update, alert, stop and the permission request', () async {
    final dataSource = BackgroundServiceDataSource();
    await dataSource.start(
      title: 'T',
      text: 'X',
      sessionChannel: 'S',
      readyChannel: 'R',
    );
    await dataSource.update(title: 'T2', text: 'X2');
    await dataSource.alert(
      title: 'A',
      text: 'B',
      sessionChannel: 'S',
      readyChannel: 'R',
    );
    await dataSource.stop();
    expect(await dataSource.requestNotificationPermission(), isTrue);
    expect(calls.map((c) => c.method), [
      'start',
      'update',
      'alert',
      'stop',
      'requestNotificationPermission',
    ]);
    expect(calls.first.arguments, {
      'title': 'T',
      'text': 'X',
      'sessionChannel': 'S',
      'readyChannel': 'R',
    });
  });
}
