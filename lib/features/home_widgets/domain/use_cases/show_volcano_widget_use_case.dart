import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/volcano_widget_content.dart';
import '../repositories/home_widgets_repository.dart';

/// Shows [content] on the Volcano widget, live or offline.
class ShowVolcanoWidgetUseCase {
  ShowVolcanoWidgetUseCase({HomeWidgetsRepository? repository})
    : _repository = repository ?? sl<HomeWidgetsRepository>();

  final HomeWidgetsRepository _repository;

  Future<Either<AppError, Unit>> call(
    VolcanoWidgetContent? content, {
    required bool live,
  }) => _repository.showVolcano(content, live: live);
}
