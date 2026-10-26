import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

Future<Database> openDatabase(String path) =>
    databaseFactoryWeb.openDatabase(path);
