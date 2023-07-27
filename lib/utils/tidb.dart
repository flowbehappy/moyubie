String toConnectionToken(
  String host,
  int port,
  String userName,
  String password,
  String roomId,
) {
  return "mysql -u '$userName' -h $host -P 4000 -p$password --room $roomId";
}

// Return (host, port, user, password, tableId).
// If port == 0, means "host" is the error message.
(String, int, String, String, String) parseTiDBConnectionText(String text) {
  if (text.isEmpty) {
    return ("", 0, "", "", "");
  }

  text = text.replaceFirst(" -p", " -p ");
  final options = text.split(" ");
  var nextOpts = List.from(options);
  nextOpts.removeAt(0);
  nextOpts.add("");
  String user = "";
  String host = "";
  int port = 0;
  String password = "";
  String msgTable = "";

  try {
    for (int i = 0; i < options.length; i += 1) {
      final opt = options[i];
      final nextOpt = nextOpts[i];
      switch (opt) {
        case "-u":
        case "--user":
          user = nextOpt.replaceAll("'", "");
          user = user.replaceAll('"', "");
          user = user.replaceAll("'", "");
          break;
        case "-h":
        case "--host":
          host = nextOpt;
          break;
        case "-P":
        case "--port":
          port = int.parse(nextOpt);
          break;
        case "-p":
        case "--password":
          password = nextOpt;
          break;
        case "--room":
          msgTable = nextOpt;
        default:
      }
    }

    return (host, port, user, password, msgTable);
  } catch (e) {
    return (e.toString(), 0, "", "", "");
  }
}
