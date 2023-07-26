import 'package:mysql_client/mysql_client.dart';

import 'chat_room.dart';

class TagsRepository {
  static Future<MySQLConnection?> getRemoteDb(TiDBConnection conn,
      {bool forceInit = false}) async {
    bool shouldInit =
        conn.connection == null || !conn.connection!.connected || forceInit;
    if (conn.host.isEmpty ||
        conn.port == 0 ||
        conn.userName.isEmpty ||
        conn.password.isEmpty) {
      shouldInit = false;
    }

    if (shouldInit) {
      // Make sure the old connection has been close
      conn.connection?.close();

      var dbConn = await MySQLConnection.createConnection(
          host: conn.host,
          port: conn.port,
          userName: conn.userName,
          password: conn.password);
      conn.connection = dbConn;

      await dbConn.connect();

      dbConn.onClose(() {
        // I haven't check the client carefully.
        // Is it enough to handle connection broken or someting bad?
        conn.connection = null;
      });
    }

    return conn.connection;
  }
}
