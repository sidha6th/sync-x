# Phase 1 — Stop the bleeding

Detailed plan for `PLAN.md` §1. Target release: **0.2.0**. Nothing in Phase 3 or 4 starts until §6 of this document is fully checked.

Order matters: gates land before fixes, so no fix can regress silently and every later fix is proven by a test the gate enforces.

---

## 1.1 Gates and repo rules — DONE in this change

| Artifact | Purpose |
|---|---|
| `.github/workflows/ci.yml` | format, analyze, test, coverage gate, publish dry run, on every push and PR to `master`/`dev`; separate job analyzes and builds `example/` |
| `.github/workflows/publish.yml` | tag-triggered publish to pub.dev, re-running every gate first |
| `tool/check_coverage.sh` | parses `coverage/lcov.info`, fails below `COVERAGE_MIN` |
| `tool/check_version.sh` | fails if the git tag disagrees with `pubspec.yaml` or `CHANGELOG.md` |
| `analysis_options.yaml` | `strict-casts`, `strict-inference`, `strict-raw-types` plus 12 added lints |
| `CONTRIBUTING.md` | `PLAN.md` §0 restated as a reviewer checklist |
| `test/helpers/`, `test/src/notifier/notifier_test.dart` | first 10 real tests, so CI has something to gate on |
| `example/main.dart` | deleted — duplicate of `example/lib/main.dart`, which is the path pub.dev reads |

### Known: the first CI run will likely be red

The Flutter SDK is not installed on the development machine this plan was written on, so the tightened analyzer could not be run locally. `strict-raw-types` is already known to flag at least one pre-existing violation:

- `lib/src/utils/extensions/build_context_extensions.dart` — `read<N extends BaseNotifier>()` uses the raw type; the bound must be `BaseNotifier<Object?>`.

That is the intended sequence, not an accident: tighten the gate, read what it reports, fix the list. Treat the first run's output as the real task list for §1.2 and append anything it finds. Do **not** relax the analyzer to get green — fix the code, or stage one option out with a dated note in this file saying which bug fix will re-enable it.

### Correction to an earlier claim

`CHANGELOG.md` is **not** corrupted. The entry for 0.1.9 has its backticks intact. The stripped-identifier text ("from  to ") is in the **git commit message** of `657de14`, which cannot be rewritten on a published branch and does not matter to users. No action.

`CHANGELOG.md` does record that the `builder` signature deliberately moved from `(context, state)` to `(state, child)` in 0.1.9. So `PLAN.md` §3.2's proposal to re-add `BuildContext` reverses a deliberate decision — it is a decision to revisit, not a bug. What **is** a defect is that the README still shows `(context, data, child)` in its examples; the docs contradict the shipped API. Fix the README in §1.5 regardless of how §3.2 is decided.

---

## 1.2 Bug fixes

One pull request per numbered item. Every one opens with the failing test and closes with the fix. No batching — a batched PR cannot be reverted cleanly when one fix turns out wrong.

### Bug 1 — `listenWhen` receives a frozen `previous`

**File** `lib/src/builders/base/base_notifier_builder.dart`

`_previous` is assigned only inside the rebuild branch of `buildWithChild`. A pure `NotifierListener` passes no `builder`, so `_shouldWatch` is `false`, that branch never runs, and `_previous` stays at the state captured in `initState` for the widget's whole life. Every `listenWhen(previous, current)` call therefore compares against the initial state. The same freeze happens on a `NotifierConsumer` for as long as `buildWhen` returns `false`.

**Failing test** `listenWhen` receives `(0,1)`, `(1,2)`, `(2,3)` across three consecutive increments. Today the second and third calls both report previous `0`.

**Fix** Move ownership of `_previous` into the notification path, and register the listener unconditionally rather than only when `widget.listener != null`:

```dart
void _triggerListener() {
  final next = _notifier.state;
  final shouldCall = widget.listenWhen?.call(_previous, next) ?? true;
  _previous = next;
  if (shouldCall) widget.listener?.call(next);
}
```

`buildWithChild` must stop writing `_previous` once this lands, or the two paths will race to advance it.

**Risk** `buildWhen` now sees a `previous` advanced by the listener path. That is the correct bloc-compatible semantic — `previous` means "the state before this change", not "the state at the last rebuild" — but it is an observable behavior change for anyone who wrote `buildWhen` against the buggy behavior. It goes in the 0.2.0 CHANGELOG as a fix with a note.

