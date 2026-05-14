import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kaiva_database.dart';

final databaseProvider = Provider<KaivaDatabase>((ref) {
  final db = KaivaDatabase();
  ref.onDispose(db.close);
  return db;
});
