import 'dart:isolate';
import 'package:github_analyzer/src/common/logger.dart';

/// Manages a pool of isolates to perform tasks in parallel.
class IsolatePool {
  final int size;
  final List<_IsolateWorker> _workers = [];
  int _currentWorkerIndex = 0;
  bool _isInitialized = false;

  /// Creates an instance of [IsolatePool].
  IsolatePool({required this.size});

  /// Initializes the isolate pool by spawning the configured number of workers.
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

  /// Executes a task on the next available isolate in the pool.
  ///
  /// **Important**: The [task] function must be a top-level or static function,
  /// not a closure or instance method, because it will be sent to another isolate.
  Future<R> execute<T, R>(Future<R> Function(T) task, T argument) async {
    if (!_isInitialized) {
      throw StateError('IsolatePool not initialized. Call initialize() first.');
    }

    final worker = _workers[_currentWorkerIndex];
    _currentWorkerIndex = (_currentWorkerIndex + 1) % _workers.length;
    return await worker.execute<T, R>(task, argument);
  }

  /// Executes a list of tasks distributed across the isolate pool.
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
      futures.add(worker.execute<T, R>(task, arguments[i]));
    }

    return await Future.wait<R>(futures);
  }

  /// Disposes the isolate pool by terminating all worker isolates.
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

/// Internal worker class that manages a single isolate.
class _IsolateWorker {
  final int id;
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  _IsolateWorker({required this.id});

  /// Spawns a new isolate for this worker.
  Future<void> spawn() async {
    logger.fine('Spawning isolate worker $id');
    _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort.sendPort);

    final firstMessage = await _receivePort.first;
    if (firstMessage is! SendPort) {
      throw StateError(
        'Expected SendPort from isolate, got ${firstMessage.runtimeType}',
      );
    }
    _sendPort = firstMessage;

    logger.fine('Isolate worker $id spawned');
  }

  /// Executes a task on this worker's isolate.
  ///
  /// **CRITICAL**: This attempts to send a function to another isolate.
  /// Dart isolates cannot share functions directly - they must be
  /// top-level or static functions. This will throw a runtime error
  /// if the function is a closure or instance method.
  ///
  /// This is a known limitation and why parallel processing is disabled
  /// by default in the analyzer.
  Future<R> execute<T, R>(Future<R> Function(T) task, T argument) async {
    if (_sendPort == null) {
      throw StateError('Isolate not spawned');
    }

    final responsePort = ReceivePort();

    try {
      // ⚠️ This will fail if task is not a top-level/static function
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

    if (result is _IsolateError) {
      throw Exception('Isolate error: ${result.message}\n${result.stackTrace}');
    }

    if (result is! R) {
      // Allow null for nullable types
      if (result == null && null is R) {
        return result as R;
      }
      throw TypeError();
    }

    return result;
  }

  /// Terminates this worker's isolate.
  Future<void> kill() async {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
    logger.fine('Isolate worker $id killed');
  }

  /// Entry point for spawned isolates.
  ///
  /// This function runs in the spawned isolate and listens for tasks.
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((dynamic message) async {
      // Validate message format
      if (message is! List || message.length != 3) {
        logger.severe('Invalid message format received in isolate');
        return;
      }

      // Extract components without type casting the function yet
      final taskDynamic = message[0];
      final argument = message[1];
      final responsePort = message[2];

      if (responsePort is! SendPort) {
        logger.severe('Response port is not a SendPort');
        return;
      }

      try {
        // Attempt to cast and execute the function
        // This will fail at runtime if the function wasn't serializable
        final task = taskDynamic as Future<dynamic> Function(dynamic);
        final result = await task(argument);
        responsePort.send(result);
      } catch (e, stackTrace) {
        // Send error back to main isolate
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

/// Represents an error that occurred in an isolate.
class _IsolateError {
  final String message;
  final String stackTrace;

  _IsolateError({required this.message, required this.stackTrace});

  @override
  String toString() => 'IsolateError: $message\n$stackTrace';
}

/// Exception thrown when isolate spawn fails.
class IsolateSpawnException implements Exception {
  final String message;

  IsolateSpawnException(this.message);

  @override
  String toString() => 'IsolateSpawnException: $message';
}
