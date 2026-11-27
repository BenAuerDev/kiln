import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/formatters/duration_formatter.dart';
import '../../../../core/l10n/app_error_x.dart';
import '../../../../core/l10n/l10n_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../domain/models/ramp_profile.dart';
import '../../domain/repositories/ramp_run_repository.dart';
import '../../domain/models/ramp_field.dart';
import '../../domain/services/ramp_editing_service.dart';
import '../../domain/services/ramp_service.dart';
import '../../domain/use_cases/delete_ramp_use_case.dart';
import '../../domain/use_cases/find_ramp_use_case.dart';
import '../../domain/use_cases/load_ramps_use_case.dart';
import '../../domain/use_cases/save_ramp_use_case.dart';
import '../extensions/ramp_profile_x.dart';
import '../navigation/ramps_navigator.dart';

/// Creates or edits a user ramp. [_rampId] is a user ramp to edit; without
/// it, a new ramp starts with the values of [_fromId] (or the default
/// preset) and an empty name; a preset [_rampId] is copied the same way. A
/// saved ramp becomes the chosen one, unless a ramp is running.
class RampEditorViewModel {
  RampEditorViewModel({
    this._rampId,
    this._fromId,
    FindRampUseCase? findRamp,
    LoadRampsUseCase? loadRamps,
    SaveRampUseCase? saveRamp,
    DeleteRampUseCase? deleteRamp,
    RampEditingService? editing,
    RampService? ramps,
    RampRunRepository? runs,
    L10nService? l10n,
    HapticsService? haptics,
    ToastService? toast,
    RampsNavigator? navigator,
  }) : _findRamp = findRamp ?? sl<FindRampUseCase>(),
       _loadRamps = loadRamps ?? sl<LoadRampsUseCase>(),
       _saveRamp = saveRamp ?? sl<SaveRampUseCase>(),
       _deleteRamp = deleteRamp ?? sl<DeleteRampUseCase>(),
       _editing = editing ?? sl<RampEditingService>(),
       _ramps = ramps ?? sl<RampService>(),
       _runs = runs ?? sl<RampRunRepository>(),
       _l10n = l10n ?? sl<L10nService>(),
       _haptics = haptics ?? sl<HapticsService>(),
       _toast = toast ?? sl<ToastService>(),
       _navigator = navigator ?? sl<RampsNavigator>() {
    _applyDraft();
    unawaited(_load());
  }

  final String? _rampId;
  final String? _fromId;
  final FindRampUseCase _findRamp;
  final LoadRampsUseCase _loadRamps;
  final SaveRampUseCase _saveRamp;
  final DeleteRampUseCase _deleteRamp;
  final RampEditingService _editing;
  final RampService _ramps;
  final RampRunRepository _runs;
  final L10nService _l10n;
  final HapticsService _haptics;
  final ToastService _toast;
  final RampsNavigator _navigator;

  /// The saved user ramp being edited; `null` for a new ramp.
  final _source = signal<RampProfile?>(null);
  final _name = signal<String>('');
  final _values = signal<RampProfile>(_draftFrom(RampService.defaultPreset));
  final _confirmingDelete = signal<bool>(false);
  final _saving = signal<bool>(false);

  /// Bumped when the draft is replaced, so the name field takes the new text.
  final _draftVersion = signal<int>(0);
  bool _applied = false;

  ReadonlySignal<String> get name => _name;
  ReadonlySignal<RampProfile> get values => _values;
  ReadonlySignal<bool> get confirmingDelete => _confirmingDelete;
  ReadonlySignal<bool> get saving => _saving;
  ReadonlySignal<int> get draftVersion => _draftVersion;

  int get maxNameLength => RampEditingService.maxNameLength;

  late final Computed<bool> isExisting = computed(() => _source.value != null);

  late final Computed<bool> canSave = computed(
    () => !_saving.value && _editing.canSave(_name.value, _values.value),
  );

  /// `+5° every 2 min · 8 min`.
  late final Computed<String> summary = computed(() {
    final values = _values.value;
    return values.summary(_l10n.strings, _ramps.duration(values));
  });

