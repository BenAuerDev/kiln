import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/haptics_service.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/portable/domain/repositories/portable_repository.dart';
import 'package:kiln/features/ramps/data/data_sources/ramps_data_source.dart';
import 'package:kiln/features/ramps/data/models/ramp_dto.dart';
import 'package:kiln/features/ramps/domain/repositories/ramps_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_editing_service.dart';
import 'package:kiln/features/ramps/domain/use_cases/delete_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/save_ramp_use_case.dart';
import 'package:kiln/features/ramps/presentation/navigation/ramps_navigator.dart';
import 'package:kiln/features/ramps/domain/use_cases/advance_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/start_ramp_use_case.dart';
import 'package:kiln/features/ramps/domain/use_cases/stop_ramp_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockPortableRepository extends Mock implements PortableRepository {}

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockAdvanceRampUseCase extends Mock implements AdvanceRampUseCase {}

class MockStartRampUseCase extends Mock implements StartRampUseCase {}

class MockStopRampUseCase extends Mock implements StopRampUseCase {}

class MockHapticsService extends Mock implements HapticsService {}

class MockToastService extends Mock implements ToastService {}

class FakeL10nService extends L10nService {}

class MockRampsNavigator extends Mock implements RampsNavigator {}

class MockSaveRampUseCase extends Mock implements SaveRampUseCase {}

class MockDeleteRampUseCase extends Mock implements DeleteRampUseCase {}

/// Keeps what was written in [stored]; starts with [initial].
class FakeRampsDataSource implements RampsDataSource {
  FakeRampsDataSource([List<RampDto> initial = const []])
    : stored = [...initial];

  List<RampDto> stored;
  String? selected;
  bool failReads = false;
  bool failWrites = false;
  int writes = 0;

  @override
  Future<List<RampDto>> readAll() async {
    if (failReads) throw const FormatException('not a list');
    return stored;
  }

  @override
  Future<String?> readSelected() async {
    if (failReads) throw const FormatException('not a list');
    return selected;
  }

  @override
  Future<void> writeSelected(String id) async {
    if (failWrites) throw StateError('disk full');
    selected = id;
  }

  @override
  Future<void> writeAll(List<RampDto> ramps) async {
    if (failWrites) throw StateError('disk full');
    writes++;
    stored = [...ramps];
  }
}

/// A user ramp repository on [FakeRampsDataSource].
RampsRepository fakeRampsRepository([List<RampDto> initial = const []]) =>
    RampsRepository(
      dataSource: FakeRampsDataSource(initial),
      editing: RampEditingService(),
    );
