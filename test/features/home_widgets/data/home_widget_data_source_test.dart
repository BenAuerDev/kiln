import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/home_widgets/data/data_sources/home_widget_data_source.dart';
import 'package:kiln/features/home_widgets/data/models/portable_widget_dto.dart';
import 'package:kiln/features/home_widgets/data/models/volcano_widget_dto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const plugin = MethodChannel('home_widget');
  const actionsChannel = MethodChannel(HomeWidgetDataSource.actionsChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var saveResult = true;

  setUp(() {
    calls.clear();
    saveResult = true;
    messenger.setMockMethodCallHandler(plugin, (call) async {
      calls.add(call);
      return call.method == 'saveWidgetData' ? saveResult : true;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(plugin, null));

  Future<void> sendFromAndroid(String method, Object? arguments) =>
      messenger.handlePlatformMessage(
        HomeWidgetDataSource.actionsChannelName,
        actionsChannel.codec.encodeMethodCall(MethodCall(method, arguments)),
        (_) {},
      );

  test(
    'saves each widget as one JSON string and updates its provider',
    () async {
      final dataSource = HomeWidgetDataSource();
      await dataSource.savePortable(
        const PortableWidgetDto(
          glyph: 'veazy',
          name: 'Veazy',
          battery: '72%',
          batteryLevel: 0.72,
          batteryLow: false,
          charging: true,
          ringDescription: 'r',
          offlineRingDescription: 'o',
          status: 'Heating to 180°',
          statusAccent: true,
          baseLabel: 'Base',
          base: '180°',
          boostLabel: 'Boost',
          boost: '195°',
          superLabel: 'Super',
          superBoost: '210°',
          basePosition: 0.82,
          boostPosition: 0.91,
          superBoostPosition: 1,
          ladderDescription: 'l',
          heatLabel: 'Heat off',
          heatActive: true,
          boostButtonLabel: 'Boost',
          boostActive: false,
          offlineStatus: 'Not connected',
          offlineHeatLabel: 'Heat',
          offlineBoostLabel: 'Boost',
          accent: 0xFF3D8BFF,
          accentText: 0xFF6AA6FF,
          onAccent: 0xFF0B0B0C,
          gradientStart: 0xFF9CC4FF,
          gradientEnd: 0xFF2F6BFF,
        ),
      );
      await dataSource.updatePortable();
      await dataSource.savePortableLive(true);
      await dataSource.saveVolcanoLive(false);
      await dataSource.updateVolcano();
      expect(calls.map((c) => c.method), [
        'saveWidgetData',
        'updateWidget',
        'saveWidgetData',
        'saveWidgetData',
        'updateWidget',
      ]);
      final saved = calls[0].arguments as Map;
      expect(saved['id'], HomeWidgetDataSource.portableKey);
      final json = jsonDecode(saved['data'] as String) as Map<String, dynamic>;
      expect(json['name'], 'Veazy');
      expect(json['superBoost'], '210°');
      expect(json['glyph'], 'veazy');
      expect(json['batteryLevel'], 0.72);
      expect(json['batteryLow'], isFalse);
      expect(json['charging'], isTrue);
      expect(json['offlineRingDescription'], 'o');
      expect(json['heatActive'], isTrue);
      // Above 2^31: Kotlin reads it as a Long and narrows it to an ARGB Int.
      expect(json['accentText'], 0xFF6AA6FF);
      expect(
        (calls[1].arguments as Map)['qualifiedAndroidName'],
        HomeWidgetDataSource.portableProvider,
      );
      expect(calls[2].arguments, {
        'id': HomeWidgetDataSource.portableLiveKey,
        'data': true,
      });
      expect(calls[3].arguments, {
        'id': HomeWidgetDataSource.volcanoLiveKey,
        'data': false,
      });
      expect(
        (calls[4].arguments as Map)['qualifiedAndroidName'],
        HomeWidgetDataSource.volcanoProvider,
      );
    },
  );

  test('saves the Volcano widget under its key', () async {
    await HomeWidgetDataSource().saveVolcano(
      const VolcanoWidgetDto(
        name: 'Volcano Hybrid',
        temperature: '142°',
        status: 'Heating to 185°',
        statusAccent: true,
        progress: 0.5,
        gaugeDescription: 'g',
        heatLabel: 'Heat off',
        heatActive: true,
        airLabel: 'Air',
        airActive: false,
        offlineTemperature: '–',
        offlineStatus: 'Not connected',
        offlineHeatLabel: 'Heat',
        offlineAirLabel: 'Air',
        accent: 1,
        accentText: 2,
        onAccent: 3,
        gradientStart: 4,
        gradientEnd: 5,
      ),
    );
    final saved = calls.single.arguments as Map;
    expect(saved['id'], HomeWidgetDataSource.volcanoKey);
    final json = jsonDecode(saved['data'] as String) as Map<String, dynamic>;
    expect(json['heatActive'], isTrue);
    expect(json['offlineHeatLabel'], 'Heat');
    expect(json['progress'], 0.5);
  });

  test('throws when the plugin did not save', () async {
    saveResult = false;
    await expectLater(
      HomeWidgetDataSource().saveVolcanoLive(false),
      throwsStateError,
    );
  });

  test('runs the handler for button actions, and answers when done', () async {
    final dataSource = HomeWidgetDataSource();
    final received = <String>[];
    final gate = Completer<void>();
    dataSource.setActionHandler((action) async {
      received.add(action);
      await gate.future;
    });
    var answered = false;
    final reply = messenger.handlePlatformMessage(
      HomeWidgetDataSource.actionsChannelName,
      actionsChannel.codec.encodeMethodCall(
        const MethodCall('action', 'volcanoHeat'),
      ),
      (_) => answered = true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(received, ['volcanoHeat']);
    // Android keeps kiln awake until the handler is done.
    expect(answered, isFalse);
    gate.complete();
    await reply;
    expect(answered, isTrue);

    await sendFromAndroid('other', 'volcanoAir');
    await sendFromAndroid('action', 42);
    dataSource.setActionHandler(null);
    await sendFromAndroid('action', 'volcanoAir');
    expect(received, ['volcanoHeat']);
  });
}
