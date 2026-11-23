import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../domain/models/workflow.dart';
import '../../domain/models/workflow_step.dart';
import '../../domain/services/workflow_editing_service.dart';
import '../../domain/use_cases/delete_workflow_use_case.dart';
import '../../domain/use_cases/find_workflow_use_case.dart';
import '../../domain/use_cases/load_workflows_use_case.dart';
import '../../domain/use_cases/save_workflow_use_case.dart';
import '../extensions/workflow_x.dart';
import '../navigation/workflows_navigator.dart';

/// Creates or edits a user workflow. Opening a preset edits a copy that is
/// saved as a new workflow.
class WorkflowEditorViewModel {
  WorkflowEditorViewModel({
    this._workflowId,
    FindWorkflowUseCase? findWorkflow,
    WorkflowEditingService? editing,
    LoadWorkflowsUseCase? loadWorkflows,
    SaveWorkflowUseCase? saveWorkflow,
    DeleteWorkflowUseCase? deleteWorkflow,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    WorkflowsNavigator? navigator,
  }) : _findWorkflow = findWorkflow ?? sl<FindWorkflowUseCase>(),
       _editing = editing ?? sl<WorkflowEditingService>(),
       _loadWorkflows = loadWorkflows ?? sl<LoadWorkflowsUseCase>(),
       _saveWorkflow = saveWorkflow ?? sl<SaveWorkflowUseCase>(),
       _deleteWorkflow = deleteWorkflow ?? sl<DeleteWorkflowUseCase>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<WorkflowsNavigator>() {
    _applyDraft();
    unawaited(_load());
  }

  final String? _workflowId;
  final FindWorkflowUseCase _findWorkflow;
  final WorkflowEditingService _editing;
  final LoadWorkflowsUseCase _loadWorkflows;
  final SaveWorkflowUseCase _saveWorkflow;
  final DeleteWorkflowUseCase _deleteWorkflow;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final WorkflowsNavigator _navigator;

  /// The workflow being edited or copied, `null` for a new one.
  final _source = signal<Workflow?>(null);
  final _name = signal<String>('');
  final _steps = signal<List<WorkflowStep>>(const []);
  final _heaterOffAtEnd = signal<bool>(true);
  final _confirmingDelete = signal<bool>(false);
  final _saving = signal<bool>(false);

  /// Bumped when the draft is replaced, so the name field takes the new text.
  final _draftVersion = signal<int>(0);

  ReadonlySignal<String> get name => _name;
  ReadonlySignal<List<WorkflowStep>> get steps => _steps;
  ReadonlySignal<bool> get heaterOffAtEnd => _heaterOffAtEnd;
  ReadonlySignal<bool> get confirmingDelete => _confirmingDelete;
  ReadonlySignal<bool> get saving => _saving;
  ReadonlySignal<int> get draftVersion => _draftVersion;

  /// Editing a saved user workflow (it can be deleted).
  late final Computed<bool> isExisting = computed(() {
    final source = _source.value;
    return source != null && !source.isPreset;
  });

  late final Computed<bool> canSave = computed(
    () => !_saving.value && _editing.canSave(_name.value, _steps.value),
  );

  late final Computed<bool> canAddStep = computed(
    () => _steps.value.length < WorkflowEditingService.maxSteps,
  );

  int get maxNameLength => WorkflowEditingService.maxNameLength;

  void setName(String value) => _name.value = value;

  void add(WorkflowStepKind kind) => _change(_editing.add(_steps.value, kind));

  void remove(int index) => _change(_editing.remove(_steps.value, index));

  void moveUp(int index) => _change(_editing.move(_steps.value, index, -1));

  void moveDown(int index) => _change(_editing.move(_steps.value, index, 1));

  void lower(int index) => _change(_editing.adjust(_steps.value, index, -1));

  void raise(int index) => _change(_editing.adjust(_steps.value, index, 1));

  void setHeaterOffAtEnd(bool value) {
    unawaited(_haptics.tick());
    _heaterOffAtEnd.value = value;
  }

  Future<void> save() async {
    if (!canSave.value) return;
    _saving.value = true;
    final result = await _saveWorkflow(
      Workflow(
        id: isExisting.value ? _source.value!.id : '',
        name: _name.value,
        steps: _steps.value,
        heaterOffAtEnd: _heaterOffAtEnd.value,
      ),
    );
    _saving.value = false;
    result.match(_showError, (saved) {
      if (saved.isNone()) return;
      unawaited(_haptics.success());
      _toast.show(_l10n.strings.workflowsSaved, level: ToastLevel.success);
      _navigator.back();
    });
  }

  /// First tap asks, second tap deletes.
  Future<void> delete() async {
    unawaited(_haptics.tick());
    if (!_confirmingDelete.value) {
      _confirmingDelete.value = true;
      return;
    }
    _confirmingDelete.value = false;
    final source = _source.value;
    if (source == null) return;
    (await _deleteWorkflow(source.id)).match(_showError, (_) {
      unawaited(_haptics.success());
      _toast.show(_l10n.strings.workflowsDeleted, level: ToastLevel.success);
      _navigator.goToWorkflows();
    });
  }

  void back() => _navigator.back();

  void _change(List<WorkflowStep> steps) {
    if (identical(steps, _steps.value)) return;
    unawaited(_haptics.tick());
    _confirmingDelete.value = false;
    _steps.value = List.unmodifiable(steps);
  }

  Future<void> _load() async {
    (await _loadWorkflows()).match(_showError, (_) => _applyDraft());
  }

  /// Fills the draft from the workflow to edit, the preset to copy, or
  /// leaves it empty for a new one.
  void _applyDraft() {
    final id = _workflowId;
    if (id == null) return;
    final source = _findWorkflow(id).toNullable();
    if (source == null || source == _source.value) return;
    _source.value = source;
    _name.value = source.displayName(_l10n.strings);
    _steps.value = source.steps;
    _heaterOffAtEnd.value = source.heaterOffAtEnd;
    _draftVersion.value++;
  }

  void _showError(AppError error) {
    unawaited(_haptics.warning());
    _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
  }

  void dispose() {
    isExisting.dispose();
    canSave.dispose();
    canAddStep.dispose();
  }
}
