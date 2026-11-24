import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../models/portable_widget_content.dart';
import '../repositories/home_widgets_repository.dart';

/// Shows [content] on the Venty/Veazy widget, live or as last known values.
class ShowPortableWidgetUseCase {
  ShowPortableWidgetUseCase({HomeWidgetsRepository? repository})
    : _repository = repository ?? sl<HomeWidgetsRepository>();

  final HomeWidgetsRepository _repository;

  Future<Either<AppError, Unit>> call(
    PortableWidgetContent? content, {
    required bool live,
  }) => _repository.showPortable(content, live: live);
}
