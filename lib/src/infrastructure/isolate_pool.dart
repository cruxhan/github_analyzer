import 'dart:isolate';
import 'package:github_analyzer/src/common/logger.dart';

class IsolatePool {
  final int size;
  final List<_IsolateWorker> _workers = [];
  int _currentWorkerIndex = 0;
  bool _isInitialized = false;

  IsolatePool({required this.size});

  Future<void> initialize() async {
    if (_isInitialized) return;

    logger.info('Initializing isolate pool with $size workers');
    for (int i = 0; i < size; i++) {
      final worker = _IsolateWorker(id: i);
      await worker.spawn();
      _workers.add(worker);
    }

    _isInitialized = true;
    logger.info('Isolate pool initialized');
  }

  Future<R> execute<T, R>(Future<R> Function(T) task, T argument) async {
    _checkInitialized();

    final worker = _workers[_currentWorkerIndex];
    _currentWorkerIndex = (_currentWorkerIndex + 1) % _workers.length;
    return await worker.execute<T, R>(task, argument);
  }

  Future<List<R>> executeAll<T, R>(
    Future<R> Function(T) task,
    List<T> arguments,
  ) async {
    _checkInitialized();

    final futures = <Future<R>>[];
    for (int i = 0; i < arguments.length; i++) {
      final worker = _workers[i % _workers.length];
      futures.add(worker.execute<T, R>(task, arguments[i]));
    }

    return await Future.wait<R>(futures);
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

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('IsolatePool not initialized. Call initialize() first.');
    }
  }
}

class _IsolateWorker {
  final int id;
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  _IsolateWorker({required this.id});

  Future<void> spawn() async {
    logger.fine('Spawning isolate worker $id');
    _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort.sendPort);

    final firstMessage = await _receivePort.first;
    _validateHandshake(firstMessage);
    _sendPort = firstMessage as SendPort;

    logger.fine('Isolate worker $id spawned');
  }

  Future<R> execute<T, R>(Future<R> Function(T) task, T argument) async {
    if (_sendPort == null) {
      throw StateError('Isolate not spawned');
    }

    final responsePort = ReceivePort();

    try {
      _sendPort!.send([task, argument, responsePort.sendPort]);
    } catch (e) {
      responsePort.close();
      throw IsolateSpawnException(
        'Cannot send function to isolate. '
        'The function must be a top-level or static function, '
        'not a closure or instance method. Error: $e',
      );
    }

    final result = await responsePort.first;
    responsePort.close();

    return _handleResult<R>(result);
  }

  R _handleResult<R>(dynamic result) {
    if (result is _IsolateError) {
      throw Exception('Isolate error: ${result.message}\n${result.stackTrace}');
    }

    if (result is! R) {
      if (result == null && null is R) {
        return result as R;
      }
      throw TypeError();
    }

    return result;
  }

  Future<void> kill() async {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
    logger.fine('Isolate worker $id killed');
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((dynamic message) async {
      if (!_validateMessage(message)) return;

      final taskDynamic = message[0];
      final argument = message[1];
      final responsePort = message[2] as SendPort;

      try {
        final task = taskDynamic as Future<dynamic> Function(dynamic);
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

  void _validateHandshake(dynamic message) {
    if (message is! SendPort) {
      throw StateError(
        'Expected SendPort from isolate, got ${message.runtimeType}',
      );
    }
  }

  static bool _validateMessage(dynamic message) {
    if (!_isValidMessageFormat(message)) {
      logger.severe('Invalid message format in isolate');
      return false;
    }

    if (!_isValidResponsePort(message)) {
      logger.severe('Response port is not a SendPort');
      return false;
    }

    return true;
  }

  static bool _isValidMessageFormat(dynamic message) {
    return message is List && message.length == 3;
  }

  static bool _isValidResponsePort(dynamic message) {
    return message is List && message.length > 2 && message[2] is SendPort;
  }
}

class _IsolateError {
  final String message;
  final String stackTrace;

  _IsolateError({required this.message, required this.stackTrace});

  @override
  String toString() => 'IsolateError: $message\n$stackTrace';
}

class IsolateSpawnException implements Exception {
  final String message;

  IsolateSpawnException(this.message);

  @override
  String toString() => 'IsolateSpawnException: $message';
}
