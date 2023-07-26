// Return (host, port, user, password).
// If port == 0, means "host" is the erorr message.
(String, int, String, String) parseTiDBConnectionText(String text) {
  if (text.isEmpty) {
    return ("", 0, "", "");
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
        default:
      }
    }

    return (host, port, user, password);
  } catch (e) {
    return (e.toString(), 0, "", "");
  }
}
