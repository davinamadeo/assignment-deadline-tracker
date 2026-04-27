import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';
import '../models/assignment.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection('users').doc(_uid).collection('courses');

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _firestore.collection('users').doc(_uid).collection('assignments');


  Future<String> insertCourse(Course course) async {
    final doc = await _courses.add(course.toMap());
    return doc.id;
  }

  Future<List<Course>> getCourses() async {
    final snap = await _courses.orderBy('name').get();
    return snap.docs.map((d) => Course.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Course>> watchCourses() {
    return _courses.orderBy('name').snapshots().map(
          (snap) =>
          snap.docs.map((d) => Course.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<void> updateCourse(Course course) async {
    await _courses.doc(course.id).update(course.toMap());
  }

  Future<void> deleteCourse(String id) async {
    await _courses.doc(id).delete();

    final snap =
    await _assignments.where('courseId', isEqualTo: id).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }


  Future<String> insertAssignment(Assignment a) async {
    final doc = await _assignments.add(a.toMap());
    return doc.id;
  }

  Stream<List<Assignment>> watchPendingAssignments() {
    return _assignments
        .where('status', isEqualTo: AssignmentStatus.pending.index)
        .snapshots()
        .map((snap) {
      final list =
      snap.docs.map((d) => Assignment.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.deadline.compareTo(b.deadline));
      return list;
    });
  }

  Stream<List<Assignment>> watchAssignmentsByCourse(String courseId) {
    return _assignments
        .where('courseId', isEqualTo: courseId)
        .where('status', isEqualTo: AssignmentStatus.pending.index)
        .snapshots()
        .map((snap) {
      final list =
      snap.docs.map((d) => Assignment.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.deadline.compareTo(b.deadline));
      return list;
    });
  }

  Future<void> updateAssignment(Assignment a) async {
    await _assignments.doc(a.id).update(a.toMap());
  }

  Future<void> markDone(String id) async {
    await _assignments
        .doc(id)
        .update({'status': AssignmentStatus.done.index});
  }

  Future<void> deleteAssignment(String id) async {
    await _assignments.doc(id).delete();
  }

  Stream<List<Assignment>> watchDoneAssignments() {
    return _assignments
        .where('status', isEqualTo: AssignmentStatus.done.index)
        .snapshots()
        .map((snap) {
      final list =
      snap.docs.map((d) => Assignment.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.deadline.compareTo(a.deadline)); // newest first
      return list;
    });
  }
}