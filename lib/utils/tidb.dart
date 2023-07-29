import 'package:args/args.dart';

ArgParser tokenParser = createTokenParser();

ArgParser createTokenParser() {
  var p = ArgParser();
  p.addOption("host", abbr: "h");
  p.addOption("port", abbr: "P");
  p.addOption("user", abbr: "u");
  p.addOption("password", abbr: "p");
  p.addOption("room");
  p.addOption("room_name");

  // Options we don't use yet. But we has to define too. Otherwise parser will complain
  p.addOption("connect-timeout");
  p.addOption("database", abbr: "D");
  p.addOption("ssl-mode");
  p.addOption("ssl-ca");

  p.allowsAnything;
  return p;
}

String toConnectionToken(
  String host,
  int port,
  String userName,
  String password,
  String roomId,
  String roomName,
) {
  return "mysql -u '$userName' -h '$host' -P $port -p$password --room '$roomId' --room_name '$roomName'";
}

// Return (host, port, user, password, tableId).
// If port == 0, means "host" is the error message.
(String, int, String, String, String, String) parseTiDBConnectionToken(
    String token) {
  if (token.isEmpty) {
    return ("", 0, "", "", "", "");
  }
  // token =
  // "mysql --connect-timeout 15 -u '3DQS6CX9AX9qY51.root' -h gateway01.eu-central-1.prod.aws.tidbcloud.com -P 4000 -D test --ssl-mode=VERIFY_IDENTITY --ssl-ca=/etc/ssl/cert.pem -piAaVmmI4dypKbEgY";
  try {
    final tokens = tokenize(token);
    final r = tokenParser.parse(tokens);
    final host = r["host"];
    final port = int.parse(r["port"]);
    final user = r["user"];
    final password = r["password"];
    final roomId = r["room"] ?? "";
    final roomName = r["room_name"] ?? "";

    return (host, port, user, password, roomId, roomName);
  } catch (e) {
    return (e.toString(), 0, "", "", "", "");
  }
}

List<String> tokenize(String input) {
  if (input.isEmpty) {
    //no command? no string
    return [];
  }

  var result = List<String>.empty(growable: true);

  var current = "";

  String? inQuote;
  bool lastTokenHasBeenQuoted = false;

  for (int index = 0; index < input.length; index++) {
    final token = input[index];

    if (inQuote != null) {
      if (token == inQuote) {
        lastTokenHasBeenQuoted = true;
        inQuote = null;
      } else {
        current += token;
      }
    } else {
      switch (token) {
        case "'": // '
        case '"': // ""
          inQuote = token;
          continue;

        case " ": // space
          if (lastTokenHasBeenQuoted || current.isNotEmpty) {
            result.add(current);
            current = "";
          }
          break;

        default:
          current += token;
          lastTokenHasBeenQuoted = false;
      }
    }
  }

  if (lastTokenHasBeenQuoted || current.isNotEmpty) {
    result.add(current);
  }

  if (inQuote != null) {
    throw Exception("Unbalanced quote $inQuote in input: $input");
  }

  return result;
}
