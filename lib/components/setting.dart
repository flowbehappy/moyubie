import 'package:flutter/material.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:get/get.dart';

class SettingPage extends GetResponsiveView<SettingsController> {
  SettingPage({super.key});

  @override
  Widget? builder() {
    const sizedBoxSpace = SizedBox(height: 24);
    return Scaffold(
      body: GetX<SettingsController>(builder: (controller) {
        return ListView(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          children: [
            sizedBoxSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
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
                  message: "description for AGI",
                  child: IconButton(
                    iconSize: 10.0,
                    splashRadius: 10,
                    color: Theme.of(screen.context).colorScheme.primary,
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
                                Theme.of(screen.context!).colorScheme.primary),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                      ),
                      items: <String>['OpenAI', 'ChatGlm', 'IF']
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
                              color: Theme.of(screen.context!)
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
                        onFieldSubmitted: (value) {
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
                    color: Theme.of(screen.context).colorScheme.primary,
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
                // initialValue: controller.glmBaseUrl.value,
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
                onFieldSubmitted: (value) {
                  controller.setGlmBaseUrl(value);
                },
              ),
            )
          ],
        );
      }),
    );
  }
}
