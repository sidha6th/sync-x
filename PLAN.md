# SyncX: Hardening & Growth Plan

Status: draft, 2026-10-10. Baseline: v0.1.9, 0 tests, 11 source files, ~1.1k lines in `lib/`.

This document is the single source of truth for what we fix, in what order, and what we deliberately refuse to build.

---

## 0. Guiding principles

These are decision rules, not aspirations. When a change is proposed, it must pass all of them.

### 0.1 More code is not more quality

A state management library sits in the hot path of every frame of every screen. Its value comes from what it *prevents*, not what it offers. So:

- **Deletion beats addition.** If a bug can be fixed by removing a mechanism instead of guarding it, remove the mechanism. Example: the widget cache in `base_notifier_builder.dart` causes a stale-child bug. The fix is to delete the cache, not to add invalidation logic.
- **No feature without a named user problem.** "bloc has it" is not a reason. Write the two-line problem statement first. If it cannot be written, the feature does not ship.
- **One way to do each thing.** Two APIs with overlapping purpose double the test matrix, the docs, and the support burden, and halve the clarity. Prefer removing the weaker one over documenting both.
- **No abstraction with one implementation.** `BaseAsyncState` currently has exactly one subclass (`AsyncState`). That split costs a file, an indirection, and a `part` directive, and buys nothing until a second implementation exists.
- **Wrapping `provider` is a liability, not an asset.** Every API we add that `provider` already has is surface we maintain for no differentiation. Expose what `provider` does well; build only what it does not.

### 0.2 Performance budget (mobile-first, non-negotiable)

Targets are per state change, measured, not assumed.

| Budget | Limit | Why |
|---|---|---|
| Allocations per `setState` | 0 beyond the new state object itself | GC pauses drop frames on low-end Android |
| Allocations per rebuild check | 0 | `buildWhen` runs on every notification |
| Closures created per build | 0 new long-lived ones | closure churn is the usual hidden cost in builder-heavy libs |
| Retained per notifier | O(listeners), nothing else | no caches, no history, no snapshots |
| Retained per builder widget | 1 state ref + 1 listener | today it is also a cached `Widget` subtree — remove it |
| Added rebuild work vs raw `ChangeNotifier` | within 10% | if we are slower than the thing we wrap, we have no product |
| Package size | `lib/` under 1500 lines | review any PR that pushes past it |
| Dependencies | `provider` only | each new dep is a version-conflict risk for every consumer app |

Hard rules that follow from the budget:

- **No timers, no `Future.delayed`, no polling, ever** — not in library code, not to fix a race. Order concurrent work with real completion signals (`Completer`, `Future`, the existing notifier lifecycle). A sleep that "fixes" a race ships the race to users with a different timing profile.
- **No caching state, widgets, or computed values** unless a benchmark proves the recompute is the bottleneck. Caches are the #1 source of staleness bugs and retained memory.
- **No history, no undo stack, no transition log** in release builds. If an observer is added (§3.4), it must be a no-op with zero retention when unset.
- **No reflection, no `dart:mirrors`, no codegen.** Codegen is why people leave riverpod.
- **No deep equality by default.** `==` on the state object is the contract; the user opts into more via `equalityCheck`.
- **No unbounded growth.** Any map/list the library holds must have an obvious removal path, written in the same PR that adds it.

### 0.3 Correctness rules

- Every public behavior has a test before it is documented as working.
- Every bug fix lands with the failing test first, in the same PR.
- The library never uses `// ignore:` to silence a lint about its own API. If `invalid_use_of_protected_member` is needed to consume our own class, the API is wrong — fix the API.
- Async work that outlives a widget must be guarded against disposal. No exceptions.
- Breaking changes bump the minor version while pre-1.0 (`0.1.x` → `0.2.0`), never the patch.

### 0.4 What we explicitly will NOT build

Recorded so it stops coming up:

