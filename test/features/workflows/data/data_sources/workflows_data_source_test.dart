import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/workflows/data/data_sources/workflows_data_source.dart';
import 'package:kiln/features/workflows/data/models/workflow_dto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPrefs prefs;
  late WorkflowsDataSource dataSource;

  setUp(() {
    prefs = _MockPrefs();
    dataSource = WorkflowsDataSource(prefs);
  });

  const dto = WorkflowDto(
    id: 'user.1',
    name: 'Evening',
    heaterOffAtEnd: true,
    steps: [
      WorkflowStepDto(type: 'heat', value: 185),
      WorkflowStepDto(type: 'air', value: 45),
    ],
  );

  test('writes and reads back the same list', () async {
    String? stored;
    when(() => prefs.setString('workflows.v1', any())).thenAnswer((call) async {
      stored = call.positionalArguments[1] as String;
    });
    await dataSource.writeAll([dto]);
    when(() => prefs.getString('workflows.v1')).thenAnswer((_) async => stored);

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
        {'id': 'broken'},
      ]),
    );
    expect((await dataSource.readAll()).map((d) => d.id), ['user.1']);
  });
}
