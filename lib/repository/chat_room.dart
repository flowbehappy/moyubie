import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysql_client/exception.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ChatRoom {
  String uuid;
  String name;
  DateTime createTime; // UTC time zone.
  String connectionToken;

  ChatRoom(
      {required this.uuid,
      required this.name,
      required this.createTime,
      required this.connectionToken});

  Map<String, dynamic> toSQLMap() {
    return {
      'uuid': uuid,
      'name': name,
      'create_time': createTime.millisecondsSinceEpoch,
      'connection_token': connectionToken,
    };
  }
}

enum MessageSource {
  user,
  bot,
}

// The context
class AIConversationContext {
  // TODO
}

class Message {
  String uuid;
  String userName;
  DateTime createTime; // UTC time zone.
  String message;
  MessageSource source;
  bool ask_ai = false;

  Message(
      {required this.uuid,
      required this.userName,
      required this.createTime,
      required this.message,
      required this.source,
      this.ask_ai = false});

  Map<String, dynamic> toSQLMap() {
    return {
      'uuid': uuid,
      'user_name': userName,
      'create_time': createTime.millisecondsSinceEpoch,
      'message': message,
      'source': source.name,
      'ask_ai': ask_ai ? '1' : '0',
    };
  }

  @override
  String toString() {
    return 'Message{uuid: $uuid, userName: $userName, createTime: $createTime, message: $message, source: $source}, askAI: $ask_ai';
  }
}

class ChatRoomRepository {
  static const String _tableChatRoom = 'chat_room';
  static const String _columnChatRoomUuid = 'uuid';
  static const String _columnChatRoomName = 'name';
  // UTC time zone. SQLite: Integer(i.e. Unix Time), TiDB: DateTime
  static const String _columnChatRoomCreateTime = 'create_time';
  static const String _columnChatRoomConnectionToken = 'connection_token';

  static const String _columnMessageUuid = 'uuid';
  static const String _columnMessageUserName = 'user_name';
  // UTC time zone. SQLite: Integer(i.e. Unix Time), TiDB: DateTime
  static const String _columnMessageCreateTime = 'create_time';
  static const String _columnMessageMessage = 'message';
  static const String _columnMessageSource = 'source';
  static const String _columnAskAI = 'ask_ai';

  static MySQLConnection? _remoteDatabase;
  static bool isRemoteDBValid = false;
  static String host = "";
  static int port = 0;
  static String userName = "";
  static String password = "";

  static Database? _database;
  static ChatRoomRepository? _instance;

  ChatRoomRepository._internal();

  factory ChatRoomRepository() {
    _instance ??= ChatRoomRepository._internal();
    return _instance!;
  }

