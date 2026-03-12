import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pointes_tabel_model.dart';

class PointsTableService {
  static final _doc = FirebaseFirestore.instance
      .collection('app_data')
      .doc('points_table');


  static Stream<DocumentSnapshot> stream() => _doc.snapshots();


  static Future<DocumentSnapshot> fetch() => _doc.get();

  static Future<void> save(PointsTable table) => _doc.set({
    'tournamentName': table.tournamentName,
    'isGroupStage':   table.isGroupStage,
    'isVisible':      table.isVisible,
    'groups': table.groups.map((g) => g.toMap()).toList(),
  });


  static Future<void> setVisible(bool value) =>
      _doc.update({'isVisible': value});


  static Future<void> setGroupStage(bool value) =>
      _doc.update({'isGroupStage': value});
}