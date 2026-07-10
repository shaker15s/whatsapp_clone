import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html' show File;
import '../../models/message_model.dart';

// ─── Reply Bar Widget (reusable, lives inside ChatInputBar) ─────────────────
class _ReplyBar extends StatelessWidget {
  final String senderName;
  final String textSnippet;
  final VoidCallback onDismiss;

  const _ReplyBar({
    required this.senderName,
    required this.textSnippet,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  textSnippet,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Platform-agnostic file wrapper ─────────────────────────────────────────
/// Wrapper to handle File (mobile/desktop) and XFile/Uint8List (web)
class PickedFileWrapper {
  final XFile xfile;
  final String? path;
  final Uint8List? bytes;

  PickedFileWrapper._({required this.xfile, this.path, this.bytes});

  factory PickedFileWrapper.fromXFile(XFile xfile) {
    return PickedFileWrapper._(xfile: xfile);
  }

  factory PickedFileWrapper.fromFile(dynamic file) {
    // dart:io File (mobile/desktop) has .path; dart:html File (web) does not
    String? path;
    try {
      path = (file as dynamic).path as String?;
    } catch (_) {
      // web fallback – dart:html File lacks .path for security
      final name = (file as dynamic).name as String?;
      return PickedFileWrapper._(xfile: XFile(name ?? ''), path: null);
    }
    return PickedFileWrapper._(xfile: XFile(path ?? ''), path: path);
  }

  factory PickedFileWrapper.fromBytes(Uint8List bytes, String name) {
    return PickedFileWrapper._(xfile: XFile.fromData(bytes, name: name), bytes: bytes);
  }

  bool get isWeb => kIsWeb || bytes != null;
  String get name => xfile.name;
  String get mimeType => xfile.mimeType ?? '';
  
  Future<Uint8List> readAsBytes() async {
    if (bytes != null) return bytes!;
    return await xfile.readAsBytes();
  }
}

// ─── Main Chat Input Bar ─────────────────────────────────────────────────────
class ChatInputBar extends StatefulWidget {
  final void Function(String text) onSendText;
  final void Function(PickedFileWrapper file) onSendImage;
  final void Function(PickedFileWrapper file, int durationSeconds) onSendAudio;
  final void Function(double lat, double lng) onSendLocation;
  final Map<String, dynamic>? replyTo;
  final VoidCallback? onClearReply;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendAudio,
    required this.onSendLocation,
    this.replyTo,
    this.onClearReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  AudioRecorder? _recorder;
  bool _isRecording = false;
  DateTime? _recordStart;

  @override
  void dispose() {
    _textController.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  Future<AudioRecorder> get _audioRecorder async {
    _recorder ??= AudioRecorder();
    return _recorder!;
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _textController.clear();
  }

  Future<void> _pickImage() async {
    try {
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
        widget.onSendImage(PickedFileWrapper.fromXFile(picked));
      }
    } catch (e) {
      _showSnack('فشل اختيار الصورة: $e');
    }
  }

Future<void> _startRecording() async {
    try {
      final recorder = await _audioRecorder;
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        _showSnack('محتاج صلاحية المايكروفون لتسجيل رسالة صوتية');
        return;
      }

      String path;
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        path = '';
      }

      await recorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordStart = DateTime.now();
      });
    } catch (e) {
      _isRecording = false;
      _showSnack('فشل بدء التسجيل: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final recorder = _recorder;
      if (recorder == null) return;
      final path = await recorder.stop();
      setState(() => _isRecording = false);

      if (path != null && _recordStart != null) {
        final duration = DateTime.now().difference(_recordStart!).inSeconds;
        if (duration >= 1) {
      widget.onSendAudio(PickedFileWrapper.fromXFile(XFile(path)), duration);
        } else {
          _showSnack('التسجيل قصير جداً، حاول مرة أخرى');
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showSnack('فشل إيقاف التسجيل: $e');
    }
  }

  Future<void> _shareLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('فعّل خدمات الموقع أولاً');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('محتاج صلاحية الموقع');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('صلاحية الموقع مرفوعة نهائياً — اذهب للإعدادات');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      widget.onSendLocation(position.latitude, position.longitude);
    } catch (e) {
      _showSnack('فشل جلب الموقع: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reply bar (if active)
        if (widget.replyTo != null)
          _ReplyBar(
            senderName: widget.replyTo!['senderName'] ?? '',
            textSnippet: widget.replyTo!['textSnippet'] ?? '',
            onDismiss: widget.onClearReply ?? () {},
          ),
        // Input row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Attach button
                IconButton(
                  icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Wrap(
                        children: [
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
                        ],
                      ),
                    ),
                  ),
                ),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                // Record button (long press)
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? const Color(0xFFFF5252)
                          : Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording ? Colors.white : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Send button
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                  onPressed: _sendText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}