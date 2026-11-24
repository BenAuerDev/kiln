import '../../../../core/service_locator.dart';
import '../repositories/home_widgets_repository.dart';
import 'handle_home_widget_action_use_case.dart';

/// Runs the buttons pressed on the home-screen widgets while [listen] is
/// on. Errors are dropped: there is no screen to show them on, and the
/// widget shows the real state with the next status.
class ListenToHomeWidgetActionsUseCase {
  ListenToHomeWidgetActionsUseCase({
    HomeWidgetsRepository? repository,
    HandleHomeWidgetActionUseCase? handleAction,
  }) : _repository = repository ?? sl<HomeWidgetsRepository>(),
       _handleAction = handleAction ?? sl<HandleHomeWidgetActionUseCase>();

  final HomeWidgetsRepository _repository;
  final HandleHomeWidgetActionUseCase _handleAction;

  void call({required bool listen}) => _repository.setActionHandler(
    listen ? (action) => _handleAction(action).then((_) {}) : null,
  );
}
