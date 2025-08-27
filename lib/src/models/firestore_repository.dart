import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orbit/src/features/auth/domain/AppUser.dart';
import 'package:orbit/src/features/collaborations/domain/collaboration.dart';
import 'package:orbit/src/features/collaborations/domain/messaging.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/src/models/database_repository.dart';

class FirestoreRepository implements DatabaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;


  // User-related methods
  @override
  Future<void> createAppUser(AppUser appUser) async {
    final collectionRef = _firestore.collection('users').doc(appUser.id);
    await collectionRef.set(appUser.toMap());
  }

  @override
  Future<AppUser> getUser(String userId) async {
    final docRef = _firestore.collection("users").doc(userId);
    final userSnapshot = await docRef.get();

    if (!userSnapshot.exists) {
      throw Exception('User with ID $userId not found.');
    }

    return AppUser.fromMap(userSnapshot.data()!);
  }

  @override
  Future<void> updateAppUser(AppUser appUser) {
    // TODO: implement updateAppUser
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAppUser(String userId) async {
    final userRef = _firestore.collection("users").doc(userId);
    final userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      throw Exception('User with ID $userId not found.');
    }

    WriteBatch batch = _firestore.batch();
    int ops = 0;

    // Delete personal tasks
    final personalTasksSnap = await userRef.collection('personalTasks').get();
    for (var doc in personalTasksSnap.docs) {
      batch.delete(doc.reference);
      if (++ops >= 450) { await batch.commit(); batch = _firestore.batch(); ops = 0; }
    }

    // Delete projects and their tasks
    final projectsSnap = await userRef.collection('projects').get();
    for (var proj in projectsSnap.docs) {
      final tasksSnap = await proj.reference.collection('projectTasks').get();
      for (var task in tasksSnap.docs) {
        batch.delete(task.reference);
        if (++ops >= 450) { await batch.commit(); batch = _firestore.batch(); ops = 0; }
      }
      batch.delete(proj.reference);
      if (++ops >= 450) { await batch.commit(); batch = _firestore.batch(); ops = 0; }
    }

    // Delete the user document itself
    batch.delete(userRef);

    await batch.commit();
  }










  // Task-related methods

  @override
  Future<List<Task>> getPersonalTasks(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('personalTasks')
        .get();

    return snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
  }



  @override
  Future<void> createPersonalTask(String userId, Task task) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('personalTasks')
        .doc(task.id);

    await docRef.set(task.toMap());
  }

  

  @override
  Future<void> checkTask(String projectId, String taskId) {
    // TODO: implement checkTask
    throw UnimplementedError();
  }

  @override
  Future<void> deletePersonalTask(String taskId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('personalTasks')
        .doc(taskId)
        .delete();
  }
  









  // Project-related methods

  @override
  Future<List<Project>> getProjects(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .get();

    return snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList();
  }


  @override
  Future<void> createProject(String userId, Project project) {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc();

    final newProject = Project(
      id: docRef.id,
      title: project.title,
      description: project.description,
      tasks: project.tasks,
      ownerId: project.ownerId,
      tag: project.tag,
    );

    return docRef.set({
      'id': docRef.id,
      ...newProject.toMap(),
    });
    
  }

  

  @override
  Future<void> deleteProject(String userId, String projectId) async {
    final projectRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId);

    final tasksSnapshot = await projectRef.collection('projectTasks').get();
    if (tasksSnapshot.docs.isNotEmpty) {
      WriteBatch batch = _firestore.batch();
      int opCount = 0;

      for (final doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
        opCount++;
        // Takes into account Firestor's limit of 500 operations per bathc
        if (opCount == 450) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }
    }

    // Finally delete the project document itself
    await projectRef.delete();
  }

  @override
  Future<void> updateProject(String userId, Project project) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(project.id);

    await docRef.update({
      'title': project.title,
      'description': project.description,
      'tag': project.tag,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Project> getProjectTasks(String userId, String projectId) async {
    final projectDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .get();

    if (!projectDoc.exists) {
      throw Exception('Project with ID $projectId not found.');
    }

    final projectData = projectDoc.data()!;
    // snapshot of tasks in the project
    final tasksSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('projectTasks')
        .get();

    final tasks = tasksSnapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();

    return Project.fromMap({
      ...projectData,
      'tasks': tasks.map((t) => t.toMap()).toList(),
    });
  }

  @override
  Future<void> createProjectTask(String projectId, Task task) {
    // TODO: implement createProjectTask
    throw UnimplementedError();
  }

  @override
  Future<void> updateProjectTask(String projectId, Task task) {
    // TODO: implement updateProjectTask
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProjectTask(String userId, String projectId, String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('projectTasks')
        .doc(taskId)
        .delete();
  }









  // Collaboration-related methods

  @override
  Future<Collaboration> createCollaboration(AppUser creator, Collaboration draft) async {
    final docRef = _firestore.collection('collaborations').doc();

    // Merge creator into members & memberIds
    final mergedMembers = <AppUser>{...draft.members, creator}.toList();
    final mergedMemberIds = <String>{
      ...draft.memberIds,
      creator.id,
      ...draft.members.map((m) => m.id),
    }.toList();

    final newCollab = Collaboration(
      id: docRef.id,
      title: draft.title,
      description: draft.description,
      members: mergedMembers,
      memberIds: mergedMemberIds,
      creatorId: creator.id,
    );

    await docRef.set({
      'id': docRef.id,
      ...newCollab.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newCollab;
  }

    @override
    Future<List<Collaboration>> getCollaborations(String userId) async {
      final snapshot = await _firestore
          .collection('collaborations')
          .where('memberIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => Collaboration.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    }

  @override
  Future<void> deleteCollaboration(String userId, String collaborationId) async {
    final collabRef = _firestore.collection('collaborations').doc(collaborationId);

    // Delete nested collabProjectTasks and collabProjects
    final projectsSnap = await collabRef.collection('collabProjects').get();
    WriteBatch batch = _firestore.batch();
    int ops = 0;

    for (final proj in projectsSnap.docs) {
      final tasksSnap = await proj.reference.collection('collabProjectTasks').get();
      for (final t in tasksSnap.docs) {
        batch.delete(t.reference);
        if (++ops >= 450) { await batch.commit(); batch = _firestore.batch(); ops = 0; }
      }
      batch.delete(proj.reference);
      if (++ops >= 450) { await batch.commit(); batch = _firestore.batch(); ops = 0; }
    }

    batch.delete(collabRef);
    await batch.commit();
  }

  @override
  Future<void> updateCollaboration(String userId, Collaboration collaboration) {
    // TODO: implement updateCollaboration
    throw UnimplementedError();
  }

  @override
  Future<void> createCollaborationProject(String collaborationId, Project project) async {
    final docRef = _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('collabProjects')
        .doc();

    final newProject = Project(
      id: docRef.id,
      title: project.title,
      description: project.description,
      tasks: project.tasks,
      ownerId: project.ownerId,
      tag: project.tag,
    );

    await docRef.set({
      'id': docRef.id,
      ...newProject.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  @override
  Future<List<Project>> getCollaborationProjects(String collaborationId, List<String> projectIds) async {
    final coll = _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('collabProjects');

    final snap = projectIds.isEmpty
        ? await coll.get()
        : await coll.where(FieldPath.documentId, whereIn: projectIds.length > 10 ? projectIds.sublist(0, 10) : projectIds).get();

    return snap.docs.map((d) => Project.fromMap(d.data())).toList();
  }

  @override
  Future<void> updateCollaborationProject(String collaborationId, String projectId) async {
    await _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('collabProjects')
        .doc(projectId)
        .update({'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> deleteCollaborationProject(String collaborationId, String projectId) async {
    final projectRef = _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('collabProjects')
        .doc(projectId);

    final tasksSnap = await projectRef.collection('collabProjectTasks').get();

    WriteBatch batch = _firestore.batch();
    int ops = 0;
    for (final t in tasksSnap.docs) {
      batch.delete(t.reference);
      if (++ops >= 450) { await batch.commit(); batch = _firestore.batch(); ops = 0; }
    }
    batch.delete(projectRef);
    await batch.commit();
  }

  @override
  Future<List<Task>> getCollaborationProjectTasks(String collaborationId, String projectId) async {
    final snap = await _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('collabProjects')
        .doc(projectId)
        .collection('collabProjectTasks')
        .get();

    return snap.docs.map((d) => Task.fromMap(d.data())).toList();
  }

  @override
  Future<void> createCollaborationProjectTask(String collaborationId, Task task) async {
    final taskRef = _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('collabProjects')
        .doc(task.projectId)
        .collection('collabProjectTasks')
        .doc(task.id);

    await taskRef.set({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateCollaborationProjectTask(String collaborationId, String taskId) async {
    final q = await _firestore
        .collectionGroup('collabProjectTasks')
        .where('id', isEqualTo: taskId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      await q.docs.first.reference.update({'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Future<void> deleteCollaborationProjectTask(String collaborationId, String taskId) async {
    final q = await _firestore
        .collectionGroup('collabProjectTasks')
        .where('id', isEqualTo: taskId)
        .get();

    WriteBatch batch = _firestore.batch();
    for (final d in q.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }


    // ===== Collaboration Chat =====

  @override
  Stream<List<Message>> collabMessagesStream(String collaborationId, {int limit = 50}) {
    final coll = _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return coll.snapshots().map((snap) => snap.docs.map((d) {
          final data = {'id': d.id, ...d.data()};
          return Message.fromMap(data);
        }).toList());
  }

  @override
  Future<List<Message>> getCollabMessagesOnce(String collaborationId, {int limit = 50}) async {
    final snap = await _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => Message.fromMap({'id': d.id, ...d.data()})).toList();
  }

  @override
  Future<List<Message>> getMoreCollabMessages(
    String collaborationId, {
    int limit = 50,
    required DateTime startBefore,
  }) async {
    final snap = await _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(startBefore)]) // paginate older
        .limit(limit)
        .get();

    return snap.docs.map((d) => Message.fromMap({'id': d.id, ...d.data()})).toList();
  }

  @override
  Future<void> sendCollabMessage(String collaborationId, Message message) async {
    final ref = _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('messages')
        .doc();

    await ref.set({
      'id': ref.id,
      'text': message.text,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'senderPhotoUrl': message.senderPhotoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCollabMessage(String collaborationId, String messageId) async {
    await _firestore
        .collection('collaborations')
        .doc(collaborationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

    // ---- Collaboration read state ----
  @override
  Future<void> markCollabRead(String collaborationId, String userId) async {
    final ref = _firestore
        .collection('users').doc(userId)
        .collection('collabReads').doc(collaborationId);

    await ref.set({'lastReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  @override
  Stream<bool> hasUnreadCollabMessages(String collaborationId, String userId) {
    final readsRef = _firestore
        .collection('users').doc(userId)
        .collection('collabReads').doc(collaborationId)
        .snapshots();

    // nest was required here: read the user's lastReadAt, then watch the latest message.
    return readsRef.asyncMap((readSnap) async {
      final lastReadAt = (readSnap.data()?['lastReadAt'] as Timestamp?);

      final latestSnap = await _firestore
          .collection('collaborations').doc(collaborationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (latestSnap.docs.isEmpty) return false;

      final latest = latestSnap.docs.first.data();
      final createdAt = latest['createdAt'] as Timestamp?;
      final senderId = latest['senderId'] as String? ?? '';

      // No timestamp yet (very rare while pending serverTimestamp) -> treat as read.
      if (createdAt == null) return false;

      // Unread if newer than lastRead and not sent by me.
      final isNewer = lastReadAt == null || createdAt.compareTo(lastReadAt) > 0;
      final isMine = senderId == userId;
      return isNewer && !isMine;
    });
  }

  
}
