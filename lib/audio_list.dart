import 'package:flutter/material.dart';
import 'package:ncmb/ncmb.dart';

class AudioListPage extends StatefulWidget {
  const AudioListPage({super.key, required this.file, required this.onTap});
  final NCMBFile file;
  final Function onTap;
  @override
  State<AudioListPage> createState() => _AudioListState();
}

class _AudioListState extends State<AudioListPage> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.file.getString("fileName")),
      onTap: () => widget.onTap(widget.file),
    );
  }
}
