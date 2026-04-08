import 'dart:async';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shirne_dialog/shirne_dialog.dart';
import 'package:universal_html/html.dart' as html;

import '../global.dart';
import '../models/play_mode.dart';
import '../models/game_manager.dart';
import '../components/play.dart';
import '../components/game_bottom_bar.dart';
import '../components/edit_fen.dart';
import '../widgets/game_wrapper.dart';

/// Game board screen — receives a [PlayMode] from the router and immediately
/// shows the game. Home screen handles mode selection.
class BoardScreen extends StatefulWidget {
  final PlayMode mode;

  const BoardScreen({super.key, required this.mode});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final GameManager gamer = GameManager.instance;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) => gamer.init());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              tooltip: context.l10n.openMenu,
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: context.l10n.flipBoard,
            onPressed: () => gamer.flip(),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: context.l10n.copyCode,
            onPressed: copyFen,
          ),
          IconButton(
            icon: const Icon(Icons.airplay),
            tooltip: context.l10n.parseCode,
            onPressed: applyFen,
          ),
          IconButton(
            icon: const Icon(Icons.airplay),
            tooltip: context.l10n.editCode,
            onPressed: editFen,
          ),
        ],
      ),
      drawer: Drawer(
        semanticLabel: context.l10n.menu,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                    Text(
                      context.l10n.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(context.l10n.newGame),
              onTap: () {
                Navigator.pop(context);
                gamer.newGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(context.l10n.loadManual),
              onTap: () {
                Navigator.pop(context);
                loadFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: Text(context.l10n.saveManual),
              onTap: () {
                Navigator.pop(context);
                saveManual();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.copyCode),
              onTap: () {
                Navigator.pop(context);
                copyFen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(context.l10n.setting),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(child: PlayPage(mode: widget.mode)),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width >= 980
          ? null
          : GameBottomBar(widget.mode),
    );
  }

  void editFen() async {
    final fenStr = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return GameWrapper(child: EditFen(fen: gamer.fenStr));
        },
      ),
    );
    if (fenStr != null && fenStr.isNotEmpty) {
      gamer.newGame(fen: fenStr);
    }
  }

  Future<void> applyFen() async {
    final l10n = context.l10n;
    ClipboardData? cData = await Clipboard.getData(Clipboard.kTextPlain);
    String fenStr = cData?.text ?? '';
    final filenameController = TextEditingController(text: fenStr);
    filenameController.addListener(() {
      fenStr = filenameController.text;
    });

    final confirmed = await MyDialog.confirm(
      TextField(controller: filenameController),
      buttonText: l10n.apply,
      title: l10n.situationCode,
    );
    if (confirmed ?? false) {
      if (RegExp(
        r'^[abcnrkpABCNRKP\d]{1,9}(?:/[abcnrkpABCNRKP\d]{1,9}){9}(\s[wb]\s-\s-\s\d+\s\d+)?$',
      ).hasMatch(fenStr)) {
        gamer.newGame(fen: fenStr);
      } else {
        MyDialog.alert(l10n.invalidCode);
      }
    }
  }

  void copyFen() {
    Clipboard.setData(ClipboardData(text: gamer.fenStr));
    MyDialog.alert(context.l10n.copySuccess);
  }

  Future<void> saveManual() async {
    final content = gamer.manual.export();
    final filename = '${DateTime.now().millisecondsSinceEpoch ~/ 1000}.pgn';
    if (kIsWeb) {
      await _saveManualWeb(content, filename);
    } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _saveManualNative(content, filename);
    }
  }

  Future<void> _saveManualNative(String content, String filename) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save pgn file',
      fileName: filename,
      allowedExtensions: ['pgn'],
    );
    if (context.mounted && result != null) {
      final fData = gbk.encode(content);
      await File('$result/$filename').writeAsBytes(fData);
      if (context.mounted) {
        MyDialog.toast(context.l10n.saveSuccess);
      }
    }
  }

  Future<void> _saveManualWeb(String content, String filename) async {
    final fData = gbk.encode(content);
    final link = html.window.document.createElement('a');
    link.setAttribute('download', filename);
    link.style.display = 'none';
    link.setAttribute('href', Uri.dataFromBytes(fData).toString());
    html.window.document.getElementsByTagName('body')[0].append(link);
    link.click();
    await Future<void>.delayed(const Duration(seconds: 10));
    link.remove();
  }

  Future<void> loadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pgn', 'PGN'],
      withData: true,
    );
    if (result != null && result.count == 1) {
      final content = gbk.decode(result.files.single.bytes!);
      if (gamer.isStop) {
        gamer.newGame();
      }
      gamer.loadPGN(content);
    }
  }
}
