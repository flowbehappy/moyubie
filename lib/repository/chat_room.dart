import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mysql_client/mysql_client.dart';

class ChatRoom {
  String uuid;
  String name;
  DateTime createTime;
  String connectionToken;

  ChatRoom(
      {required this.uuid,
      required this.name,
      required this.createTime,
      required this.connectionToken});

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'create_time': createTime.toString(),
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
  DateTime createTime;
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
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'user_name': userName,
      'create_time': createTime.toString(),
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
  static const String _columnChatRoomCreateTime = 'create_time';
  static const String _columnChatRoomConnectionToken = 'connection_token';

  static const String _columnMessageUuid = 'uuid';
  static const String _columnMessageUserName = 'user_name';
  static const String _columnMessageCreateTime = 'create_time';
  static const String _columnMessageMessage = 'message';
  static const String _columnMessageSource = 'source';
  static const String _columnAskAI = 'ask_ai';

  static MySQLConnection? _remoteDatabase;
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
      final String path = join(await getDatabasesPath(), 'chatgpt.db');
      _database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("on create!");
        await db.execute('''
          CREATE TABLE $_tableChatRoom (
            $_columnChatRoomUuid VARCHAR(36) PRIMARY KEY,
            $_columnChatRoomName TEXT,
            $_columnChatRoomCreateTime TEXT,
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

  Future<MySQLConnection> _getRemoteDb() async {
    if (_remoteDatabase == null) {
      var conn = await MySQLConnection.createConnection(
          host: host, port: port, userName: userName, password: password);
      _remoteDatabase = conn;
      await conn.connect();
      await conn.execute("CREATE DATABASE IF NOT EXISTS chatgpt;");
      await conn.execute("USE chatgpt;");
      var res = await conn.execute("SHOW TABLES LIKE 'chat_room';");
      if (res.rows.isEmpty) {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS $_tableChatRoom (
            $_columnChatRoomUuid VARCHAR(36) PRIMARY KEY,
            $_columnChatRoomName TEXT,
            $_columnChatRoomCreateTime TEXT,
            $_columnChatRoomConnectionToken TEXT
          )
        ''');
      }
    }
    return _remoteDatabase!;
  }

  Future<List<ChatRoom>> getChatRooms() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableChatRoom);
    return List.generate(maps.length, (i) {
      return ChatRoom(
        uuid: maps[i][_columnChatRoomUuid],
        name: maps[i][_columnChatRoomName],
        createTime: DateTime.parse(maps[i][_columnChatRoomCreateTime]),
        connectionToken: maps[i][_columnChatRoomConnectionToken],
      );
    });
  }

  Future<void> addChatRoom(ChatRoom chatRoom) async {
    final db = await _getDb();
    await db.insert(
      _tableChatRoom,
      chatRoom.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.execute('''
        CREATE TABLE IF NOT EXISTS `${chatRoom.uuid}` (
          $_columnMessageUuid VARCHAR(36) PRIMARY KEY,
          $_columnMessageUserName TEXT,
          $_columnMessageCreateTime TEXT,
          $_columnMessageMessage TEXT,
          $_columnMessageSource TEXT,
          $_columnAskAI INTEGER
        )
        ''');
    final remoteDB = await _getRemoteDb();
    await remoteDB.execute('''
        CREATE TABLE IF NOT EXISTS `${chatRoom.uuid}` (
          $_columnMessageUuid VARCHAR(36) PRIMARY KEY,
          $_columnMessageUserName TEXT,
          $_columnMessageCreateTime TEXT,
          $_columnMessageMessage TEXT,
          $_columnMessageSource TEXT,
          $_columnAskAI INTEGER
        )
        ''');
  }

  Future<void> updateChatRoom(ChatRoom chatRoom) async {
    final db = await _getDb();
    await db.update(
      _tableChatRoom,
      chatRoom.toMap(),
      where: '$_columnChatRoomUuid = ?',
      whereArgs: [chatRoom.uuid],
    );
    final remoteDB = await _getRemoteDb();
    await remoteDB.execute('''
      UPDATE $_tableChatRoom SET
        $_columnChatRoomName = '${chatRoom.name}',
        $_columnChatRoomCreateTime = '${chatRoom.createTime.toString()}',
        $_columnChatRoomConnectionToken = '${chatRoom.connectionToken}'
      WHERE $_columnChatRoomUuid = '${chatRoom.uuid}'
    '''
    );
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

    final remoteDB = await _getRemoteDb();
    await remoteDB.execute('''
      DELETE FROM $_tableChatRoom WHERE $_columnChatRoomUuid = '$uuid'
    ''');
    await remoteDB.execute('DROP TABLE IF EXISTS `$uuid`');
  }

  Future<List<Message>> getMessagesByChatRoomUUid(String uuid) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query('`$uuid`');
    return List.generate(maps.length, (i) {
      return Message(
          uuid: maps[i][_columnMessageUuid],
          userName: maps[i][_columnMessageUserName],
          createTime: DateTime.parse(maps[i][_columnMessageCreateTime]),
          message: maps[i][_columnMessageMessage],
          source: MessageSource.values
              .firstWhere((e) => e.name == maps[i][_columnMessageSource]),
          ask_ai: maps[i][_columnAskAI] == 1);
    });
  }

  Future<void> addMessage(String chatRoomUuid, Message message) async {
    final db = await _getDb();
    await db.insert(
      '`$chatRoomUuid`',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final remoteDB = await _getRemoteDb();
    await remoteDB.execute('''
        INSERT INTO `$chatRoomUuid` VALUES ('${message.uuid}', 
        '${message.userName}', '${message.createTime.toString()}', 
        '${message.message}', '${message.source.name}', ${message.ask_ai ? 1 : 0})
    ''');
  }

  Future<void> deleteMessage(String chatRoomUuid, String messageUuid) async {
    final db = await _getDb();
    await db.delete(
      '`$chatRoomUuid`',
      where: '$_columnMessageUuid = ?',
      whereArgs: [messageUuid],
    );

    final remoteDB = await _getRemoteDb();
    await remoteDB.execute('''
      DELETE FROM `$chatRoomUuid` WHERE $_columnMessageUuid = '$messageUuid'
    ''');
  }
}
