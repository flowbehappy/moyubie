import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Moyubie/components/tags_info.dart';
import 'package:Moyubie/controller/chat_room.dart';
import 'package:Moyubie/controller/settings.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Moyubie/repository/chat_room.dart';
import 'package:Moyubie/repository/tags.dart';
import 'package:Moyubie/utils/tag_collector.dart';
import 'package:uuid/uuid.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingPageState();
  }
}

class _SettingPageState extends State<SettingPage> {
  _popFinish(String title, String content) {
    if (context.mounted) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _doRemoveMessage(bool isLocal) async {
    if (isLocal) {
      await ChatRoomRepository().removeDatabase();
      return true;
    } else {
      return await ChatRoomRepository().removeDatabaseRemote();
    }
  }

  _onClearMessage(bool isLocal) async {
    ChatRoomController controller = Get.find();
    controller.reset();
    String location = isLocal ? "local" : "remote";
    if (context.mounted) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          content: Text("Do really want to remove all $location messages?"),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final res = _doRemoveMessage(isLocal);
                res.then((value) {
                  if (value) {
                    _popFinish("Done", "Remove all $location messages done!");
                  } else {
                    _popFinish("Failed", "Remove $location messages failed!");
                  }
                });

                if (context.mounted) {
                  Navigator.pop(context, 'OK');
                }
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const SizedBox sizedBoxSpace = SizedBox(height: 48);
    const SizedBox tap = SizedBox(width: 4);
    const SizedBox space = SizedBox(width: 12);
    return GetX<SettingsController>(builder: (controller) {
      return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          primary: false,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              controller.saveTmpOption(context: context);
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.save),
          ),
          appBar: AppBar(
            toolbarHeight: 0,
            primary: false,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Theme.of(context).brightness,
            ),
            backgroundColor: Theme.of(context).colorScheme.background,
          ),
          body: ListView(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            children: [
              sizedBoxSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text("Nickname"),
                  Tooltip(
                    message: "Set your nickname here.",
                    child: IconButton(
                      iconSize: 10.0,
                      splashRadius: 10,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {},
                      icon: const Icon(Icons.question_mark),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  tap,
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextFormField(
                        initialValue: controller.nickname.value,
                        decoration: InputDecoration(
                          hintMaxLines: 100,
                          hintText: "Set your nickname here",
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                        ),
                        autovalidateMode: AutovalidateMode.always,
                        maxLines: 1,
                        minLines: 1,
                        onEditingComplete: () {},
                        onChanged: (value) {
                          controller.setNickname(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text("AGI"),
                  Tooltip(
                    message:
                        "Artificial General Intelligence.\nYou can use @ai to talk to the AI service in any chat room.",
                    child: IconButton(
                      iconSize: 10.0,
                      splashRadius: 10,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {},
                      icon: const Icon(Icons.question_mark),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tap,
                  const SizedBox(
                    width: 52,
                    child: Text("Service"),
                  ),
                  space,
                  Expanded(
                    child: SizedBox(
                      height: 50.0,
                      width: 200.0,
                      child: DropdownButtonFormField(
                        // padding: EdgeInsets.only(left: 116),
                        value: controller.llm.value,
                        decoration: InputDecoration(
                          // labelText: 'llmHint'.tr,
                          // hintText: 'llmHint'.tr,
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                        ),
                        items: <String>['Echo', 'OpenAI']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          controller.setLlm(newValue);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tap,
                  const SizedBox(
                    width: 52,
                    child: Text("Model"),
                  ),
                  space,
                  Expanded(
                    child: SizedBox(
                      height: 50.0,
                      width: 200.0,
                      child: DropdownButtonFormField(
                          value: controller.gptModel.value,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                          ),
                          items: <String>[
                            'gpt-3.5-turbo',
                            'gpt-3.5-turbo-16k',
                            'gpt-4',
                            'gpt-4-0613',
                            'gpt-4-32k',
                            'gpt-4-32k-0613'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue == null) return;
                            controller.setGptModel(newValue);
                          }),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tap,
                  const SizedBox(
                    width: 52,
                    child: Text("Token"),
                  ),
                  space,
                  Expanded(
                    child: SizedBox(
                        height: 50.0,
                        width: 200.0,
                        child: TextFormField(
                          initialValue: controller.openAiKey.value,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            suffixIcon: IconButton(
                              splashRadius: 10,
                              icon: Icon(
                                Icons.remove_red_eye,
                                color: controller.isObscure.value
                                    ? Colors.grey
                                    : Colors.blue,
                              ),
                              onPressed: () {
                                controller.isObscure.value =
                                    !controller.isObscure.value;
                              },
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.always,
                          maxLines: 1,
                          onChanged: (value) {
                            controller.setOpenAiKey(value);
                          },
                          obscureText: controller.isObscure.value,
                        )),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text("TiDB Serverless"),
                  Tooltip(
                    message:
                        "TiDB Serverless is an online database service.\nMoyubie can store your chat messages on TiDB Serverless, so that you can access them from anywhere with any devices.\nTiDB Serverless is also required for group chat.",
                    child: IconButton(
                      iconSize: 10.0,
                      splashRadius: 10,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {},
                      icon: const Icon(Icons.question_mark),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  tap,
                  Expanded(
                    child: SizedBox(
                      child: TextFormField(
                        initialValue: controller.serverlessCmd.value,
                        decoration: InputDecoration(
                          hintMaxLines:
                              controller.isTiDBCmdObscure.value ? 1 : 10,
                          hintText:
                              "Go to www.tidbcloud.com, create a TiDB cluster of free Serverless Tier. Copy the connection text of your cluster and paste here. For example: \n\nmysql --connect-timeout 15 -u 'xxxxxx.root' -h gateway01.us-west-2.prod.aws.tidbcloud.com -P 4000 -D test --ssl-mode=VERIFY_IDENTITY --ssl-ca=/etc/ssl/cert.pem -pxxxxxx",
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          suffixIcon: IconButton(
                            splashRadius: 10,
                            icon: Icon(
                              Icons.remove_red_eye,
                              color: controller.isTiDBCmdObscure.value
                                  ? Colors.grey
                                  : Colors.blue,
                            ),
                            onPressed: () {
                              controller.isTiDBCmdObscure.value =
                                  !controller.isTiDBCmdObscure.value;
                            },
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.always,
                        maxLines: controller.isTiDBCmdObscure.value ? 1 : null,
                        onEditingComplete: () {},
                        onChanged: (value) {
                          controller.setServerlessCmd(value);
                        },
                        obscureText: controller.isTiDBCmdObscure.value,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text("AI Recommendation"),
                  Tooltip(
                    message: "Control how LLM try to guess things you love.",
                    child: IconButton(
                      iconSize: 10.0,
                      splashRadius: 10,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {},
                      icon: const Icon(Icons.question_mark),
                    ),
                  ),
                ],
              ),
              TagsInfo(Get.find<TagCollector>()),

              // DEBUGGER
              if (kDebugMode) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text("Debugger"),
                    Tooltip(
                      message: "You can see me?",
                      child: IconButton(
                        iconSize: 10.0,
                        splashRadius: 10,
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {},
                        icon: const Icon(Icons.question_mark),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          final repo = Get.find<TagsRepository>();
                          repo
                              .addNewTags(
                                  List.generate(10, (index) => Uuid().v4()))
                              .then((value) =>
                                  log("DONE?", name: "moyubie::tags"))
                              .catchError((err) =>
                                  log("ERROR! [$err]", name: "moyubie::tags"));
                        },
                        child: const Text("Add some random tags for you!")),
                    ElevatedButton(
                        onPressed: () {
                          final repo = Get.find<TagsRepository>();
                          repo
                              .fetchMostPopularTags(10)
                              .then((value) =>
                                  log("DONE? [$value]", name: "moyubie::tags"))
                              .catchError((err) =>
                                  log("ERROR! [$err]", name: "moyubie::tags"));
                        },
                        child: const Text("Fetch tags of you!")),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text("Dangerous Zone"),
                    Tooltip(
                      message: "Don't use it!",
                      child: IconButton(
                        iconSize: 10.0,
                        splashRadius: 10,
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {},
                        icon: const Icon(Icons.question_mark),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                        onPressed: () => _onClearMessage(true),
                        child: const Text("Clear local messages")),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                        onPressed: () => _onClearMessage(false),
                        child: const Text("Clear remote messages")),
                  ],
                ),
              ]
            ],
          ),
        ),
      );
    });
  }
}
