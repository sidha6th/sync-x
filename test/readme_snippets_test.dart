// ignore_for_file: unnecessary_lambdas
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncx/syncx.dart';

class CounterNotifier extends Notifier<int> {
  CounterNotifier() : super(0);

  void increment() => setState(state + 1);

  Future<void> incrementLater() async {
    await Future<void>.delayed(Duration.zero);
    increment();
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: NotifierBuilder<CounterNotifier, int>(
          builder: (count, child) => Text('$count'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CounterNotifier>().increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GreetingApi {
  Future<String> fetch() async => 'hello';
}

class GreetingNotifier extends AsyncNotifier<String> {
  GreetingNotifier(this.api);

  final GreetingApi api;

  @override
  Future<AsyncState<String>> onInit() async {
    return AsyncState.data(await api.fetch());
  }

  Future<void> refresh() async {
    setLoading();
    try {
      setData(await api.fetch());
    } catch (error, stackTrace) {
      setError(error, message: 'Could not load', stackTrace: stackTrace);
    }
  }
}

class LifecycleCounter extends Notifier<int> {
  LifecycleCounter() : super(0);

  @override
  void onInit() {}

  @override
  void onUpdate(int state) {}
}

class User {}

class UserRepository {
  void load() {}
}

class WrongUserNotifier extends Notifier<User?> {
  WrongUserNotifier() : super(null) {
    repository = UserRepository();
  }

  UserRepository? repository;

  @override
  void onInit() => repository!.load();
}

class RightUserNotifier extends Notifier<User?> {
  RightUserNotifier(this.repository) : super(null);

  final UserRepository repository;

  @override
  void onInit() => repository.load();
}

class MyForm extends StatelessWidget {
  const MyForm({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class Snippets extends StatelessWidget {
  const Snippets({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        NotifierBuilder<CounterNotifier, int>(
          buildWhen: (previous, current) => current.isEven,
          builder: (count, child) => Text('$count'),
        ),
        NotifierListener<CounterNotifier, int>(
          listenWhen: (previous, current) => current > 10,
          listener: (count) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Past ten: $count')),
          ),
          child: const MyForm(),
        ),
        AsyncNotifierBuilder<GreetingNotifier, String>.withData(
          loadingBuilder: (child) => const CircularProgressIndicator(),
          dataBuilder: (greeting, child) => Text(greeting),
          errorBuilder: (error, child) =>
              Text(error.message ?? '${error.error}'),
        ),
        AsyncNotifierBuilder<GreetingNotifier, String>(
          builder: (state, child) => state.when(
            loading: () => const CircularProgressIndicator(),
            data: (greeting) => Text(greeting),
            error: (error) => Text(error.message ?? '${error.error}'),
          ),
        ),
        AsyncNotifierBuilder<GreetingNotifier, String>(
          builder: (state, child) => state.when(
            loading: () => Text(state.data ?? 'Loading...'),
            data: (greeting) => Text(greeting),
            error: (error) => Text(state.data ?? 'Failed'),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => NotifierRegister.value(
                notifier: context.read<CounterNotifier>(),
                child: const DetailPage(),
              ),
            ),
          ),
          child: const Text('go'),
        ),
        NotifierBuilder<CounterNotifier, int>(
          onInit: (notifier) => notifier.incrementLater(),
          builder: (count, child) => Text('$count'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('the README counter runs as written', (tester) async {
    await tester.pumpWidget(
      NotifierRegister(
        create: (context) => CounterNotifier(),
        child: const MaterialApp(home: CounterPage()),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('the README snippets build', (tester) async {
    await tester.pumpWidget(
      NotifierRegister(
        create: (context) => CounterNotifier(),
        child: NotifierRegister(
          create: (context) => GreetingNotifier(GreetingApi()),
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: Snippets())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
