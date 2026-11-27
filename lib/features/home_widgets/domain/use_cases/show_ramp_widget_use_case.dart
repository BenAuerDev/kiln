import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/ramp_widget_content.dart';
import '../repositories/home_widgets_repository.dart';

/// Shows [content] on the ramp widget, live or as last known values.
class ShowRampWidgetUseCase {
  ShowRampWidgetUseCase({HomeWidgetsRepository? repository})
    : _repository = repository ?? sl<HomeWidgetsRepository>();

  final HomeWidgetsRepository _repository;

  Future<Either<AppError, Unit>> call(
    RampWidgetContent? content, {
    required bool live,
  }) => _repository.showRamp(content, live: live);
}