### Bug 2 — stale `child` and stale `builder` closure

**File** same

```dart
return _cachedWidget ??= (widget.builder?.call(state, child) ?? child ?? const SizedBox.shrink());
```

`??=` assigns once and never recomputes. When the parent rebuilds with a **new** `child` but the notifier state has not changed, the old cached subtree is returned and the new child is silently dropped. The captured `widget.builder` closure goes stale the same way after a hot reload or a parent rebuild with a new callback.

**Failing test** Mount a `NotifierBuilder` with `child: Text('a')`, rebuild the parent with `child: Text('b')` and no state change, expect `Text('b')`. Today it finds `Text('a')`.

**Fix** Delete `_cachedWidget` and both of its read sites. Flutter's element diffing already skips subtrees whose widget instances are identical, so the cache buys nothing measurable while costing one retained subtree per builder — a direct violation of the `PLAN.md` §0.2 retention budget. This is the §0.1 rule in action: remove the mechanism, do not add invalidation.

**Verification** The §2.4 benchmark must show no regression versus the cached version. If it does regress, the cache comes back only with a measurement attached and a `didUpdateWidget` invalidation.

### Bug 3 — `AsyncNotifier` notifies after disposal and swallows init failures

**File** `lib/src/notifier/lifecycle_mixin/async_notifier_lifecycle.dart`

```dart
void _initialize(void Function(AsyncState<S> state) whenCompleted) {
  onInit().then(whenCompleted);
}
```

Fired from the constructor with no disposal guard and no `onError`. Two separate defects:

- Dispose the owning widget before the future resolves and the completion calls `notifyListeners()` on a disposed `ChangeNotifier`: `A <Notifier> was used after being disposed`. This is the crash a user hits by backing out of a screen during a slow network call — the single most reachable bug in the library.
- An `onInit` that throws becomes an unhandled async error. The notifier never leaves `loading`, so the UI shows a spinner forever with no error surfaced.

**Failing tests** Two. (a) Build a widget with an `AsyncNotifier` whose `onInit` completes from a `Completer`, unmount, complete the `Completer`, expect no exception and no notification. (b) An `onInit` that throws leaves the state as `error` carrying the original error and stack trace.

**Fix** Add a disposal flag on `_RootBaseNotifier` and guard the completion:

```dart
void _initialize(void Function(AsyncState<S> state) whenCompleted) {
  onInit().then(
    (state) {
      if (!_disposed) whenCompleted(state);
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!_disposed) {
        whenCompleted(AsyncState.error(error, stackTrace: stackTrace));
      }
    },
  );
}
```

`_RootBaseNotifier` needs a `dispose()` override setting `_disposed = true` before `super.dispose()`. One bool per notifier, inside the §0.2 retention budget. No cancellation token, no subscription registry — those belong to `onDispose` in Phase 3.

**Note** The flag is a prerequisite for `fromFuture` / `fromStream` in `PLAN.md` §3.3. Land it correctly once, here.

### Bug 4 — `onInit()` runs before the subclass constructor body

**File** `lib/src/notifier/async_notifier.dart`, `lib/src/notifier/notifier.dart`

Both constructors call `_initialize()` in their body. Dart runs a superclass constructor body before the subclass's, so the synchronous prefix of a user's `onInit` executes before any field the user assigns in their own constructor body. A notifier that takes a repository and assigns it in its constructor body sees `null` inside `onInit`.

**Failing test** A notifier assigning a field in its constructor body and reading it in `onInit` — assert it is visible, or assert a clear diagnostic rather than a `LateInitializationError`.

**Fix** Document the contract: dependencies must arrive through `super`-reachable final fields or initializing formals, not constructor-body assignment. Add a debug-only assertion if a cheap detection exists.

**Explicitly rejected** `Future.microtask(_initialize)`. It appears to fix the ordering by deferring one turn of the event loop — which is exactly the timing dodge `PLAN.md` §0.2 forbids. It would convert a deterministic failure into a timing-dependent one, and it would make `onInit` fire after the first frame, changing the initial-state contract for every existing user.

### Bug 5 — `state` is `@protected`, so nobody can read it

**File** `lib/src/notifier/base/base_notifier.dart`

