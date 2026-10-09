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

### Analyzer result — resolved

Flutter stable is now installed at `~/flutter`. The tightened analyzer reported **8 issues, all `info`**, all fixed in `5a68966`:

- 6 × `comment_references` — doc comments on `BaseNotifier` and `Notifier` referenced `[setState]` and `[forced]` from scopes where neither is visible. `BaseNotifier` does not declare `setState` at all, so these pointed at nothing; they now point at `Notifier.setState`.
- 1 × `unnecessary_this` in `async_notifier.dart`.
- 1 × `use_super_parameters` in the new test helper.

`flutter analyze --fatal-infos`, `dart format`, and the test suite are all green.

**Prediction that was wrong:** `strict-raw-types` did *not* flag `read<N extends BaseNotifier>()`. The option covers raw type *annotations*, not raw type-parameter *bounds*. The fix is still worth making, but it belongs to Bug 5 and no gate forces it.

### Correction to an earlier claim

`CHANGELOG.md` is **not** corrupted. The entry for 0.1.9 has its backticks intact. The stripped-identifier text ("from  to ") is in the **git commit message** of `657de14`, which cannot be rewritten on a published branch and does not matter to users. No action.

`CHANGELOG.md` does record that the `builder` signature deliberately moved from `(context, state)` to `(state, child)` in 0.1.9. So `PLAN.md` §3.2's proposal to re-add `BuildContext` reverses a deliberate decision — it is a decision to revisit, not a bug. What **is** a defect is that the README still shows `(context, data, child)` in its examples; the docs contradict the shipped API. Fix the README in §1.5 regardless of how §3.2 is decided.

---

## 1.2 Bug fixes

One pull request per numbered item. Every one opens with the failing test and closes with the fix. No batching — a batched PR cannot be reverted cleanly when one fix turns out wrong.

### Bug 1 — `listenWhen` receives a frozen `previous` — FIXED `4cc489e`

**File** `lib/src/builders/base/base_notifier_builder.dart`

Confirmed, with a second cause the original write-up missed. `late S _previous = _notifier.state` is a **lazy** initializer: it first evaluated inside the first notification, by which point the state had already changed. So the very first `listenWhen` call compared a state against itself. On top of that, the field was only advanced in the rebuild branch of `buildWithChild`, which a builder-less `NotifierListener` never reaches.

Observed for three consecutive increments: `[[1,1], [1,2], [1,3]]`. Expected `[[0,1], [1,2], [2,3]]`.

**Fix as shipped** differs from the plan. A single `_previous` cannot serve both predicates: listeners run before the rebuild, so advancing one shared field in the listener path makes `buildWhen` receive `(current, current)`. Split into two fields with the semantics `flutter_bloc` uses:

- `_listenerPrevious` advances on **every** notification, accepted or not.
- `_builderPrevious` (now `_state`, see Bug 2) advances **only** when a rebuild is accepted, so `buildWhen` keeps comparing against what is on screen.

Both are assigned eagerly in `initState`.

**Tests** `test/src/builders/notifier_listener_test.dart`, 4 cases.

### Bug 2 — stale `child` and stale `builder` closure — FIXED `a752cf2`

**File** same

Confirmed, but **narrower than claimed and with a deeper cause.** The original write-up said any parent rebuild with a new child would render the stale one. It does not: with the default `buildWhen`, `_shouldRebuild` returned `true`, the first branch ran, and the cache was bypassed. The cache was only reachable when `buildWhen` returned `false`, or when the widget had no builder at all. Both paths were verified broken — a new child rendered nothing (`Found 0 widgets with text "b"`).

**The fix could not be "delete the cache".** Rebuilds were driven by a `Provider.of<N>(context)` dependency, so the element rebuilt on every notification and `buildWhen` was applied *afterwards* to undo it. The cache existed purely to have something to return once a rebuild had already happened; removing it would leave nothing to return.

**Fix as shipped** Drive rebuilds from the notifier and call `setState` only when `buildWhen` accepts — the `flutter_bloc` architecture. `buildWhen` now decides whether a rebuild happens at all instead of discarding one that already did. Consequences:

- no cached subtree; `build` always runs the current builder with the current child
- `buildWhen` is no longer called during the initial build. It previously ran once at mount comparing the initial state against itself — an extra defect found by the tests, not in the original list.
- a rejected `buildWhen` costs one predicate call and no element rebuild
- retention per builder goes from one state reference plus a cached widget subtree to two state references, inside the `CONTRIBUTING.md` budget

**Tests** `test/src/builders/notifier_builder_test.dart`, 9 cases.

### Bug 3 — notifies after disposal, swallows init failures — FIXED `6ce167c`

**File** `lib/src/notifier/lifecycle_mixin/async_notifier_lifecycle.dart`

Both halves confirmed exactly as written. Disposing before `onInit` resolved threw `A TestAsyncNotifier was used after being disposed`; a throwing `onInit` left the notifier in `loading` with the error unhandled.

**Fix as shipped** `_disposed` on `_RootBaseNotifier`, set in a `dispose()` override and exposed as a public `isDisposed`. `_initialize` guards the completion and adds an `onError` that routes to `AsyncState.error` with the original error and stack trace.

`setState` after disposal is deliberately left throwing on every other path — it is the same contract as `setState` on an unmounted `State`, and silencing it would hide real bugs in user code. `isDisposed` is public so a notifier owning its own async work can check it. This flag is the prerequisite for `fromFuture` / `fromStream` in `PLAN.md` §3.3.

**Tests** `test/src/notifier/async_notifier_test.dart`, 4 cases.

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

### Bug 11 — `buildWhen` was invoked during the initial build — FIXED with Bug 2

Found by the Bug 2 tests, not in the original list. `buildWhen` ran once at mount, comparing the initial state against itself, so a predicate with logging or any other side effect fired spuriously before any change had occurred. `flutter_bloc` never consults `buildWhen` for the first build. The Bug 2 rework removed the call as a side effect of moving the decision into the notification path.

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
| 2 | ~~Read the first CI run~~ — done locally; analyzer clean, 8 infos fixed | step 3 |
| 3 | ~~Bugs 1, 2, 3~~ — fixed, 27 tests green, coverage 14% → 48% | 0.2.0 |
| 4 | Bug 5 + the raw-type fix, then §1.3 | clean analyzer |
| 5 | Decide D1 and D2, then Bugs 6–10 | 0.2.0 |
| 6 | Bug 4 contract + §1.5 docs pass | 0.2.0 |
| 7 | §1.4 pub.dev setup, dry run, tag `v0.2.0` | Phase 2 |

Phase 2's test suite is written in parallel from step 3 onward — every bug fix above contributes its regression test to it, so the two phases share the work instead of duplicating it.
