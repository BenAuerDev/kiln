import 'package:fpdart/fpdart.dart';

import '../../../../core/service_locator.dart';
import '../models/ramp_profile.dart';
import '../repositories/ramps_repository.dart';
import '../services/ramp_service.dart';

/// The current version of a user ramp or preset by id; `none()` once it was
/// deleted. Reads repository signals, so it can be used in a computed.
class FindRampUseCase {
  FindRampUseCase({RampsRepository? repository})
    : _repository = repository ?? sl<RampsRepository>();

  final RampsRepository _repository;

  Option<RampProfile> call(String id) => Option.fromNullable(
    _repository.byId(id) ??
        RampService.presets.where((preset) => preset.id == id).firstOrNull,
  );
}
