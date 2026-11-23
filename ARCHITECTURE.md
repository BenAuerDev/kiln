# Flutter architecture guide

This is a Flutter-only app with no custom backend. Follow this architecture strictly.
Packages: `signals_flutter` (state), `get_it` (DI, accessed as global `sl`), `flutter_hooks` (local widget state), `go_router` (routing), an `Either` type (e.g. `fpdart`) for results.

## Folder layout
Group by feature: `lib/features/<feature>/`

```
data/
  data_sources/      <name>_data_source.dart
  models/            (only if the data format needs its own DTOs)
domain/
  models/            plain Dart types used by UI and logic
  repositories/      <name>_repository.dart
  use_cases/         <verb_subject>_use_case.dart
  services/          pure functions/classes (parsing, calculation, grouping, sorting)
  extensions/        <type>_x.dart (pure derivations, no Flutter imports)
presentation/
  screens/           <name>_screen.dart
  widgets/           one public widget per file
  view_models/       <name>_view_model.dart
  extensions/        <type>_x.dart (may import Flutter: IconData, Color, l10n)
setup_dependencies.dart   registers everything of the feature into get_it `sl`
```

Shared code lives in `lib/core/` (service locator, routing, theme, formatters, l10n service).

## Layer rules
Dependencies point inward only: presentation → domain → data.
- **Data** must not know about domain or presentation. It knows where data comes from (local DB, preferences, REST API, files) and in what format.
- **Domain** must not know about presentation, widgets or `BuildContext`.
- **Presentation** must not know about data. It never imports `data/`.
- NEVER use abstract-class-plus-implementation. Data sources and repositories are concrete classes. Mock them in tests instead.

### Data sources (`*_data_source.dart`)
- Do I/O only: database, key-value storage, HTTP, platform channels.
- Contain no business logic and no caching. They throw on failure.

### Repositories (`*_repository.dart`)
- Hold cached data in **private** `Signal<T>` fields and expose them as `ReadonlySignal<T>` getters.
- Do the CRUD against data sources and keep the signals up to date.
- Catch all errors from the data layer and return `Either<AppError, T>`. Never leak raw exceptions.
- Repositories that hold user/account data must be registered for reset on logout/clear (if the app has accounts).
- Registered as singletons.

### Use cases (`<verb_subject>_use_case.dart`, e.g. `CreateWorkoutUseCase`)
- Expose a single `call` method. Stateless. No side effects (no navigation, toasts, dialogs).
- Contain ALL business logic. Call repositories, services, or other use cases only.
- Prefer leaf use cases. A composer use case may call other use cases when its single job is composing them. Keep call chains shallow.
- No try/catch. Errors come back from repositories as `Either`.
- Get dependencies from `sl`. Registered with `registerFactory`.
- Every use case needs a unit test (happy path and edge cases).
- Reusable logic across use cases goes into a service in `domain/services/`.

### Extensions (`<type>_x.dart`)
- Anything derived from a single model or enum (display name, formatted value, label, icon, colour) is `extension TypeX on Type`. It is NOT a free function and NOT a helper in a widget file.
- A derivation needing nothing external is a getter. Otherwise pass dependencies explicitly (`AppLocalizations l10n`, `Locale locale`). NEVER take a `BuildContext`.
- One extension per type. Extensions that import Flutter live in `presentation/extensions/`, pure ones in `domain/extensions/`.
- Logic that combines unrelated inputs belongs in a view model or use case. Reusable formatting not tied to one type goes in `core/formatters/`.

### View models (`*_view_model.dart`)
- Get dependencies (repositories, use cases, services) from `sl`. Registered with `registerFactory`: every `sl<XViewModel>()` creates a new instance.
- Expose UI state as `Computed<T>` / `ReadonlySignal<T>` derived from repository signals.
- Have one method per user action (button tap, etc.).
- Own all side effects of interactions: navigation, toasts, haptics, notifications, dialogs.
- Pass actions to use cases. NEVER implement business logic.
  - Allowed: UI state and its wiring (signals, text controllers, focus, debounce timers, which dialog is open, turning a use-case result into state or a toast).
  - Not allowed: calculations, parsing, grouping, sorting, text transformations. Put these in `domain/services/` as pure functions with unit tests.