- Code generation or build_runner integration.
- A DI container. `provider` is the container.
- Global singleton access / service locator.
- Event/action classes (bloc's events). The notifier method *is* the event.
- Middleware chains, interceptors, or plugin pipelines.
- Time-travel debugging, state persistence, hydration. These belong in separate opt-in packages.
- Freezed-style generated unions for `AsyncState`.
- A router, a form library, or anything not state.

---

## 1. Phase 1 — Stop the bleeding (blocking, ~1 week)

Nothing else matters until this phase is green. Ship as `0.2.0`.

### 1.1 Repo rules and infrastructure

| Task | File | Notes |
|---|---|---|
| Add `CONTRIBUTING.md` | new | encode §0 as a reviewer checklist |
| Add `.github/workflows/ci.yml` | new | see below |
| Tighten analyzer | `analysis_options.yaml` | add `strict-casts`, `strict-raw-types`, `strict-inference` under `analyzer: language:` |
| Remove tracked junk | `example/main.dart` | duplicate of `example/lib/main.dart`; pub.dev reads `example/lib/main.dart` |
| Fix `CHANGELOG.md` 0.1.9 entry | `CHANGELOG.md` | backticked identifiers were stripped; it currently reads "from  to " |

CI gates (all must pass, no merge otherwise):

```yaml
- dart format --output=none --set-exit-if-changed .
- flutter analyze --fatal-infos
- flutter test --coverage
- coverage threshold check (see §2.5)
- dart pub publish --dry-run
```

### 1.2 Bug fixes (each with a failing test first)

Ordered by user impact.

1. **`listenWhen` previous never advances** — `lib/src/builders/base/base_notifier_builder.dart`
   `_previous` is only written in the rebuild branch of `buildWithChild`. A pure `NotifierListener` has `builder == null`, so `_shouldWatch` is false and `_previous` is frozen at the initial state for the widget's whole life. Same when `buildWhen` returns false.
   Fix: make `_triggerListener` own `_previous`; always register the listener, not only when `widget.listener != null`.

2. **Stale `child` / stale `builder` closure** — same file, `_cachedWidget ??= ...`
   Once set, never recomputed. A parent rebuild with a new `child` renders the old one.
   Fix: delete `_cachedWidget` entirely. Flutter's element diffing already skips identical subtrees; the cache buys nothing measurable and costs a retained subtree per builder (§0.2).

3. **`AsyncNotifier` notifies after dispose, and swallows init errors** — `lib/src/notifier/lifecycle_mixin/async_notifier_lifecycle.dart`
   `onInit().then(whenCompleted)` is fired from the constructor with no disposal guard and no `onError`. Disposing the owning widget before the future resolves throws `A <Notifier> was used after being disposed`; an `onInit` that throws becomes an unhandled async error and the notifier sits in `loading` forever.
   Fix: add a `_disposed` flag set in a `dispose()` override on `_RootBaseNotifier`; guard the completion and route errors to `AsyncState.error`.

4. **`onInit()` runs before the subclass constructor body** — superclass constructor bodies execute first, so the synchronous prefix of `onInit` sees unset subclass fields. Any notifier that assigns a repository in its constructor body breaks.
   Fix: deps must arrive via `super`-reachable final fields; document it, and assert in debug if we can detect misuse. Do **not** paper over it with `Future.microtask` — that is a timing dodge (§0.2).

5. **`state` getter is `@protected`** — `lib/src/notifier/base/base_notifier.dart`
   Consumers cannot read `context.read<CounterNotifier>().state` without a lint error, and our own builder file needs `// ignore_for_file: invalid_use_of_protected_member` to compile. Per §0.3, the API is wrong. Make `state` public; keep `setState` protected.

6. **`AsyncState` equality ignores the type parameter** — `base_async_state.dart` tests `other is! BaseAsyncState` (raw), so `AsyncState<int>.data(1) == AsyncState<num>.data(1)`.

7. **`toLoading()` retains `data` that `when` cannot reach** — `async_state.dart`. Status is `loading`, so `when` takes the loading branch and the retained data is dead weight in memory. Decide one way (§3.2) — either drop it or expose it properly as refresh state.

8. **`toError` keeps `data` but `BaseAsyncState.error()` nulls it** — pick one and make both agree.

9. **`_copyWith` cannot clear a field** — `data ?? this.data` means null is indistinguishable from "unchanged". Use a sentinel or make the transitions explicit (the latter is less code).

10. **Redundant/contradictory equality in `AsyncNotifier.setState`** — the no-custom-check path evaluates `curr == next && curr == next`; the custom path ANDs the user's intent with full state equality, so a custom check reporting "equal" still updates whenever the status differs. That contradicts the doc comment. Collapse to one check.

### 1.3 Delete the self-ignore

Remove `// ignore_for_file: invalid_use_of_protected_member` from `base_notifier_builder.dart` and fix whatever breaks. It is hiding API design errors, not lint noise.

---

## 2. Phase 2 — Test suite (blocking, ~1 week, parallel with Phase 1)

### 2.1 Philosophy

- `flutter_test` only. **No mockito, no mocktail, no build_runner.** Fake notifiers are 5 lines each.
- One file per source file: `test/src/<mirrors lib path>_test.dart`.
- Shared fakes in `test/helpers/` — a `CounterNotifier`, a controllable `TestAsyncNotifier` backed by a `Completer`, a `RebuildCounter` widget. Nothing else.
- Tests assert **observable behavior**, never private fields.
- Every test is deterministic. No `pumpAndSettle` on real durations, no `Future.delayed` in tests — drive async with `Completer` and `pump()`. Same rule as library code (§0.2).

### 2.2 Unit tests

`BaseNotifier` / `Notifier`
- `setState` matrix: `forced` × `notify` × `equalityCheck` × {changed, unchanged} — assert state value *and* listener call count for each cell.
- Unchanged state does not notify; `forced: true` notifies anyway.
- `notify: false` updates state, fires `onUpdate`, does not notify.
- `notifyListeners()` throws `UnsupportedError`.
- `onUpdate` fires after state is written, once per accepted update, never on a rejected one.
- `onInit` fires exactly once per instance.
- `toString()` includes identity and state.
- Custom `stateEqualityCheck` override is honored.
- Listener added, then removed, then state changes → not called.

`AsyncNotifier`
- `AsyncNotifier()` starts `loading`; `.withData(x)` starts `data(x)`.
- `onInit` resolving to data → state becomes that data, listeners notified once.
- `onInit` throwing → state becomes `error` carrying the original error and stack trace.
- **Dispose before `onInit` completes → no throw, no notification** (regression test for 1.2.3).
- `setLoading` / `setData` / `setError` transitions from each of the three starting statuses — 9 cases.
- `setData` with an equal value and `forced: false` → no notification.
- `equalityCheck` receives `data`, not the wrapper state.

`AsyncState`
- `when` and `whenData` across all three statuses, including the optional-callback-absent paths.
- `==` / `hashCode`: equal pairs, each-field-differs pairs, cross-type pair (regression for 1.2.6), and the `hashCode` consistency property.
- Every `to*` transition: resulting status, `data`, `errorState` — assert all three fields explicitly, so the 1.2.7–1.2.9 decisions are locked down.
- `toString()` per status.

`ErrorState` — construction, equality, optional message/stackTrace.

`NotifierRegister`
- `create` constructor provides the notifier to descendants and **disposes it** on unmount.
- `.value` constructor provides and **does not dispose**.
- `lazy: false` constructs eagerly; `lazy: true` (default) constructs on first read.
- Reading a type that was never registered throws `ProviderNotFoundException`.

`BuildContextExtensions` — `read` returns the instance without subscribing (assert: a state change after a `read` causes no rebuild).

### 2.3 Widget tests (the ones that actually protect the product)

Rebuild-count assertions are the core of this suite. The whole pitch is "precise rebuild control" — assert it numerically or it is a marketing claim.

- `NotifierBuilder`: builds once on mount; one rebuild per accepted state change; **zero** rebuilds when `buildWhen` returns false; zero rebuilds when the state is unchanged.
- `NotifierBuilder` with a `child`: parent rebuild with a *new* child and unchanged state renders the new child (regression for 1.2.2).
- `NotifierListener`: `listener` fires per change, never rebuilds the subtree; `listenWhen` receives the correct `(previous, current)` pair across **three consecutive** changes (regression for 1.2.1); `listenWhen` false after a `buildWhen` false still sees the right previous.
- `NotifierConsumer`: listener fires before the rebuild; both predicates are independent.
- The three async widgets: same matrix, plus loading → data → error → data rendering, and the `.withData` constructors.
- `onInit` callback on builders fires once, receives the notifier, and is not re-fired on rebuild.
- Listener is detached on dispose: unmount the builder, change state, assert no call and no exception.
- Nesting: two notifiers, two builders, a state change on one rebuilds only its own builder.

### 2.4 Performance regression tests

Cheap, and they keep §0.2 honest:

- A benchmark test comparing rebuild count and elapsed time for `NotifierBuilder` vs a bare `ValueListenableBuilder` over 1000 state changes. Fail if more than 10% slower.
- An allocation smoke test: 10k `setState` calls on an unchanged value allocate nothing and notify zero times.

### 2.5 Coverage gates

- Phase 2 exit: **90% line coverage on `lib/src`**, and 100% on `base_notifier.dart`, `base_notifier_builder.dart`, `async_state.dart`.
- CI fails below the threshold. The number only goes up.

### 2.6 Integration test

`example/integration_test/` driving the existing example app. Catches lifecycle and dispose-ordering issues that widget tests miss (notably 1.2.3 in a real app teardown).

---

## 3. Phase 3 — Make it usable (~2 weeks). Ship as `0.3.0`

Each item below has a user problem attached, per §0.1.

### 3.1 Close the `BuildContext` gap

Problem: `context.read` is the only extension. `watch` and `select` are the first two calls a Flutter dev reaches for, and `select` is the only way to rebuild on one field of a large state object without a builder nest.

- `context.watch<N>()` → subscribe and return the notifier.
- `context.select<N, T>(T Function(S state))` → rebuild only when the projection changes.
- Both delegate to `provider`. Thin, already-tested machinery underneath — exactly the wrapping that *is* worth doing (§0.1).
- Fix the raw type: `read<N extends BaseNotifier>()` → `read<N extends BaseNotifier<Object?>>()`.

### 3.2 `BuildContext` in `builder`, and settle the refresh story

Problem 1: `BuilderCallback<S>` is `(S state, Widget? child)` — no context. Every competing library passes it, and the README examples already show `(context, state, child)`, so the docs contradict the code today.
→ Add context. This is a breaking signature change; it belongs in `0.3.0` with a migration note.

Problem 2: showing cached data while a refresh is in flight is the single most common async UI need, and `toLoading()` already retains the data but `when` cannot reach it.
→ Expose it honestly: add `isRefreshing` (status is loading **and** data is present) and make `when` take an optional `refreshing` branch that falls back to `data`. No new state class, no extra retention — the field is already there.

### 3.3 Composition and lifecycle

- `MultiNotifierRegister` — today users either nest `NotifierRegister` or drop to `MultiProvider`, which leaks the abstraction. Delegates to `MultiProvider`.
- `onDispose()` lifecycle hook — `onInit` exists with no symmetric close, so stream subscriptions and timers owned by a notifier have nowhere to go. This is a correctness gap, not a convenience.
- `AsyncNotifier.fromFuture` / `fromStream` helpers — the two shapes 90% of async notifiers actually are. Must cancel the subscription in `onDispose`, and must be guarded by the `_disposed` flag from 1.2.3.

### 3.4 `SyncxObserver`

Problem: there is no way to log or trace state transitions app-wide. bloc's `BlocObserver` is a large part of why teams trust bloc.

Constraint from §0.2: a single static nullable hook, called only when non-null, retaining nothing. No list of observers, no transition history, no buffering. If unset, the cost must be one null check per `setState`.

---

## 4. Phase 4 — Earn adoption (~1 week, docs-heavy). Ship as `0.4.0`

Code is not the bottleneck here; trust is.

- **Migration tables**: bloc → syncx, provider → syncx, riverpod → syncx. Side-by-side, same feature, both snippets. Highest-conversion page we can write.
- **An honest "why not SyncX" section.** State our limits: single maintainer, no scopes/families, `BuildContext`-bound, young. Developers trust libraries that state their trade-offs; they bounce off ones that only list features.
- **Lead with `AsyncNotifier`.** It is the actual differentiator: `AsyncNotifier<T>` with `Future<AsyncState<T>> onInit()` is four lines and no codegen. Everything else we offer, `provider` or bloc already offers. Restructure the README so this is above the fold.
- **Rebuild-control proof**: publish the §2.4 benchmark numbers in the README. A measured claim beats an adjective.
- pub.dev score work: tests, `example/lib/main.dart` correctness, dartdoc coverage. Score drives discovery.
- Consider publishing `AsyncState` + `AsyncNotifier` as a standalone package. Smaller ask for a new user, real adoption path, and it feeds traffic back to the main library.

---

## 5. Open decisions

Resolve before the phase that depends on them.

| # | Question | Blocks | Default if undecided |
|---|---|---|---|
| D1 | Collapse `BaseAsyncState` into `AsyncState`? One subclass only (§0.1). | 1.2.6–1.2.9 | Collapse. Less code, less indirection, smaller test matrix. |
| D2 | Does `toError` keep `data`? | 1.2.8 | Keep it, and surface it — an error banner over stale content is the better UX. |
| D3 | Do we want scopes/families (riverpod's real moat)? | long-term positioning | No, for now. It is a rewrite, not a feature. Revisit at 1.0. |
| D4 | Is `0.2.0` or `1.0.0` the target for the first "trustworthy" release? | all version numbers above | `0.2.0`. Earn 1.0 with real-world usage, not with a plan. |

---

## 6. Definition of done per phase

- **Phase 1**: CI green, 10 bugs fixed each with a regression test, no `ignore_for_file` in `lib/`, CHANGELOG readable, `0.2.0` published.
- **Phase 2**: 90% coverage on `lib/src`, rebuild-count tests passing, performance budget test in CI, integration test running against the example app.
- **Phase 3**: `watch`/`select`/`MultiNotifierRegister`/`onDispose`/observer shipped, each with tests and a README section, `0.3.0` published with a migration note for the `builder` signature change.
- **Phase 4**: migration tables live, benchmark numbers published, pub.dev score reviewed.

---

## 7. Start here

In order, today:

1. `.github/workflows/ci.yml` + tightened `analysis_options.yaml` + `CONTRIBUTING.md` — gates before fixes, so no fix regresses silently.
2. `test/helpers/` fakes, then the `BaseNotifier` / `Notifier` unit tests. They are the cheapest and cover the most-used path.
3. Bugs 1.2.1, 1.2.2, 1.2.3 — failing test first, then the fix. These three ship wrong behavior to users today, silently.
4. Everything else in Phase 1 order.
