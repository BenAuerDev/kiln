# Coding conventions used in kiln

Read together with `ARCHITECTURE.md` (incl. Addendum), `docs/brief.md`, `docs/plan.md`.

## Dependency injection
- Repositories, use cases and view models take their dependencies as optional
  named constructor params that default to `sl`, so tests can pass mocks:
  ```dart
  class FooUseCase {
    FooUseCase({FooRepository? repository})
      : _repository = repository ?? sl<FooRepository>();
  ```
- Data sources take their I/O dependency positionally (`FooDataSource(this._ble)`)
  and are registered as `registerLazySingleton(() => FooDataSource(sl()))`.
- Register with tear-offs: `..registerFactory(FooUseCase.new)`.

## Errors
- Data sources throw (`BleException` subclasses from `core/ble/ble_exceptions.dart`,
  `FormatException` for bad packets).
- Repositories catch and return `Either<AppError, T>` (fpdart). Use
  `BleErrorMapper.toAppError(e)` from `core/ble/ble_error_mapper.dart` for BLE
  errors and `AppError.storage()` for preferences.
- View models turn `AppError` into a toast with `error.message(l10n)` from
  `core/l10n/app_error_x.dart`.
- Use `Option<T>` where "nothing happened" is a valid outcome (e.g. a
  clamped adjust that did not change anything returns `right(none())`).

## Signals
- Private `Signal<T>` fields, public `ReadonlySignal<T>` getters.
- `watch(context)` and `Watch` are deprecated in signals_flutter 7. Use
  `SignalWidget` (implicit tracking) or `SignalBuilder(builder: (context) => …)`.
- Screens are `HookWidget`s:
  ```dart
  final vm = useMemoized(() => sl<FooViewModel>());
  useEffect(() => vm.dispose, [vm]);
  ```
  then pass `vm` to child sections. Sections that read signals extend `SignalWidget`.
- View models collect `effect(...)` disposers and dispose every `computed` in `dispose()`.

## UI
- Obers UI only (`import 'package:obers_ui/obers_ui.dart';`). It does not
  re-export Flutter, so also `import 'package:flutter/widgets.dart';`.
  Reference: `AI_README.md` in the obers_ui checkout
  (`~/.pub-cache/git/obers_ui-*/AI_README.md`). Never use Material/Cupertino widgets.
- Text through `OiLabel.*`. Numbers and headings use the Space Grotesk text
  styles (`h1`–`h4`, `display`), which already have tabular figures.
- Colours: `context.colors` (Obers) and `context.kiln` (accent gradient, glow,
  accent text, raised surface, track; see `core/theme/kiln_tokens.dart`).
  No colour literals outside `core/theme/kiln_palette.dart`.
- `KilnThemeScope` (an `InheritedWidget` above `OiApp`) is the one accepted
  exception to the widget base-class rule: it is theme infrastructure, not a
  screen or widget, and Obers has no theme-extension slot for kiln's tokens.
- Session lifecycle: `PortableRepository` and `VolcanoRepository` watch their
  device's BLE connection state and end the session when the link drops, so
  no screen has to be visible for that.
- Honour reduce motion: `MediaQuery.disableAnimationsOf(context)`.
- Every interactive element gets a semantic label from the `.arb` files.

## Strings
- All user-visible strings in `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`
  (German uses informal "du"). Prefix keys with the feature (`devices…`,
  `portable…`, `volcano…`, `welcome…`).
- Then run `flutter gen-l10n`. Widgets use `getAppLocalizations(context)`;
  view models use `sl<L10nService>().strings`.

## Tests
- `test/` mirrors `lib/`. mocktail for mocks. Every use case: happy path and edge cases.
- Repository tests with mocked data sources including the error path.

## BLE safety
- No firmware, bootloader, factory-reset, analysis or usage-stats commands or
  constants anywhere in code.
- Each feature's data layer has a `<Feature>WriteSafety` allow-list. Writes not
  on it return `Left(AppError.writeNotVerified(...))` without touching BLE.
- Temperature writes are clamped in use cases (Volcano 40–230 °C, portables 40–210 °C).

## Tooling
- `dart format .`, `flutter analyze` and `flutter test` must be clean.