```dart
@protected
S get state => _state;
```

`context.read<CounterNotifier>().state` is an analyzer error for every consumer of the library. The proof that the annotation is wrong is in SyncX's own source: `base_notifier_builder.dart` opens with `// ignore_for_file: invalid_use_of_protected_member` purely to read it, and the test helper in `test/helpers/counter_notifier.dart` has to re-expose it through a `current` getter. By `PLAN.md` §0.3, a library that must ignore its own lint has the wrong API.

**Fix** Make `state` public. Keep `setState`, `addListener`, and `removeListener` protected — those are genuinely framework-internal, and the builders are the only legitimate callers.

**Bundle with** `read<N extends BaseNotifier>()` → `read<N extends BaseNotifier<Object?>>()`, the raw type `strict-raw-types` flags.

**Risk** None for users; this only widens access. The `@protected` removal is not breaking.

### Bug 6 — `AsyncState` equality ignores the type parameter

**File** `lib/src/utils/models/base/base_async_state.dart`

`if (other is! BaseAsyncState) return false;` tests the raw type, so `AsyncState<int>.data(1) == AsyncState<num>.data(1)` is `true`. Combined with the equality-driven `setState`, a notifier can silently refuse an update that legitimately changed the state's type.

**Fix** Compare against `BaseAsyncState<S>`.

### Bugs 7–9 — `AsyncState` transitions are internally inconsistent

**File** `lib/src/utils/models/async_state.dart`

Three defects with one root cause — `_copyWith` is doing load-bearing work it cannot do correctly:

- **7** `toLoading()` returns `_copyWith(status: loading)`, which keeps `data`. But `when` switches on status, takes the `loading` branch, and never exposes it. The retained data is unreachable — pure memory cost against the §0.2 budget, and a half-built feature.
- **8** `toError(...)` keeps `data` while the `BaseAsyncState.error()` constructor nulls it. Two ways to reach an error state, two different results.
- **9** `_copyWith` uses `data ?? this.data`, so null is indistinguishable from "unchanged" and no field can ever be cleared.

**Fix** Resolve decision **D1** in `PLAN.md` §5 first; the default is to collapse `BaseAsyncState` into `AsyncState`, since one abstract class with exactly one subclass costs a file, a `part` directive and an indirection for nothing (§0.1). Then delete `_copyWith` and write the three transitions explicitly — each one names every field it sets, which is both shorter than a correct `copyWith` and impossible to get wrong.

Whether `data` survives a transition is decision **D2** (default: yes for `toError`, surfaced rather than hidden; the refresh story for `toLoading` is `PLAN.md` §3.2). Either way, §2.2's tests must assert `status`, `data`, and `errorState` explicitly for all nine transitions so the decision is locked in code.

### Bug 10 — contradictory equality in `AsyncNotifier.setState`

**File** `lib/src/notifier/async_notifier.dart`

```dart
equalityCheck: (curr, next) =>
    (equalityCheck?.call(curr.data, next.data) ??
        this.stateEqualityCheck(curr, next)) &&
    curr == next,
```

With no custom check this evaluates `curr == next && curr == next`. With one, the user's intent is ANDed with full state equality, so a custom check reporting "these are equal, do not update" still updates whenever the status differs — the opposite of what the doc comment promises.

**Fix** One check, one meaning: if the caller supplies `equalityCheck`, it decides, on `data`. Otherwise `stateEqualityCheck` decides, on the whole state.

---

## 1.3 Delete the self-ignore

Remove `// ignore_for_file: invalid_use_of_protected_member` from `lib/src/builders/base/base_notifier_builder.dart` and fix what breaks. Bug 5 removes most of the need; `addListener` / `removeListener` stay protected, and the builder is a legitimate framework caller, so a single narrowly-scoped `// ignore:` on those specific lines is acceptable where a file-wide one is not.

`analysis_options.yaml` already raises `invalid_use_of_protected_member` to `error`, so this cannot silently regress once the ignore is gone.

Same cleanup applies to `test/src/notifier/notifier_test.dart`, which currently carries the same file-wide ignore for the same reason.

---

## 1.4 pub.dev automated publishing — one-time setup (manual)

The workflow is committed; these steps are on the repo and package owner and cannot be scripted from here.

