import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:Moyubie/controller/settings.dart';
import 'package:Moyubie/repository/tags.dart';
import 'package:Moyubie/utils/ai_recommend.dart';

class TagCollector extends DisposableInterface {
  final TagsRepository repo;
  SettingsController sctl;

  Future<void>? _bgTask;
  List<String> _batching = [];

  RxList<Object> bgErrs = RxList([]);
  RxInt droppedMsgs = 0.obs;
  RxBool enabled = true.obs;

  AIContext get _ai_ctx =>
      AIContext(api_key: sctl.openAiKey.value, model: sctl.gptModel.value);
  bool get available => sctl.openAiKey.isNotEmpty;

  TagCollector({required this.repo, required this.sctl});

  factory TagCollector.create(
      {TagsRepository? repo, SettingsController? sctl}) {
    final theRepo = repo ?? Get.find<TagsRepository>();
    final theSctl = sctl ?? Get.find<SettingsController>();
    var coll = TagCollector(repo: theRepo, sctl: theSctl);
    return coll;
  }

  void accept(String s) {
    if (enabled.isFalse || !available) {
      return;
    }
    log("Getting message $s from user.", name: "TagCollector");
    _batching.add(s);
    if (_bgTask != null) {
      log("Batching for there is pending task.", name: "TagCollector");
      return;
    }
    final batch = _batching;
    _batching = [];
    _bgTask = () async {
      try {
        log("Sending batch $batch to GPT.", name: "TagCollector");
        await sendBatch(batch);
      } catch (e) {
        bgErrs.add(e);
        // Retry, or drop this batch of messages.
        if (_batching.length <= 20) {
          _batching = [...batch, ..._batching];
        } else {
          droppedMsgs.value = droppedMsgs.value + batch.length;
        }
      } finally {
        log("Background task is done.", name: "TagCollector");
        _bgTask = null;
      }
    }();
  }

  Future<void> sendBatch(List<String> batch) async {
    final prof = UserProfiler(_ai_ctx);
    final profile = await prof.messageToTags(batch);
    log("Get tags ${profile.tags} from GPT.", name: "TagCollector");
    await repo.addNewTags(profile.tags);
    log("Saved tags ${profile.tags} to TiDB cloud.", name: "TagCollector");
  }

  @override
  void onClose() {
    _batching = [];
    _bgTask = null;
    super.onClose();
  }
}
