import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Your PC's IP. (Android emulator would use http://10.0.2.2:3000)
const serverUrl = 'http://192.168.1.10:3000';

void main() => runApp(const MaterialApp(home: JoinPage()));

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});
  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _room = TextEditingController(text: 'test123');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(
            controller: _room,
            decoration: const InputDecoration(labelText: 'Room name'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await [Permission.camera, Permission.microphone].request();
              if (!mounted) return;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CallPage(room: _room.text.trim()),
              ));
            },
            child: const Text('Join'),
          ),
        ]),
      ),
    );
  }
}

class CallPage extends StatefulWidget {
  final String room;
  const CallPage({super.key, required this.room});
  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remotes = {};
  final Map<String, RTCPeerConnection> _pcs = {};
  final Map<String, Future<void>> _chain = {};
  MediaStream? _localStream;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _localRenderer.initialize();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    _localRenderer.srcObject = _localStream;
    setState(() {});

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket.onConnect((_) => _socket.emit('join', widget.room));

    // I just joined: call everyone already in the room
    _socket.on('existing-peers', (peers) async {
      for (final id in List<String>.from(peers)) {
        final pc = await _createPc(id);
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        _send(id, {'type': 'offer', 'sdp': offer.sdp});
      }
    });

    _socket.on('signal', (msg) {
      final from = msg['from'] as String;
      final data = Map<String, dynamic>.from(msg['data']);
      // handle messages from each peer one at a time, in order
      _chain[from] = (_chain[from] ?? Future.value()).then((_) => _handle(from, data));
    });

    _socket.on('peer-left', (id) => _removePeer(id as String));

    _socket.connect();
  }

  void _send(String to, Map<String, dynamic> data) {
    _socket.emit('signal', {'to': to, 'data': data});
  }

  Future<void> _handle(String from, Map<String, dynamic> d) async {
    final pc = _pcs[from] ?? await _createPc(from);
    switch (d['type']) {
      case 'offer':
        await pc.setRemoteDescription(RTCSessionDescription(d['sdp'], 'offer'));
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        _send(from, {'type': 'answer', 'sdp': answer.sdp});
        break;
      case 'answer':
        await pc.setRemoteDescription(RTCSessionDescription(d['sdp'], 'answer'));
        break;
      case 'candidate':
        final c = d['candidate'];
        await pc.addCandidate(
            RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
        break;
    }
  }

  Future<RTCPeerConnection> _createPc(String id) async {
    final pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ],
    });
    _pcs[id] = pc;

    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onIceCandidate = (c) {
      if (c.candidate != null) {
        _send(id, {'type': 'candidate', 'candidate': c.toMap()});
      }
    };

    pc.onTrack = (event) async {
      if (event.streams.isEmpty) return;
      var r = _remotes[id];
      if (r == null) {
        r = RTCVideoRenderer();
        await r.initialize();
        _remotes[id] = r;
      }
      r.srcObject = event.streams[0];
      if (mounted) setState(() {});
    };
    return pc;
  }

  void _removePeer(String id) {
    _pcs.remove(id)?.close();
    _remotes.remove(id)?.dispose();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _socket.dispose();
    for (final pc in _pcs.values) {
      pc.close();
    }
    for (final r in _remotes.values) {
      r.dispose();
    }
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remotes = _remotes.values.toList();
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.room}')),
      body: Stack(children: [
        Positioned.fill(
          child: remotes.isEmpty
              ? const Center(child: Text('Waiting for others to join...'))
              : GridView.count(
                  crossAxisCount: remotes.length == 1 ? 1 : 2,
                  children: [
                    for (final r in remotes)
                      RTCVideoView(r,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ],
                ),
        ),
        Positioned(
          right: 12,
          bottom: 90,
          width: 110,
          height: 150,
          child: RTCVideoView(_localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Center(
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.call_end),
            ),
          ),
        ),
      ]),
    );
  }
}