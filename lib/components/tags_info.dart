import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:moyubie/utils/tag_collector.dart';

class TagsInfo extends StatelessWidget {
  final TagCollector _coll;
  final Rx<List<String>?> _$tags = Rx(null);

  TagsInfo(this._coll, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => SwitchListTile(
              title: _coll.enabled.value
                  ? const Text("Tag collector is enabled.")
                  : const Text("Tag collector is disabled."),
              subtitle: _coll.enabled.value
                  ? const Text(
                      "Once you are asking AI, we will try to guess what you love.")
                  : const Text("We won't try to collect your interest point."),
              value: _coll.enabled.value,
              onChanged: (open) {
                _coll.enabled.value = open;
              },
          activeColor: Theme.of(context).primaryColor,
            )),
        const SizedBox(height: 4,),
        ExpansionTile(
            title: const Text("Your Interests"),
            onExpansionChanged: (exp) {
              if (exp && _$tags.value == null) {
                _coll.repo.fetchMostPopularTags(10, waitSync: true).then((value) {
                  _$tags.value = value;
                });
              }
            },
            children: [
              Obx(() => _$tags.value == null
                  ? Center(
                      child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: const CircularProgressIndicator()))
                  : Wrap(
                      alignment: WrapAlignment.start,
                      children: _$tags.value!
                          .map((element) => Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: ActionChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(element),
                                  onPressed: null,
                                ),
                              ))
                          .toList(growable: false),
                    ))
            ])
      ],
    );
  }
}
