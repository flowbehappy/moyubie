import 'package:flutter/material.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:get/get.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingPageState();
  }
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    const SizedBox sizedBoxSpace = SizedBox(height: 24);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 70, 70, 70),
        toolbarHeight: 40,
      ),
      body: GetX<SettingsController>(builder: (controller) {
        return ListView(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          children: [
            sizedBoxSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    controller.saveTmpOption();
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
            sizedBoxSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text("AGI"),
                Tooltip(
                  message: "Artificial General Intelligence",
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
            const Divider(
              color: Colors.grey,
              height: 10,
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
            sizedBoxSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 50,
                  child: Text("Service"),
                ),
                const SizedBox(width: 30),
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
                            color:
                                Theme.of(context).colorScheme.primary),
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
            sizedBoxSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 50,
                  child: Text("Model"),
                ),
                const SizedBox(width: 30),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary),
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
            sizedBoxSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 50,
                  child: Text("Token"),
                ),
                const SizedBox(width: 30),
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
            sizedBoxSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text("TiDB Serverless"),
                Tooltip(
                  message: "description for TiDB Serverless",
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
            const Divider(
              color: Colors.grey,
              height: 10,
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
            sizedBoxSpace,
            SizedBox(
              height: 200,
              child: TextFormField(
                initialValue: controller.serverlessCmd.value,
                decoration: InputDecoration(
                  hintText:
                      "mysql --connect-timeout 15 -u xxx.root' -h xxx -P xxx -D test",
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                autovalidateMode: AutovalidateMode.always,
                maxLines: null,
                minLines: 10,
                onEditingComplete: () {},
                onChanged: (value) {
                  controller.setServerlessCmd(value);
                },
              ),
            )
          ],
        );
      }),
    );
  }
}