  Future<Database> _getDb() async {
    if (_database == null) {
      final String path = join(await getDatabasesPath(), 'moyubie.db');
      _database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("on create!");
        await db.execute('''
          CREATE TABLE $_tableChatRoom (
            $_columnChatRoomUuid VARCHAR(36) PRIMARY KEY,
            $_columnChatRoomName TEXT,
            $_columnChatRoomCreateTime INTEGER,
            $_columnChatRoomConnectionToken TEXT
          )
        ''');
      });
    }
    return _database!;
  }

  updateRemoteDBConfig(
      String host, int port, String userName, String password) {
    ChatRoomRepository.host = host;
    ChatRoomRepository.port = port;
    ChatRoomRepository.userName = userName;
    ChatRoomRepository.password = password;
  }

  removeDatabase() async {
    String path = join(await getDatabasesPath(), 'moyubie.db');
    await deleteDatabase(path);
    _database = null;
  }

  String remoteDBToString() {
    return "hose: $host, port: $port, userName: $userName, password: $password";
  }

  void setRemoteDBValid(bool v) {
    isRemoteDBValid = v;
  }

  Future<MySQLConnection?> getRemoteDb({bool forceInit = false}) async {
    bool shouldInit = _remoteDatabase == null || !_remoteDatabase!.connected || forceInit;
    if (host.isEmpty || (!isRemoteDBValid && !forceInit)) {
      shouldInit = false;
    }

    try {
      if (shouldInit) {
        // Make sure the old connection has been close
        _remoteDatabase?.close();

        var conn = await MySQLConnection.createConnection(
            host: host, port: port, userName: userName, password: password);
        _remoteDatabase = conn;
        if (_remoteDatabase == null) return Future(() => null);

        await conn.connect();

        conn.onClose(() {
          // I haven't check the client carefully.
          // Is it enough to handle connection broken or someting bad?
          _remoteDatabase = null;
        });

        var res = await conn.execute("SHOW DATABASES LIKE 'moyubie';");
        if (res.rows.isEmpty) {
          await conn.execute("CREATE DATABASE IF NOT EXISTS moyubie;");
        }
        await conn.execute("USE moyubie;");
        res = await conn.execute("SHOW TABLES LIKE 'chat_room';");
        if (res.rows.isEmpty) {
          await conn.execute('''
          CREATE TABLE IF NOT EXISTS $_tableChatRoom (
            $_columnChatRoomUuid VARCHAR(36) PRIMARY KEY,
            $_columnChatRoomName TEXT,
            $_columnChatRoomCreateTime DATETIME,
            $_columnChatRoomConnectionToken TEXT
          )
        ''');
        }
      }
    } catch (e) {
      return Future(() => null);
    }
    return _remoteDatabase;
  }

  Future<List<ChatRoom>> getChatRooms({String? where}) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps =
        await db.query(_tableChatRoom, where: where);
    return List.generate(maps.length, (i) {
      var ct = maps[i][_columnChatRoomCreateTime];
      return ChatRoom(
        uuid: maps[i][_columnChatRoomUuid],
        name: maps[i][_columnChatRoomName],
        createTime: DateTime.fromMicrosecondsSinceEpoch(ct),
        connectionToken: maps[i][_columnChatRoomConnectionToken],
      );
    });
  }

  Future<List<ChatRoom>> getChatRoomsRemote() async {
    final db = await getRemoteDb();
    if (db == null) return Future(() => []);
    var res = await db.execute("SELECT * FROM $_tableChatRoom;");
    return res.rows.map((e) {
      var maps = e.assoc();
      return ChatRoom(
        uuid: maps[_columnChatRoomUuid]!,
        name: maps[_columnChatRoomName]!,
        createTime: DateTime.parse(maps[_columnChatRoomCreateTime]!),
        connectionToken: maps[_columnChatRoomConnectionToken]!,
      );
    }).toList();
  }

  Future<void> replaceLocalChatRooms(List<ChatRoom> rooms) async {
    final db = await _getDb();
    await db.execute("DELETE FROM $_tableChatRoom;");
    for (var room in rooms) {
      await db.insert(
        _tableChatRoom,
        room.toSQLMap(),
      );
    }
  }

  Future<void> addChatRoom(ChatRoom chatRoom) async {
    final db = await _getDb();
    await db.insert(
      _tableChatRoom,
      chatRoom.toSQLMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.execute('''
        CREATE TABLE IF NOT EXISTS `${chatRoom.uuid}` (
          $_columnMessageUuid VARCHAR(36) PRIMARY KEY,
          $_columnMessageUserName TEXT,
          $_columnMessageCreateTime INTEGER,
          $_columnMessageMessage TEXT,
          $_columnMessageSource TEXT,
          $_columnAskAI INTEGER
        )
        ''');
    final remoteDB = await getRemoteDb();
    if (remoteDB != null) {
      await remoteDB.execute('''
        BEGIN;

        INSERT IGNORE INTO $_tableChatRoom 
        (`$_columnChatRoomUuid`, `$_columnChatRoomName`, `$_columnChatRoomCreateTime`, `$_columnChatRoomConnectionToken`) VALUES 
        ('${chatRoom.uuid}', :name, '${chatRoom.createTime.toString()}', :token);

        CREATE TABLE IF NOT EXISTS `${chatRoom.uuid}` (
          $_columnMessageUuid VARCHAR(36) PRIMARY KEY,
          $_columnMessageUserName TEXT,
          $_columnMessageCreateTime DATETIME,
          $_columnMessageMessage TEXT,
          $_columnMessageSource TEXT,
          $_columnAskAI INTEGER
        );

        COMMIT;
        ''', {"name": chatRoom.name, "token": chatRoom.connectionToken});
    }
  }

  Future<void> updateChatRoom(ChatRoom chatRoom) async {
    final db = await _getDb();
    await db.update(
      _tableChatRoom,
      chatRoom.toSQLMap(),
      where: '$_columnChatRoomUuid = ?',
      whereArgs: [chatRoom.uuid],
    );
    final remoteDB = await getRemoteDb();
    if (remoteDB != null) {
      await remoteDB.execute('''
      UPDATE $_tableChatRoom SET
        $_columnChatRoomName = :name,
        $_columnChatRoomCreateTime = unixepoch('${chatRoom.createTime.toString()}'),
        $_columnChatRoomConnectionToken = :token
      WHERE $_columnChatRoomUuid = '${chatRoom.uuid}'
    ''', {"name": chatRoom.name, "token": chatRoom.connectionToken});
    }
  }

  Future<void> deleteChatRoom(String uuid) async {
    final db = await _getDb();
    await db.transaction((txn) async {
      await txn.delete(
        _tableChatRoom,
        where: '$_columnChatRoomUuid = ?',
        whereArgs: [uuid],
      );
    });
    await db.execute('DROP TABLE IF EXISTS `$uuid`');

    final remoteDB = await getRemoteDb();
    if (remoteDB != null) {
      await remoteDB.execute('''
      DELETE FROM $_tableChatRoom WHERE $_columnChatRoomUuid = '$uuid'
    ''');
      await remoteDB.execute('DROP TABLE IF EXISTS `$uuid`');
    }
  }

  Future<List<Message>> getMessagesByChatRoomUUid(String uuid,
      {int limit = 500}) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query('`$uuid`',
        orderBy: "$_columnMessageCreateTime desc", limit: limit);
    return List<Message>.from(maps.reversed.map((m) => Message(
        uuid: m[_columnMessageUuid],
        userName: m[_columnMessageUserName],
        createTime: DateTime.fromMillisecondsSinceEpoch(
            m[_columnMessageCreateTime],
            isUtc: true),
        message: m[_columnMessageMessage],
        source: MessageSource.values
            .firstWhere((e) => e.name == m[_columnMessageSource]),
        ask_ai: m[_columnAskAI] == 1)));
  }

  Future<void> addMessage(String chatRoomUuid, Message message) async {
    final db = await _getDb();
    await db.insert(
      '`$chatRoomUuid`',
      message.toSQLMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Don't wait for remote message finish adding to TiDB.
    var addRemote = addMessageRemote(chatRoomUuid, message);
    addRemote
        .then((value) => {
              // todo
            })
        .onError((error, stackTrace) => {
              // todo
            });
  }

  Future<String?> addMessageRemote(String chatRoomUuid, Message message) async {
    try {
      await insertMessageRemote(chatRoomUuid, message);
    } catch (e) {
      if (e is MySQLServerException) {
        if (e.errorCode == 1146) {
          // Create the chat room. It is possible that user create chat room before adding mysql/TiDB connection.
          final rooms = await getChatRooms(
              where: "$_columnChatRoomUuid = '$chatRoomUuid'");
          if (rooms.length == 1) {
            // Add chat room again.
            await addChatRoom(rooms.first);
            await insertMessageRemote(chatRoomUuid, message);
          } else {
            // If it is not, then too weird. I give up!
          }
        }
      }

      return e.toString();
    }

    // Lots of exception we haven't handled yet. But who cares!
    return null;
  }

  Future<void> insertMessageRemote(String chatRoomUuid, Message message) async {
    var remoteDB = await getRemoteDb();
    if (remoteDB != null) {
      // Must use SQL with param
      await remoteDB.execute('''INSERT IGNORE INTO `$chatRoomUuid` 
      ($_columnMessageUuid, $_columnMessageUserName, $_columnMessageCreateTime, $_columnMessageMessage, $_columnMessageSource, $_columnAskAI) VALUES 
      (:uuid, :user, :createTime, :message, :source, :askAI)''', {
        "uuid": message.uuid,
        "user": message.userName,
        "createTime": message.createTime.toString(),
        "message": message.message,
        "source": message.source,
        "askAI": message.ask_ai ? 1 : 0
      });
    }
  }

  Future<void> deleteMessage(String chatRoomUuid, String messageUuid) async {
    final db = await _getDb();
    await db.delete(
      '`$chatRoomUuid`',
      where: '$_columnMessageUuid = ?',
      whereArgs: [messageUuid],
    );

    final remoteDB = await getRemoteDb();
    if (remoteDB != null) {
      await remoteDB.execute(
          "DELETE FROM `$chatRoomUuid` WHERE $_columnMessageUuid = '$messageUuid'");
    }
  }
}
