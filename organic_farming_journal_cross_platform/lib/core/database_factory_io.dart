import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openDatabase(String path) =>
    databaseFactoryIo.openDatabase(path);
