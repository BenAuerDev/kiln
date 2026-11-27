import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/ramps/data/data_sources/ramps_data_source.dart';
import 'package:kiln/features/ramps/data/models/ramp_dto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPrefs prefs;
  late RampsDataSource dataSource;

  setUp(() {
    prefs = _MockPrefs();
    dataSource = RampsDataSource(prefs);
  });

  const dto = RampDto(
    id: 'user.1',
    name: 'Evening',
    startCelsius: 175,
    endCelsius: 200,
    stepCelsius: 5,
    intervalSeconds: 90,
  );

  test('writes and reads back the same list', () async {
    String? stored;
    when(() => prefs.setString('ramps.v1', any())).thenAnswer((call) async {
      stored = call.positionalArguments[1] as String;
    });
    await dataSource.writeAll([dto]);
    when(() => prefs.getString('ramps.v1')).thenAnswer((_) async => stored);

    final [read] = await dataSource.readAll();
    expect(read.toJson(), dto.toJson());
  });

  test('nothing stored is an empty list', () async {
    when(() => prefs.getString(any())).thenAnswer((_) async => null);
    expect(await dataSource.readAll(), isEmpty);
  });

  test('skips malformed entries', () async {
    when(() => prefs.getString(any())).thenAnswer(
      (_) async => jsonEncode([
        dto.toJson(),
        {'id': 'user.2', 'name': 'Broken'},
      ]),
    );
    expect((await dataSource.readAll()).map((r) => r.id), ['user.1']);
  });
}
