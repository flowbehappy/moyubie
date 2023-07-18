// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:moyubie/components/chat.dart';

enum ChatRoomType {
  tablet,
  phone,
}

class ChatRoom extends StatefulWidget {
  const ChatRoom({
    super.key,
    required this.restorationId,
    required this.type,
  });

  final String restorationId;
  final ChatRoomType type;

  @override
  ChatRoomState createState() => ChatRoomState();
}

class ChatRoomState extends State<ChatRoom> with RestorationMixin {
  final RestorableInt _currentIndex = RestorableInt(-1);

  @override
  String get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_currentIndex, 'two_pane_selected_item');
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var panePriority = TwoPanePriority.both;
    if (widget.type == ChatRoomType.phone) {
      panePriority = _currentIndex.value == -1
          ? TwoPanePriority.start
          : TwoPanePriority.end;
    }
    return TwoPane(
      paneProportion: 0.3,
      panePriority: panePriority,
      startPane: ListPane(
        selectedIndex: _currentIndex.value,
        onSelect: (index) {
          setState(() {
            _currentIndex.value = index;
          });
        },
      ),
      endPane: DetailsPane(
        selectedIndex: _currentIndex.value,
        onClose: widget.type == ChatRoomType.phone
            ? () {
                setState(() {
                  _currentIndex.value = -1;
                });
              }
            : null,
      ),
    );
  }
}

class ListPane extends StatelessWidget {
  final ValueChanged<int> onSelect;
  final int selectedIndex;
  final _scrollController = ScrollController();

  ListPane({
    super.key,
    required this.onSelect,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Chat Room"),
      ),
      body: Scrollbar(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          restorationId: 'list_demo_list_view',
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (int index = 1; index < 21; index++)
              ListTile(
                onTap: () {
                  onSelect(index);
                },
                selected: selectedIndex == index,
                leading: ExcludeSemantics(
                  child: CircleAvatar(child: Text('$index')),
                ),
                title: Text(
                  'chat room $index',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DetailsPane extends StatelessWidget {
  final VoidCallback? onClose;
  final int selectedIndex;

  const DetailsPane({
    super.key,
    required this.selectedIndex,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onClose == null
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        title: Text(
          selectedIndex == -1 ? "" : "Chat Room $selectedIndex",
        ),
      ),
      body: const ChatWindow(),
    );
  }
}
