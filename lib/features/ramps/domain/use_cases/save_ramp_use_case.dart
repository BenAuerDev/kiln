import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/ramp_profile.dart';
import '../repositories/ramps_repository.dart';
import '../services/ramp_editing_service.dart';

/// Saves a user ramp: trims the name, brings the values into the limits and
/// gives a new ramp (empty id, or a preset being copied) its id. Returns the
/// saved ramp, or `none()` when it cannot be saved (nothing is saved).
class SaveRampUseCase {
  SaveRampUseCase({
    RampsRepository? repository,
    RampEditingService? editing,
    DateTime Function()? clock,
  }) : _repository = repository ?? sl<RampsRepository>(),
       _editing = editing ?? sl<RampEditingService>(),
       _clock = clock ?? DateTime.now;

  final RampsRepository _repository;
  final RampEditingService _editing;
  final DateTime Function() _clock;

  Future<Either<AppError, Option<RampProfile>>> call(RampProfile draft) async {
    final trimmed = draft.name.trim();
    final name = trimmed.length > RampEditingService.maxNameLength
        ? trimmed.substring(0, RampEditingService.maxNameLength)
        : trimmed;
    final values = _editing.normalise(draft);
    if (!_editing.canSave(name, values)) return right(none());
    final ramp = RampProfile(
      id: draft.id.isEmpty || draft.isPreset
          ? 'user.${_clock().microsecondsSinceEpoch}'
          : draft.id,
      name: name,
      startCelsius: values.startCelsius,
      endCelsius: values.endCelsius,
      stepCelsius: values.stepCelsius,
      interval: values.interval,
    );
    return (await _repository.save(ramp)).map((_) => some(ramp));
  }
}