1. **GitHub**: create an environment named `pub.dev` under Settings → Environments. Add required reviewers if you want a human approval gate before each publish. The workflow already targets `environment: pub.dev`.
2. **pub.dev**: open <https://pub.dev/packages/syncx/admin> → *Automated publishing* → enable *Publishing from GitHub Actions*.
   - Repository: `sidha6th/sync-x`
   - Tag pattern: `v{{version}}`
   - Require the GitHub environment: `pub.dev`
3. Verify no secret is needed. The `pub` client performs the OIDC exchange itself using the token the `permissions: id-token: write` block grants, so there is no `PUB_TOKEN` to store and nothing to rotate. If the publish step reports a missing credential, the cause is a missing `id-token: write` permission or a tag that does not match the configured pattern — not an absent secret.
4. **Dry run before trusting it.** Run the workflow manually (`workflow_dispatch`, `dry_run: true`). It executes every gate and `flutter pub publish --dry-run`, and stops before publishing.
5. **First real release**: tag `v0.2.0`. `tool/check_version.sh` fails the job unless `pubspec.yaml` says `0.2.0` and `CHANGELOG.md` has a `## 0.2.0` section, so a mismatched release cannot reach pub.dev.

### Why a Flutter-specific job instead of the shared workflow

The documented shortcut is `dart-lang/setup-dart/.github/workflows/publish.yml@v1`. It installs the Dart SDK only, and `syncx` depends on the Flutter SDK, so dependency resolution fails there. `publish.yml` therefore runs its own job with `subosito/flutter-action` and keeps `permissions: id-token: write`, which is the only part the OIDC exchange actually needs.

### Branch protection

Protect `master`: require the `verify` and `example` checks from `ci.yml`, and disallow direct pushes. Gates that can be bypassed are documentation, not gates.

---

## 1.5 Documentation truth pass

Cheap, and it removes the contradictions a new user hits first.

- README examples show `builder: (context, data, child)`; the shipped `BuilderCallback` is `(S state, Widget? child)`. Fix every occurrence to match the code.
- `async_notifier_lifecycle.dart`'s `onUpdate` doc comment shows an override named `onUpdated`. The method is `onUpdate`. The `comment_references` lint now added to `analysis_options.yaml` will catch this class of error going forward.
- Document the §1.2 Bug 4 constructor-ordering contract on `onInit` for both `Notifier` and `AsyncNotifier`.
- `CHANGELOG.md` for 0.2.0 lists every §1.2 fix, with the Bug 1 `buildWhen`/`listenWhen` semantic change called out explicitly.

---

## 1.6 Definition of done

Phase 1 ships when all of these are true:

- [ ] `ci.yml` green on `master`, with `--fatal-infos` and all three `strict-*` options enabled and none staged out.
- [ ] Bugs 1–10 fixed, each in its own PR, each with a regression test that fails on the parent commit.
- [ ] No `ignore_for_file` anywhere in `lib/`.
- [ ] `COVERAGE_MIN` raised from `0` to the measured value, in the same PR that first measures it, and never lowered after.
- [ ] Decisions D1 and D2 from `PLAN.md` §5 recorded in that file with a date.
- [ ] README and dartdoc agree with the shipped API (§1.5).
- [ ] `pub.dev` environment configured, automated publishing enabled, `workflow_dispatch` dry run green (§1.4).
- [ ] `master` protected, requiring both CI jobs.
- [ ] `v0.2.0` tagged and published by the workflow — never by hand.

## 1.7 Sequencing

| Step | Work | Blocks |
|---|---|---|
| 1 | This change: gates, scripts, lints, `CONTRIBUTING.md`, first tests | everything |
| 2 | Read the first CI run; append its findings to §1.2 | step 3 |
| 3 | Bugs 1, 2, 3 — the three that ship wrong behavior today | 0.2.0 |
| 4 | Bug 5 + the raw-type fix, then §1.3 | clean analyzer |
| 5 | Decide D1 and D2, then Bugs 6–10 | 0.2.0 |
| 6 | Bug 4 contract + §1.5 docs pass | 0.2.0 |
| 7 | §1.4 pub.dev setup, dry run, tag `v0.2.0` | Phase 2 |

Phase 2's test suite is written in parallel from step 3 onward — every bug fix above contributes its regression test to it, so the two phases share the work instead of duplicating it.
