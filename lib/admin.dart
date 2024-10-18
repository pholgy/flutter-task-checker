import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class AdminPage extends StatefulWidget {
  final String userEmail;

  const AdminPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> _tasks = [];  // List to store tasks
  bool isLoading = true;  // To show loading state
  String errorMessage = '';
  final pb = PocketBase('http://127.0.0.1:8090');  // Initialize PocketBase
  final TextEditingController taskNameController = TextEditingController();  // Task name input

  @override
  void initState() {
    super.initState();
    fetchTasks();  // Load tasks when the page loads
  }

  // Fetch tasks from PocketBase
  Future<void> fetchTasks() async {
    try {
      final response = await pb.collection('tasks').getFullList();  // Fetch all tasks

      setState(() {
        _tasks = response.map((record) => record.data).toList();  // Store tasks
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load tasks: $e';
        isLoading = false;
      });
    }
  }

  // Function to add a new task to PocketBase
  Future<void> addTask(String taskName) async {
    try {
      final record = await pb.collection('tasks').create(body: {
        'task_name': taskName,
        'status': 'Incomplete',
      });

      setState(() {
        _tasks.add(record.data);  // Add task to the list
        taskNameController.clear();  // Clear input
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to add task: $e';
      });
    }
  }

  // Function to delete a task from PocketBase
  Future<void> deleteTask(String taskId, int index) async {
    try {
      await pb.collection('tasks').delete(taskId);  // Delete the task by ID

      setState(() {
        _tasks.removeAt(index);  // Remove task from list
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to delete task: $e';  // Show error if deletion fails
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Display list of tasks
              Expanded(
                child: ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return ListTile(
                      title: Text(task['task_name']),
                      subtitle: Text(task['status']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Pass the task ID to delete the task
                          deleteTask(task['id'], index);  // Delete task by ID
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Input for new tasks
              TextField(
                controller: taskNameController,
                decoration: const InputDecoration(labelText: 'New Task Name'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (taskNameController.text.isNotEmpty) {
                    addTask(taskNameController.text);  // Add new task
                  }
                },
                child: const Text('Add Task'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
