import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class TaskDashboard extends StatefulWidget {
  final String userEmail;
  const TaskDashboard({Key? key, required this.userEmail}) : super(key: key);

  @override
  _TaskDashboardState createState() => _TaskDashboardState();
}

class _TaskDashboardState extends State<TaskDashboard> {
  List<Map<String, dynamic>> _tasks = [];  // List to store tasks
  final TextEditingController taskController = TextEditingController();
  bool isLoading = true;  // Loading state
  String errorMessage = '';
  final pb = PocketBase('http://127.0.0.1:8090');  // Initialize PocketBase

  @override
  void initState() {
    super.initState();
    fetchTasks();  // Load tasks when the dashboard opens
  }

  // Function to fetch tasks from PocketBase
  Future<void> fetchTasks() async {
    try {
      // Fetch tasks where the user_email field matches the logged-in user
      final response = await pb.collection('tasks').getFullList(
        filter: 'user_email = "${widget.userEmail}"'
      );  

      setState(() {
        _tasks = response.map((record) => record.data).toList();
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
        'user_email': widget.userEmail,  // Associate task with the user's email
      });

      setState(() {
        _tasks.add(record.data);  // Add task to the local list
        taskController.clear();  // Clear the input field
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to save task: $e';
      });
    }
  }

  // Function to mark task as complete in PocketBase
  Future<void> markTaskComplete(int index) async {
    try {
      final taskId = _tasks[index]['id'];
      await pb.collection('tasks').update(taskId, body: {
        'status': 'Complete',
      });

      setState(() {
        _tasks[index]['status'] = 'Complete';  // Update the status locally
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update task: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tasks for ${widget.userEmail}')),
      body: Column(
        children: [
          if (errorMessage.isNotEmpty)
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: taskController,
                decoration: const InputDecoration(labelText: 'Task Name'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  addTask(taskController.text);  // Add new task
                }
              },
              child: const Text('Add Task'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_tasks[index]['task_name']),
                    subtitle: Text(_tasks[index]['status']),
                    trailing: _tasks[index]['status'] == 'Incomplete'
                        ? IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              markTaskComplete(index);  // Mark task as complete
                            },
                          )
                        : const Icon(Icons.done, color: Colors.green),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
