# Contributing to SyncX

Read `PLAN.md` first. It holds the decision rules; this file is the reviewer checklist that enforces them.

## Non-negotiables

SyncX runs in the hot path of every frame of a mobile app. Two rules outrank everything else:

1. **More code is not more quality.** The library's value is what it prevents, not what it offers.
2. **Mobile budget is a hard limit, not a goal.** See the performance budget below.

### Never merge a change that

- Adds a timer, `Future.delayed`, `sleep`, or polling to library code — including to fix a race. Order concurrent work with real completion signals (`Completer`, `Future`, the notifier lifecycle). A sleep that hides a race ships the race to users with different timing.
- Adds a cache of state, widgets, or computed values without a benchmark proving the recompute is the bottleneck.
- Retains anything per notifier beyond its listeners, or per builder widget beyond one state reference and one listener.
- Adds a dependency. `provider` is the only one.
- Adds code generation, `build_runner`, reflection, or `dart:mirrors`.
- Adds an abstraction with a single implementation, or a second way to do something the library already does.
- Uses `// ignore:` to silence a lint about SyncX's own API. If consuming our own class needs an ignore, the API is wrong — fix the API.
- Documents a behavior that has no test.
- Bumps only the patch version while introducing a breaking change. Pre-1.0, breaking changes bump the minor version.

### Performance budget

| Budget | Limit |
|---|---|
| Allocations per `setState` | 0 beyond the new state object |
| Allocations per rebuild check | 0 |
| Retained per notifier | O(listeners) |
| Retained per builder widget | 1 state ref + 1 listener |
| Added rebuild work vs raw `ChangeNotifier` | within 10% |
| `lib/` size | under 1500 lines |
| Dependencies | `provider` only |

## Adding a feature

A pull request that adds public API must open with a two-line problem statement: the user situation that is painful today, and why no existing SyncX or `provider` API covers it. "bloc has it" is not a problem statement. Without it the PR is closed.

SyncX will not grow a DI container, a service locator, event classes, middleware, time-travel debugging, state persistence, or anything outside state management. See `PLAN.md` §0.4.

## Fixing a bug

1. Write the failing test first, in the same pull request.
2. Fix the root cause, not the reported symptom. Grep every caller of the function you touch — a guard in the shared function is a smaller diff than a guard in each caller, and it fixes the siblings the report did not mention.
3. Prefer removing the mechanism that caused the bug over guarding it.

## Tests

- `flutter_test` only. No mockito, no mocktail, no `build_runner`. A fake notifier is five lines.
- Mirror the source layout: `lib/src/a/b.dart` is tested by `test/src/a/b_test.dart`. Shared fakes live in `test/helpers/`.
- Assert observable behavior. Never reach into private fields.
- Tests must be deterministic. No `Future.delayed`, no `pumpAndSettle` on real durations — drive async with a `Completer` and `pump()`.
- Widget tests assert **rebuild counts** numerically. "Precise rebuild control" is the product claim; an un-asserted claim is marketing.

## Local checks

Run what CI runs, before pushing:

```sh
flutter pub get
dart format .
flutter analyze --fatal-infos
flutter test --coverage
tool/check_coverage.sh
flutter pub publish --dry-run
```

`COVERAGE_MIN` gates `tool/check_coverage.sh`. The number only ever goes up.

## Releasing

Publishing is automated and runs only from a tag. See `PLAN.md` §1.4 for the one-time pub.dev setup.

1. Land all changes on `master`.
2. Bump `version:` in `pubspec.yaml`.
3. Add a matching `## <version>` section to `CHANGELOG.md`, with a migration snippet for every breaking change.
4. Tag and push: `git tag v<version> && git push origin v<version>`.
5. The `Publish to pub.dev` workflow re-runs every gate, verifies the tag matches `pubspec.yaml` and `CHANGELOG.md`, then publishes.

Never run `flutter pub publish` by hand. The tag is the release record.
