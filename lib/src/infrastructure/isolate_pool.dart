import 'dart:isolate';
import 'package:github_analyzer/src/common/logger.dart';

class IsolatePool {
  final int size;
  final AnalyzerLogger logger;
  final List<_IsolateWorker> _workers = [];
  int _currentWorkerIndex = 0;
  bool _isInitialized = false;

  IsolatePool({required this.size, required this.logger});

  Future<void> initialize() async {
    if (_isInitialized) return;

    logger.info('Initializing isolate pool with $size workers');

    for (int i = 0; i < size; i++) {
      final worker = _IsolateWorker(id: i, logger: logger);
      await worker.spawn();
      _workers.add(worker);
    }

    _isInitialized = true;
    logger.info('Isolate pool initialized');
  }

  Future<R> execute<T, R>(Future<R> Function(T) task, T argument) async {
    if (!_isInitialized) {
      throw StateError('IsolatePool not initialized. Call initialize() first.');
    }

    final worker = _workers[_currentWorkerIndex];
    _currentWorkerIndex = (_currentWorkerIndex + 1) % _workers.length;

    return await worker.execute(task, argument);
  }

  Future<List<R>> executeAll<T, R>(
    Future<R> Function(T) task,
    List<T> arguments,
  ) async {
    if (!_isInitialized) {
      throw StateError('IsolatePool not initialized. Call initialize() first.');
    }

    final futures = <Future<R>>[];

    for (int i = 0; i < arguments.length; i++) {
      final worker = _workers[i % _workers.length];
      futures.add(worker.execute(task, arguments[i]));
    }

    return await Future.wait(futures);
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;

    logger.info('Disposing isolate pool');

    for (final worker in _workers) {
      await worker.kill();
    }

    _workers.clear();
    _isInitialized = false;
    logger.info('Isolate pool disposed');
  }
}

class _IsolateWorker {
  final int id;
  final AnalyzerLogger logger;
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  _IsolateWorker({required this.id, required this.logger});

  Future<void> spawn() async {
    logger.debug('Spawning isolate worker $id');

    _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort.sendPort);

    _sendPort = await _receivePort.first as SendPort;
    logger.debug('Isolate worker $id spawned');
  }

  Future<R> execute<T, R>(Future<R> Function(T) task, T argument) async {
    if (_sendPort == null) {
      throw StateError('Isolate not spawned');
    }

    final responsePort = ReceivePort();
    _sendPort!.send([task, argument, responsePort.sendPort]);

    final result = await responsePort.first;
    responsePort.close();

    if (result is _IsolateError) {
      throw Exception('Isolate error: ${result.message}\n${result.stackTrace}');
    }

    return result as R;
  }

  Future<void> kill() async {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
    logger.debug('Isolate worker $id killed');
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final task = message[0] as Future<dynamic> Function(dynamic);
      final argument = message[1];
      final responsePort = message[2] as SendPort;

      try {
        final result = await task(argument);
        responsePort.send(result);
      } catch (e, stackTrace) {
        responsePort.send(
          _IsolateError(
            message: e.toString(),
            stackTrace: stackTrace.toString(),
          ),
        );
      }
    });
  }
}

class _IsolateError {
  final String message;
  final String stackTrace;

  _IsolateError({required this.message, required this.stackTrace});
}
