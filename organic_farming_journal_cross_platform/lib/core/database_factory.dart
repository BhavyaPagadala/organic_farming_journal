import 'package:sembast/sembast.dart';

import 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart'
    as platform;

Future<Database> openDatabase(String path) => platform.openDatabase(path);
