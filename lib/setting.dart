import 'package:engine/engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

import 'global.dart';
import 'models/game_setting.dart';

/// 设置页
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  GameSetting setting = GameSetting.getInstance();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = 500;
    if (MediaQuery.of(context).size.width < width) {
      width = MediaQuery.of(context).size.width;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingTitle),
        actions: [
          TextButton(
            onPressed: () {
              setting.save().then((v) {
                Navigator.pop(context);
                MyDialog.toast(context.l10n.saveSuccess,
                    iconType: IconType.success);
              });
            },
            child: Text(context.l10n.saveButton),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  title: Text(context.l10n.aiType),
                  trailing: CupertinoSegmentedControl(
                    onValueChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        setting.info = value as EngineInfo;
                      });
                    },
                    groupValue: setting.info,
                    children: {
                      builtInEngine: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(context.l10n.builtInEngine),
                      ),
                      for (var engine in Engine().getSupportedEngines())
                        engine: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: Text(engine.name),
                        ),
                    },
                  ),
                ),
                ListTile(
                  title: Text(context.l10n.aiLevel),
                  trailing: CupertinoSegmentedControl(
                    onValueChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        setting.engineLevel = value as int;
                      });
                    },
                    groupValue: setting.engineLevel,
                    children: {
                      10: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(context.l10n.levelBeginner),
                      ),
                      11: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                        ),
                        child: Text(context.l10n.levelIntermediate),
                      ),
                      12: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Text(context.l10n.levelMaster),
                      ),
                    },
                  ),
                ),
                ListTile(
                  title: Text(context.l10n.gameSound),
                  trailing: CupertinoSwitch(
                    value: setting.sound,
                    onChanged: (v) {
                      setState(() {
                        setting.sound = v;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text(context.l10n.gameVolume),
                  trailing: CupertinoSlider(
                    value: setting.soundVolume,
                    min: 0,
                    max: 1,
                    onChanged: (v) {
                      setState(() {
                        setting.soundVolume = v;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
