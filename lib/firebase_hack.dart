import 'package:firebase_analytics/firebase_analytics.dart' as g;

// A really hack way to handle that in unsupported platforms, firebase throws
// exception while calling `FirebaseAnalytics.instance`.
class FirebaseAnalytics {
  static dynamic get instance {
    try {
      return g.FirebaseAnalytics.instance;
    } catch (e) {
      return Noop();
    }
  }
}

class Noop {
  // So, everything goes noop...
  // Thankfully we don't rely on the return value of any firebase methods.
  @override
  noSuchMethod(Invocation invocation) {
    return;
  }
}