import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../backend_client.dart';

/// Keeps `/sync/stream` open and calls [onSignal] whenever the group has news.
///
/// The server sends a sequence number, never data (see .llmwiki/Sync.md), so a
/// missed message costs nothing: the next pull starts from the local cursor. That
/// is also why reconnecting needs no bookkeeping — only a fresh single-use ticket
/// and an exponential backoff capped at 60 s.
class SyncStream {
  SyncStream(this._client, this._deviceToken, this.onSignal);

  final BackendClient _client;
  final String _deviceToken;
  final void Function() onSignal;

  WebSocketChannel? _channel;
  Timer? _retry;
  int _attempt = 0;
  bool _stopped = false;

  void start() {
    _stopped = false;
    _connect();
  }

  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> _connect() async {
    if (_stopped) return;
    try {
      final uri = await _client.streamUri(_deviceToken);
      if (_stopped) return;
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;
      _attempt = 0;
      // Whatever happened while disconnected.
      onSignal();
      channel.stream.listen(
        (message) {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          if (data['type'] == 'new_seq') onSignal();
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _channel = null;
    if (_stopped) return;
    final seconds = math.min(60, 1 << math.min(_attempt, 6));
    _attempt++;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: seconds), _connect);
  }
}
