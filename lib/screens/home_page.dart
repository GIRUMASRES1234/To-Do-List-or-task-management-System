import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/task_service.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _auth = AuthService();
  final TaskService _taskService = TaskService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String searchText = "";
  String filterCategory = "All";

  final List<String> categories = ["All", "School", "Work", "Personal"];
  final List<String> priorities = ["High", "Medium", "Low"];

  String selectedCategory = "School";
  String selectedPriority = "Medium";
  DateTime? selectedDate;

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool isOverdue(String? dueDate) {
    if (dueDate == null) return false;

    try {
      final taskDate = DateTime.parse(dueDate);
      final today = DateTime.now();

      return DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
      ).isBefore(DateTime(today.year, today.month, today.day));
    } catch (e) {
      return false;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return const Color(0xFFC62828);
      case "Medium":
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case "School":
        return const Color(0xFF1565C0);
      case "Work":
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF1B5E20);
    }
  }

  Color getCategoryBg(String category) {
    switch (category) {
      case "School":
        return const Color(0xFFE3F2FD);
      case "Work":
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  Color getPriorityBg(String priority) {
    switch (priority) {
      case "High":
        return const Color(0xFFFFEBEE);
      case "Medium":
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddTaskDialog() {
    _titleController.clear();
    _descController.clear();
    selectedCategory = "School";
    selectedPriority = "Medium";
    selectedDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_task,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: ["School", "Work", "Personal"].map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedCategory = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: priorities.map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedPriority = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    await pickDate();
                    setDialogState(() {});
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedDate == null
                              ? 'Pick due date'
                              : 'Due: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: TextStyle(
                            color: selectedDate == null
                                ? Colors.grey.shade600
                                : Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (_titleController.text.trim().isNotEmpty) {
                            await _taskService.addTask(
                              _titleController.text.trim(),
                              _descController.text.trim(),
                              category: selectedCategory,
                              priority: selectedPriority,
                              dueDate: selectedDate?.toString(),
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Save task'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(DocumentSnapshot task) {
    _titleController.text = task["title"] ?? "";
    _descController.text = task["description"] ?? "";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _titleController.clear();
                        _descController.clear();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await _taskService.updateTask(
                          task.id,
                          _titleController.text.trim(),
                          _descController.text.trim(),
                        );
                        Navigator.pop(context);
                        _titleController.clear();
                        _descController.clear();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color iconBg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }

  Widget buildTaskCard(DocumentSnapshot task) {
    final bool isCompleted = task["isCompleted"] ?? false;
    final String category = task["category"] ?? "School";
    final String priority = task["priority"] ?? "Medium";
    final String? dueDate = task["dueDate"];
    final String title = task["title"] ?? "";
    final String desc = task["description"] ?? "";

    final bool overdue = isOverdue(dueDate) && !isCompleted;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete task'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _taskService.deleteTask(task.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: overdue
                ? Colors.red.shade200
                : Colors.grey.withOpacity(0.15),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: isCompleted
                ? const Color(0xFF1565C0)
                : getPriorityColor(priority),
            child: Icon(
              isCompleted
                  ? Icons.check
                  : overdue
                  ? Icons.warning_amber_rounded
                  : Icons.task_alt_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBadge(
                      category,
                      getCategoryBg(category),
                      getCategoryColor(category),
                    ),
                    const SizedBox(width: 6),
                    _buildBadge(
                      priority,
                      getPriorityBg(priority),
                      getPriorityColor(priority),
                    ),
                    const SizedBox(width: 6),
                    if (dueDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: overdue
                                ? Colors.red.shade600
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            dueDate.substring(0, 10),
                            style: TextStyle(
                              fontSize: 12,
                              color: overdue
                                  ? Colors.red.shade600
                                  : Colors.grey.shade600,
                              fontWeight: overdue
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Colors.blue.shade600,
              size: 20,
            ),
            onPressed: () => _showEditTaskDialog(task),
          ),
          onTap: () => _taskService.toggleTaskStatus(task.id, !isCompleted),
        ),
      ),
    );
  }

  // ─── Drawer Header with Profile Image ──────────────────────────────────────

  Widget _drawerHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? imageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          imageUrl = data["profileImage"];
        }

        return DrawerHeader(
          decoration: const BoxDecoration(color: Color(0xFF1565C0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null
                    ? const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              const Text(
                'My profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email ?? 'No email',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Task manager',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onThemeChanged,
            tooltip: 'Toggle theme',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterCategory,
                dropdownColor: Theme.of(context).cardColor,
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: Theme.of(context).iconTheme.color,
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (v) => setState(() => filterCategory = v!),
              ),
            ),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _drawerHeader(),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await _auth.signOut();
              },
            ),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _taskService.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add your first task',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          final allTasks = snapshot.data!.docs;

          final totalTasks = allTasks.length;
          final completedTasks = allTasks
              .where((t) => (t["isCompleted"] ?? false) == true)
              .length;
          final pendingTasks = totalTasks - completedTasks;

          var filteredTasks = allTasks;

          if (filterCategory != "All") {
            filteredTasks = filteredTasks
                .where((t) => (t["category"] ?? "") == filterCategory)
                .toList();
          }

          if (searchText.isNotEmpty) {
            filteredTasks = filteredTasks.where((t) {
              final title = (t["title"] ?? "").toString().toLowerCase();
              return title.contains(searchText.toLowerCase());
            }).toList();
          }

          return Column(
            children: [
              // Stat cards
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    _buildStatCard(
                      'Total',
                      totalTasks.toString(),
                      Icons.format_list_bulleted,
                      const Color(0xFF1565C0),
                      const Color(0xFFE3F2FD),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Done',
                      completedTasks.toString(),
                      Icons.check_circle_outline,
                      const Color(0xFF2E7D32),
                      const Color(0xFFE8F5E9),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Pending',
                      pendingTasks.toString(),
                      Icons.pending_outlined,
                      const Color(0xFFF57F17),
                      const Color(0xFFFFF8E1),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.25),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: (v) => setState(() => searchText = v),
                ),
              ),

              // Task list / grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (filteredTasks.isEmpty) {
                      return Center(
                        child: Text(
                          'No matching tasks',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    if (constraints.maxWidth > 600) {
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.6,
                            ),
                        itemCount: filteredTasks.length,
                        itemBuilder: (_, i) => buildTaskCard(filteredTasks[i]),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredTasks.length,
                      itemBuilder: (_, i) => buildTaskCard(filteredTasks[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
        tooltip: 'Add task',
      ),
    );
  }
}
