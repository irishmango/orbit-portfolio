import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orbit/auth_repository.dart';
import 'package:orbit/src/features/collaborations/presentation/collaboration_screen.dart';
import 'package:orbit/src/features/home/presentation/widgets/collab_card.dart';
import 'package:orbit/src/features/home/presentation/widgets/project_card.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';
import 'package:orbit/src/features/collaborations/domain/collaboration.dart';
import 'package:orbit/src/features/create/presentation/create_screen.dart';
import 'package:orbit/src/features/home/presentation/widgets/task_card.dart';
import 'package:orbit/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:orbit/src/features/projects/presentation/project_screen.dart';
import 'package:orbit/src/features/tasks/presentation/task_screen.dart';
import 'package:orbit/src/models/database_repository.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:orbit/theme.dart';
import 'package:provider/provider.dart';
class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "Dashboard";
  final List<String> filters = ["Dashboard", "Personal", "Projects", "Collaborations"];
  List<Project> _projects = [];
  List<Task> _tasks = [];
  List<Map<String, dynamic>> shownList = [];
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _fetchedDescription = '';

  Future<void> loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final db = context.read<FirestoreRepository>(); 
    List<Task> allTasks = [];
    List<Project> allProjects = [];
    List<Collaboration> allCollaborations = [];

    // Fetch personal tasks 
    if (selectedFilter == "Personal" || selectedFilter == "Dashboard") {
      allTasks = await db.getPersonalTasks(userId);
    }

    // Fetch projects 
    if (selectedFilter == "Projects" || selectedFilter == "Dashboard") {
      allProjects = await db.getProjects(userId);
    }

    // Fetch collaborations
    if (selectedFilter == "Collaborations" || selectedFilter == "Dashboard") {
      allCollaborations = await db.getCollaborations(userId);
    }

    List<Map<String, dynamic>> composedList;

    if (selectedFilter == "Dashboard") {
  
    composedList = [
      // Collaborations...
      {'type': 'header', 'label': 'Collaborations'},
      if (allCollaborations.isEmpty) {'type': 'placeholder', 'label': 'No collaborations yet'},
      ...allCollaborations.map((c) => {'type': 'collaboration', 'data': c}),
      {'type': 'divider'},

      // Projects (as a grid)
      {'type': 'header', 'label': 'Projects'},
      if (allProjects.isEmpty) {'type': 'placeholder', 'label': 'No projects yet'},
      {'type': 'projects_grid', 'data': allProjects},
      {'type': 'divider'},

      // Tasks...
      {'type': 'header', 'label': 'Tasks'},
      if (allTasks.isEmpty) {'type': 'placeholder', 'label': 'No tasks yet'},
      ...allTasks.map((t) => {'type': 'task', 'data': t}),
    ];




    } else if (selectedFilter == "Personal") {
      composedList = allTasks.map((t) => {'type': 'task', 'data': t}).toList();
    
    } else if (selectedFilter == "Projects") {
      composedList = [
        if (allProjects.isEmpty)
          {'type': 'placeholder', 'label': 'No projects yet'}
        else
          {'type': 'projects_grid', 'data': allProjects},
      ];

    } else if (selectedFilter == "Collaborations") {
      composedList = allCollaborations.map((c) => {'type': 'collaboration', 'data': c}).toList();
    } else {
      composedList = [];
    }

    setState(() {
      _tasks = allTasks;
      _projects = allProjects;
      shownList = composedList;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String getTitle() {
    switch (selectedFilter) {
      case 'Dashboard':
        return 'Dashboard';
      case 'Projects':
        return 'Your Projects';
      case 'Personal':
        return 'Personal Tasks';
      case 'Collaborations':
        return 'Collaborations';
      default:
        return 'Tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<FirestoreRepository>();
    final auth = context.watch<AuthRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      getTitle(),
                      style: AppTextStyles.header,
                      maxLines: 1,
                      // overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 36,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
                      ));
                    },
                    icon: const Icon(Icons.person, size: 48, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = filter == selectedFilter;

                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          selectedFilter = filter;
                        });
                        await loadData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: const Color.fromRGBO(28, 125, 28, 1))
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Text(
                          filter,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ListView
              Expanded(
                child: ListView.builder(
                        itemCount: shownList.length,
                        itemBuilder: (context, index) {
                          final item = shownList[index];

                          if (item['type'] == 'divider') {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                height: 1,
                                color: Colors.white24,
                              ),
                            );
                          }

                          if (item['type'] == 'header') {
                            return Padding(
                              padding: const EdgeInsets.only(top: 0, bottom: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item['label'] ?? '',
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (item['type'] == 'placeholder') {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
                              child: Center(
                                child: Text(
                                  item['label'] ?? '',
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white54,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (item['type'] == 'projects_grid') {
                            final projects = (item['data'] as List<Project>);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,          
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: projects.length,
                              itemBuilder: (context, i) {
                                final project = projects[i];
                                return GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProjectScreen(project: project),
                                      ),
                                    );
                                    await loadData(); 
                                  },
                                  child: ProjectCard(
                                    project: project,
                                  ),
                                );
                              },
                            );
                          } else if (item['type'] == 'task') {
                            final task = item['data'] as Task;
                            final borderColor = switch (task.priority) {
                              TaskPriority.low => Colors.green,
                              TaskPriority.medium => Colors.orange,
                              TaskPriority.high => Colors.red,
                            };

                            return Dismissible(
                              key: ValueKey(task.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.black,
                                    title: const Text("Delete Task", style: AppTextStyles.body),
                                    content: const Text("Are you sure you want to delete this task?", style: TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                return confirm == true;
                              },
                              onDismissed: (_) async {
                                await db.deletePersonalTask(task.id);
                                setState(() {
                                  _tasks.removeWhere((t) => t.id == task.id);
                                  shownList.removeAt(index);
                                });
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskScreen(
                                        title: task.title,
                                        description: task.description,
                                        priority: task.priority.name,
                                      ),
                                    ),
                                  );
                                },
                                child: TaskCard(
                                  task: task,
                                  borderColor: borderColor,
                                ),
                              ),
                            );
                          } else if (item['type'] == 'collaboration') {
                            final collab = item['data'] as Collaboration;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CollaborationScreen(
                                      collaboration: collab,
                                    ),
                                  ),
                                );
                              },
                              child: CollabCard(collaboration: collab,
                                // tag: 'Collaboration',
                                // title: collab.title,
                                // tasks: [collab.description],
                              ),
                            );
                          }

                          return const SizedBox();
                        },
                      ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),


      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(28, 125, 28, 1),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateScreen()),
          );
          if (result != null) {
            await loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}