### Screens and widgets
- Base classes: `StatelessWidget`, `SignalWidget` (signals_flutter) or `HookWidget` only. NEVER `StatefulWidget`.
- Widgets contain NO business logic. They read state only via the view model's `ReadonlySignal` getters and call view model methods.
- Never call use cases, repositories or domain functions from widgets. The view model does it and exposes the result.
- Widgets may import domain models/enums and extensions, never `data/`.
- **Only the screen** calls `sl<XViewModel>()` (once). Its sections receive `vm` as a constructor parameter. Never call `sl<XViewModel>()` further down the tree (that would be a second, empty instance).
- Reusable leaf widgets (rows, chips, cards) take only data and callbacks, never a view model.
- Exception: a self-contained widget placed on a screen as a whole (e.g. a header timer button) may create its own view model with `useMemoized` and dispose it. This is only safe when all its state lives in repository signals.
- Complex local state: use hooks; extract a custom hook if reusable.
- Use the project's UI kit/wrapper components for all UI. Don't scatter raw Material/Cupertino widgets if a design system exists.
- All screens are registered in the router (one `GoRoute` subclass per feature, collected in one routes file).
- All user-visible strings live in `.arb` files, read with `getAppLocalizations(context)` in widgets, and via an injected l10n service in view models.
- Colours and hex values live ONLY in the theme file. Use theme tokens everywhere else.

### Widget file rules (important)
- **One public widget per file.** Do NOT declare private widget classes (`class _Foo extends StatelessWidget`) in the parent file.
- Extract every sub-widget into its own file under `presentation/widgets/<area>/`, public and named after what it is.
- Do NOT use `_buildX()` helper methods that return widgets. Use widget classes.
- The only tolerated exception is a trivial purely visual fragment of about 20 lines or fewer, with no parameters of its own, used once. When in doubt, extract.
- Keep screens thin: a screen composes widgets and passes `vm` down.

## Dependency injection (`setup_dependencies.dart`, per feature)
- Data sources: `registerLazySingleton`
- Repositories: `registerLazySingleton`
- Use cases: `registerFactory`
- View models: `registerFactory`
- A central `core/service_locator.dart` calls each feature's setup function.

## Error handling
- Data source throws → repository catches and returns `Either` → use case passes it on → view model turns it into state or a toast. Widgets just render.
- Use typed exception/error classes, not strings.

## Testing
- Use cases: unit tests with mocked repositories (happy path and edge cases). These are the most important tests.
- Repositories: tests with mocked data sources, including the error path.
- Services and extensions: plain unit tests.
- Widgets: widget tests with a fake view model or mocked dependencies.

## Checklist for every change
1. Code lives in the right layer and imports only inward.
2. No logic in widgets or view models; it is in use cases or services.
3. No `StatefulWidget`, no private widget classes, no `_build` methods.
4. Strings in `.arb`, colours in theme.
5. New use case → unit test. New dependency → registered in `setup_dependencies.dart`.
6. Run `dart analyze` and `dart format`.

## Addendum

1. **Long-running jobs** (workflow runs, auto-reconnect) live in a repository that holds their state in signals, such as `WorkflowRunRepository` or `ConnectionRepository`. Use cases drive them.
2. **View model disposal:** screens are `HookWidget`s that create their view model with `useMemoized(() => sl<XViewModel>())` and dispose it in `useEffect`. View models implement `dispose()` and clean up effects and subscriptions.
3. **Device colours:** the per-device accent palette lives only in the theme file. Extensions such as `DeviceFinishX` return theme tokens, never hex values.
4. **Use cases** may write to the device through repositories. "No side effects" means no UI side effects. Haptics, toasts and navigation live in view models through injected core services (`HapticsService`, `ToastService`, l10n service), so they can be mocked in tests.
