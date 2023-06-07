import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:testing_flutter_hooks/custom_hook.dart';

// remove null elements essentially or else it just the same as Map
extension CompactMap<T> on Iterable<T?> {
  Iterable<T> compactMap<E>([E? Function(T?)? transform]) =>
      map(transform ?? (e) => e).where((e) => e != null).cast();
}

void testIt() {
  final values = [1, 2, null, 3];
  final nonNull = values.compactMap((e) {
    if (e != null && e > 10) {
      return e;
    } else {
      return null;
    }
  });
}

void main(List<String> args) {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage6(),
    ),
  );
}

// Example of use Stream
Stream<String> getTime() => Stream.periodic(
    const Duration(seconds: 1), (_) => DateTime.now().toIso8601String());

class HomePage extends HookWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateTime = useStream(getTime());
    return Scaffold(
      appBar: AppBar(
        title: Text(dateTime.data ?? 'Home Page'),
      ),
    );
  }
}

// Example of useTextEdittingController, useEffect, useState
class HomePage1 extends HookWidget {
  const HomePage1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // creating a controller
    final controller = useTextEditingController();
    // whenever there is a change in the controller, we want to update the text
    // useState: allow everyone that listens to this text will be notified
    final text = useState('');
    //useEffect: executing side Effects
    // This will be recalled whenever we do a hot reload
    useEffect(() {
      // We added a listener to the controller that updates the text
      //whenever the controller value changes
      controller.addListener(() {
        text.value = controller.text;
      });
      return null;
    }, [controller]);
    // This stops useEffect to recalled whenever the app is hot reload,
    //instead it will look at its dependency list and only be called if
    //the elements in its depency list changes

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(children: [
        TextField(
          controller: controller,
        ),
        Text('You typed ${text.value}')
      ]),
    );
  }
}

// useMemoized and useFuture
const url = 'https://bit.ly/3qYOtDm';

class HomePage2 extends HookWidget {
  const HomePage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // NOTE: useFuture does not hold on to any State. It just creates the future and let you consume it.

    //useMemoized: creates a caching mechanism for complex objects.
    // Here we cache the Future Object
    final image = useMemoized((() => (NetworkAssetBundle(Uri.parse(url))
        .load(url)
        .then((data) => data.buffer.asUint8List())
        .then((data) => Image.memory(data)))));
    // Here we consume the Future with useFuture
    final snapshot = useFuture(image);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: Column(children: [snapshot.data].compactMap().toList()));
  }

  //useListenable: consumes a listenable and calls the build function whenever the listenable changes
  // It need to be cached so use useMemoized()
}

class CountDown extends ValueNotifier<int> {
  CountDown({required int from}) : super(from) {
    sub = Stream.periodic(const Duration(seconds: 1), (v) => from - v)
        .takeWhile((value) => (value > 0))
        .listen((value) {
      this.value = value;
    });
  }

  late StreamSubscription sub;
  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}

class HomePage3 extends HookWidget {
  const HomePage3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final countDown = useMemoized(() => CountDown(from: 20));
    final notifier = useListenable(countDown);
    return Scaffold(
      appBar: AppBar(
        title: Text(notifier.value.toString()),
      ),
    );
  }
}

//useAnimationController and useScrollController
const url1 = 'https://bit.ly/3x7J5Qt';
const imageHeight =
    300.0; // normalization: Take a value between X and Y and decrease it to between the range 0 to 1

extension Normalize on num {
  num normalized(num selfRangeMin, num selfRangeMax,
          [num normalizedRangeMin = 0.0, num normalizedRangeMax = 1.0]) =>
      (normalizedRangeMax - normalizedRangeMin) *
          ((this - selfRangeMin) / (selfRangeMax - selfRangeMin)) +
      normalizedRangeMin;
}

class HomePage4 extends HookWidget {
  const HomePage4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final opacity = useAnimationController(
      duration: const Duration(seconds: 1),
      initialValue: 1,
      upperBound: 1,
      lowerBound: 0,
    );
    final size = useAnimationController(
      duration: const Duration(seconds: 1),
      initialValue: 1,
      upperBound: 1,
      lowerBound: 0,
    );