  /// `170–190°`.
  late final Computed<String> range = computed(
    () => _values.value.range(_l10n.strings),
  );

  /// `5 steps`: how often the base is raised after the start.
  late final Computed<String> stepCount = computed(
    () => _l10n.strings.rampsEditorSteps(_ramps.stepCount(_values.value)),
  );

  /// The values shown in the rows, e.g. `170°`, `+5°`, `1:30` (short, to
  /// fit next to −/+).
  late final Computed<String> startLabel = computed(
    () => _l10n.strings.commonDegrees(_values.value.startCelsius),
  );
  late final Computed<String> endLabel = computed(
    () => _l10n.strings.commonDegrees(_values.value.endCelsius),
  );
  late final Computed<String> stepLabel = computed(
    () => _l10n.strings.rampsEditorStepValue(_values.value.stepCelsius),
  );
  late final Computed<String> intervalLabel = computed(
    () => DurationFormatter.clock(_values.value.interval),
  );

  /// The unit under [intervalLabel].
  late final Computed<String> minutesUnit = computed(
    () => _l10n.strings.rampsEditorMinutes,
  );

  void setName(String value) => _name.value = value;

  void lower(RampField field) => _adjust(field, -1);

  void raise(RampField field) => _adjust(field, 1);

  Future<void> save() async {
    if (!canSave.value) return;
    _saving.value = true;
    final result = await _saveRamp(
      _values.value.copyWith(id: _source.value?.id ?? '', name: _name.value),
    );
    _saving.value = false;
    result.match(_showError, (saved) {
      saved.match(() {}, (ramp) {
        if (!(_runs.run.value?.isActive ?? false)) _runs.select(ramp.id);
        unawaited(_haptics.success());
        _toast.show(_l10n.strings.rampsSaved, level: ToastLevel.success);
        _navigator.back();
      });
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
    (await _deleteRamp(source.id)).match(_showError, (_) {
      unawaited(_haptics.success());
      _toast.show(_l10n.strings.rampsDeleted, level: ToastLevel.success);
      _navigator.back();
    });
  }

  void back() => _navigator.back();

  void _adjust(RampField field, int direction) {
    final next = _editing.adjust(_values.value, field, direction);
    if (identical(next, _values.value)) return;
    unawaited(_haptics.tick());
    _confirmingDelete.value = false;
    _values.value = next;
  }

  Future<void> _load() async {
    (await _loadRamps()).match(_showError, (_) => _applyDraft());
  }

  /// Fills the draft once: a user ramp [_rampId] is edited; a preset
  /// [_rampId] or the ramp [_fromId] gives a new ramp its values; nothing
  /// gives the default preset's. An id not known yet may be a user ramp that
  /// is still loading, so this runs again after loading.
  void _applyDraft() {
    if (_applied) return;
    final key = _rampId ?? _fromId;
    final found = key == null ? null : _findRamp(key).toNullable();
    if (key != null && found == null) return;
    _applied = true;
    if (found != null && _rampId != null && !found.isPreset) {
      _source.value = found;
      _name.value = found.name;
      _values.value = found;
      _draftVersion.value++;
      return;
    }
    _values.value = _draftFrom(found ?? RampService.defaultPreset);
  }

  /// The values of [ramp] as a new, unnamed user ramp (no preset tag).
  static RampProfile _draftFrom(RampProfile ramp) => RampProfile(
    id: '',
    startCelsius: ramp.startCelsius,
    stepCelsius: ramp.stepCelsius,
    interval: ramp.interval,
    endCelsius: ramp.endCelsius,
  );

  void _showError(AppError error) {
    unawaited(_haptics.warning());
    _toast.show(error.message(_l10n.strings), level: ToastLevel.error);
  }

  void dispose() {
    isExisting.dispose();
    canSave.dispose();
    summary.dispose();
    range.dispose();
    stepCount.dispose();
    startLabel.dispose();
    endLabel.dispose();
    stepLabel.dispose();
    intervalLabel.dispose();
    minutesUnit.dispose();
  }
}
