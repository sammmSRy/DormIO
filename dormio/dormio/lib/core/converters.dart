import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

List<String> stringList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

double toDouble(dynamic v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;

int toInt(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
