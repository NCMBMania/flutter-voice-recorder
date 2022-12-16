import 'package:flutter/material.dart';
import 'package:ncmb/ncmb.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'recording.dart';
import 'player.dart';
import 'audio_list.dart';

void main() {
  // NCMBの初期化
  NCMB('9170ffcb91da1bbe0eff808a967e12ce081ae9e3262ad3e5c3cac0d9e54ad941',
      '9e5014cd2d76a73b4596deffdc6ec4028cfc1373529325f8e71b7a6ed553157d');
  runApp(const MyApp());
}

class MyAppPage extends StatefulWidget {
  const MyAppPage({super.key});
  @override
  State<MyAppPage> createState() => _MyAppState();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'オーディオレコーダー',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyAppPage(),
    );
  }
}

class _MyAppState extends State<MyAppPage> {
  // 再生対象のファイル
  NCMBFile? _file;
  // ファイルストアにある既存録音データの一覧
  List<NCMBFile> _files = [];

  @override
  void initState() {
    // NCMBのファイルストアからファイルを取得
    _loadFiles();
    super.initState();
  }

  // NCMBのファイルストアからファイルを取得する処理
  Future<void> _loadFiles() async {
    // ファイル検索用クエリー
    var query = NCMBFile.query();
    // 検索条件（ファイル名がrecord_で始まるもの）
    query.regex("fileName", "record_.*");
    // 検索実行して、NCMBFileのリストに変換
    final files = (await query.fetchAll()).map((f) => f as NCMBFile).toList();
    // ステートに適用
    setState(() {
      _files = files;
    });
  }

  // 録音終了時の処理
  void _onStop(String? path) async {
    // 録音ファイルがない場合は何もしない
    if (path == null) return;
    // ファイルをアップロードして、NCMBFileを取得
    var file = await _upload(path);
    // ステートに適用
    setState(() {
      _files.add(file);
    });
  }

  // ファイルをアップロードする処理
  Future<NCMBFile> _upload(String path) async {
    // blob:http://からバイト文字列を取得する
    final res = await http.get(
      Uri.parse(path),
    );
    var bytes = res.bodyBytes;
    // ファイル名作成
    var ts = DateTime.now().millisecondsSinceEpoch;
    // 拡張子を取得
    final mime = lookupMimeType('', headerBytes: bytes);
    final regExp = RegExp(r'^audio\/(.*)($|;)');
    final ext = regExp.firstMatch(mime!)?.group(1);
    var fileName = "record_$ts.$ext";
    // ファイルアップロード
    return await NCMBFile.upload(fileName, bytes);
  }

  // 再生するファイルを選択した際の処理
  void _onTap(NCMBFile file) async {
    // ステートに適用
    setState(() {
      _file = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("レコーディング"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 録音用ステート（録音が終了すると、_onStopを呼び出す）
          RecordingPage(onStop: _onStop),
          // 既存の録音データを一覧表示する（録音データが選択されると _onTap を呼び出す）
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) =>
                  AudioListPage(file: _files[index], onTap: _onTap),
              itemCount: _files.length,
            ),
          ),
          // ファイルが選択されたら、音声再生用ステートを表示する
          _file != null
              ? PlayerPage(audioFile: _file!)
              : const Text("音声ファイルを選択してください")
        ],
      ),
    );
  }
}
