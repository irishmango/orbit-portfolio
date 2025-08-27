import 'package:orbit/src/features/auth/domain/AppUser.dart';
import 'package:orbit/src/features/collaborations/domain/collaboration.dart';
import 'package:orbit/src/features/collaborations/domain/messaging.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';

abstract class DatabaseRepository {

  Future<List<Task>> getPersonalTasks(String projectId);
  Future<void> createPersonalTask(String projectId, Task task);
  Future<void> deletePersonalTask(String taskId);


  Future<List<Project>> getProjects(String userId);
  Future<void> createProject(String userId, Project project);
  Future<void> deleteProject(String userId, String projectId);
  Future<void> updateProject(String userId, Project project);
  //
  Future<Project> getProjectTasks(String userId, String projectId);
  Future<void> createProjectTask(String projectId, Task task);
  Future<void> updateProjectTask(String projectId, Task task);
  Future<void> deleteProjectTask(String userId, String projectId, String taskId);


  Future<List<Collaboration>> getCollaborations(String userId);
  Future<void> createCollaboration(AppUser creator, Collaboration draft);
  Future<void> deleteCollaboration(String userId, String projectId);
  Future<void> updateCollaboration(String userId, Collaboration collaboration);
  //
  Future<void> createCollaborationProject(String collaborationId, Project project);
  Future<List<Project>> getCollaborationProjects(String collaborationId, List<String> projectIds);
  Future<void> updateCollaborationProject(String collaborationId, String projectId);
  Future<void> deleteCollaborationProject(String collaborationId, String projectId);
  //
  Future<List<Task>> getCollaborationProjectTasks(String collaborationId, String projectId);
  Future<void> createCollaborationProjectTask(String collaboationId, Task task);
  Future<void> updateCollaborationProjectTask(String collaborationId, String taskId);
  Future<void> deleteCollaborationProjectTask(String collaborationId, String taskId);

    // ---- Collaboration Chat ----
  Stream<List<Message>> collabMessagesStream(String collaborationId, {int limit = 50});
  Future<List<Message>> getCollabMessagesOnce(String collaborationId, {int limit = 50});
  Future<List<Message>> getMoreCollabMessages(String collaborationId, {int limit = 50, required DateTime startBefore});
  Future<void> sendCollabMessage(String collaborationId, Message message);
  Future<void> deleteCollabMessage(String collaborationId, String messageId);
    // ---- Collaboration read state ----
  Future<void> markCollabRead(String collaborationId, String userId);
  Stream<bool> hasUnreadCollabMessages(String collaborationId, String userId);

  Future<void> createAppUser(AppUser appUser);
  Future<AppUser> getUser(String userId);
  Future<void> updateAppUser(AppUser appUser);
  Future<void> deleteAppUser(String userId);
}