    final controller = useScrollController();
    useEffect(() {
      controller.addListener(() {
        final newOpacity = max(imageHeight - controller.offset, 0.0);
        final normalized = newOpacity.normalized(0.0, imageHeight).toDouble();
        opacity.value = normalized;
        size.value = normalized;
      });
      return null;
    }, [controller]);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hope this looks nice'),
      ),
      body: Column(children: [
        SizeTransition(
          sizeFactor: size,
          axis: Axis.vertical,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: opacity,
            child: Image.network(
              url,
              height: imageHeight,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Expanded(
            child: ListView.builder(
          controller: controller,
          itemCount: 100,
          itemBuilder: (context, index) =>
              ListTile(title: Text('Person ${index + 1}')),
        ))
      ]),
    );
  }
}

//useStreamController
class HomePage5 extends HookWidget {
  const HomePage5({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final StreamController<double> controller;
    controller = useStreamController<double>(onListen: () {
      controller.sink.add(0.0);
    });
    return Scaffold(
        appBar: AppBar(
          title: Text("UseStreamController Example"),
        ),
        body: StreamBuilder<double>(
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            } else {
              final rotation = snapshot.data ?? 0.0;
              return GestureDetector(
                  onTap: () {
                    controller.sink.add(rotation + 10.0);
                  },
                  child: RotationTransition(
                      turns: AlwaysStoppedAnimation(rotation / 360),
                      child: Center(child: Image.network(url))));
            }
          },
        ));
  }
}

// useReducer:  NewState = OldState + Action
enum Action { rotateRight, rotateLeft, moreVisible, lessVisible }

@immutable
class State {
  final double rotationDeg;
  final double alpha;
  const State({required this.rotationDeg, required this.alpha});
  const State.zero()
      : rotationDeg = 0.0,
        alpha = 1.0;
  State rotateRight() => State(rotationDeg: rotationDeg + 10.0, alpha: alpha);
  State rotateLeft() => State(rotationDeg: rotationDeg - 10.0, alpha: alpha);

  State increaseAlpha() =>
      State(rotationDeg: rotationDeg, alpha: min(alpha + 0.1, 1.0));
  State decreaseAlpha() =>
      State(rotationDeg: rotationDeg, alpha: max(alpha - 0.1, 0.0));
}

State reducer(State oldState, Action? action) {
  switch (action) {
    case Action.rotateLeft:
      return oldState.rotateLeft();
    case Action.rotateRight:
      return oldState.rotateRight();
    case Action.lessVisible:
      return oldState.decreaseAlpha();
    case Action.moreVisible:
      return oldState.increaseAlpha();
    case null:
      return oldState;
  }
}

class HomePage6 extends HookWidget {
  const HomePage6({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = useReducer<State, Action?>(reducer,
        initialState: const State.zero(), initialAction: null);
    return Scaffold(
        appBar: AppBar(
          title: const Text("Home Page"),
        ),
        body: Column(
          children: [
            Row(children: [
              for (final i in Action.values)
                TextButton(
                    onPressed: () {
                      store.dispatch(i);
                    },
                    child: Text(i.toString()))
            ]),
            const SizedBox(height: 100),
            Opacity(
                opacity: store.state.alpha,
                child: RotationTransition(
                    turns:
                        AlwaysStoppedAnimation(store.state.rotationDeg / 360),
                    child: Image.network(url1))),
          ],
        ));
  }
}

class HomePage7 extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // useAppLifecycleState: the build function will be called again when the state
    final state =
        useAppLifecycleState(); // For example when the app go out of focus or stuff like that
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      body: Opacity(
        opacity: state == AppLifecycleState.resumed ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withAlpha(100),
              spreadRadius: 10,
            ),
          ]),
        ),
      ),
    );
  }
}

class HomePage8 extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final number = useInfiniteTimer(context);
    return Center(child: Text(number.toString()));
  }
}
