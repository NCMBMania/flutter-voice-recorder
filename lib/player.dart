import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:html' as webFile;
import 'dart:typed_data';
import 'package:ncmb/ncmb.dart';

/// 音声再生用のステートフルウィジェット
/// https://zenn.dev/r0227n/articles/085c234061235e
/// を参考に、利用しない部分を削除しています
class PlayerPage extends StatefulWidget {
  const PlayerPage({Key? key, required this.audioFile}) : super(key: key);
  // 再生対象のファイル
  final NCMBFile audioFile;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _setupSession();
  }

  Future<void> _setupSession() async {
    _player = AudioPlayer();
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await _loadAudioFile();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 再生するファイル名を表示
          Text(widget.audioFile.getString("fileName", defaultValue: "No Name")),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () async => await _playSoundFile(),
          ),
        ],
      ),
    );
  }

  Future<void> _playSoundFile() async {
    // 再生終了状態の場合、新たなオーディオファイルを定義し再生できる状態にする
    if (_player.processingState == ProcessingState.completed) {
      await _loadAudioFile();
    }
    await _player.setSpeed(1.0); // 再生速度
    await _player.play();
  }

  Future<void> _loadAudioFile() async {
    // ファイルストアから実データをダウンロード
    var data = await widget.audioFile.contents();
    // Uint8ListをByteDataに変換
    var blob = ByteData.sublistView(data);
    // さらにByteDataをBlob URIに変換
    var path = webFile.Url.createObjectUrlFromBlob(webFile.Blob([blob]));
    // Blob URIを再生
    await _player.setUrl(path);
  }
}
