import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_constants.dart';
import '../data/app_storage.dart';

class JobSocketEvent {
  final String type; // 'job:created' | 'job:claimed' | 'job:cancelled' | 'job:status' | 'connection'
  final Map<String, dynamic> payload;

  const JobSocketEvent(this.type, this.payload);
}

class JobSocketService {
  JobSocketService._internal();
  static final JobSocketService instance = JobSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  final Set<String> _joinedJobRooms = {};

  final StreamController<JobSocketEvent> _eventController =
      StreamController<JobSocketEvent>.broadcast();
  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);

  Stream<JobSocketEvent> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  String get _socketNamespaceUrl {
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return '$base/jobs';
  }

  Future<void> connect() async {
    if (_socket != null && (_socket!.connected || _socket!.active)) {
      return;
    }

    final token = await AppStorage.getToken();
    if (token == null || token.isEmpty) return;

    _socket?.dispose();

    final socket = io.io(
      _socketNamespaceUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    socket.onConnect((_) {
      _isConnected = true;
      connectionNotifier.value = true;
      debugPrint('>>> [SOCKET /jobs] Connected: ${socket.id}');
      for (final jobId in _joinedJobRooms) {
        socket.emit('joinJob', jobId);
      }
      _eventController.add(const JobSocketEvent('connection', {'connected': true}));
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      connectionNotifier.value = false;
      debugPrint('<<< [SOCKET /jobs] Disconnected');
      _eventController.add(const JobSocketEvent('connection', {'connected': false}));
    });

    socket.onConnectError((err) {
      _isConnected = false;
      connectionNotifier.value = false;
      debugPrint('<<< [SOCKET /jobs] Connect error: $err');
    });

    for (final eventName in ['job:created', 'job:claimed', 'job:cancelled', 'job:status']) {
      socket.on(eventName, (data) {
        final Map<String, dynamic> map = data is Map
            ? Map<String, dynamic>.from(data)
            : {'raw': data};
        debugPrint('>>> [SOCKET /jobs] Event $eventName: $map');
        _eventController.add(JobSocketEvent(eventName, map));
      });
    }

    _socket = socket;
  }

  void joinJobRoom(dynamic jobId) {
    if (jobId == null) return;
    final key = jobId.toString();
    _joinedJobRooms.add(key);
    if (_socket != null && _socket!.connected) {
      _socket!.emit('joinJob', key);
    }
  }

  void leaveJobRoom(dynamic jobId) {
    if (jobId == null) return;
    final key = jobId.toString();
    _joinedJobRooms.remove(key);
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leaveJob', key);
    }
  }

  void disconnect() {
    _joinedJobRooms.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    connectionNotifier.value = false;
  }
}
