import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/message_model.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String text) onSendText;
  final void Function(File file) onSendImage;
  final void Function(File file, int durationSeconds) onSendAudio;
  final void Function(double lat, double lng) onSendLocation;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendAudio,
    required this.onSendLocation,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  DateTime? _recordStart;

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _textController.clear();
  }

  Future<void> _pickImage() async {
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('كاميرا'),
              onTap: () async {
                final f = await _picker.pickImage(source: ImageSource.camera);
                if (mounted) Navigator.pop(context, f);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () async {
                final f = await _picker.pickImage(source: ImageSource.gallery);
                if (mounted) Navigator.pop(context, f);
              },
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      widget.onSendImage(File(picked.path));
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _isRecording = true;
      _recordStart = DateTime.now();
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path != null && _recordStart != null) {
      final duration = DateTime.now().difference(_recordStart!).inSeconds;
      if (duration >= 1) {
        widget.onSendAudio(File(path), duration);
      }
    }
  }

  Future<void> _shareLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    widget.onSendLocation(position.latitude, position.longitude);
  }

  @override
  void dispose() {
    _textController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Wrap(children: [
                    ListTile(
                      leading: const Icon(Icons.image),
                      title: const Text('صورة'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('موقعي'),
                      onTap: () {
                        Navigator.pop(context);
                        _shareLocation();
                      },
                    ),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
              ),
            ),
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: CircleAvatar(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                child: Icon(_isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendText,
            ),
          ],
        ),
      ),
    );
  }
}
