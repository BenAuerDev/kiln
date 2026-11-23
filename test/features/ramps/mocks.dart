import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/core/services/haptics_service.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/portable/domain/repositories/portable_repository.dart';
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
