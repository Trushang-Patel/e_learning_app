import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Future<void> addCourse() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      print('Title and description cannot be empty');
      return;
    }
    await FirebaseFirestore.instance.collection('courses').add({
      'title': titleController.text,
      'description': descriptionController.text,
    });
    titleController.clear();
    descriptionController.clear();
    print('Course added successfully');
  }

  Future<void> deleteCourse(String courseId) async {
    await FirebaseFirestore.instance.collection('courses').doc(courseId).delete();
    print('Course deleted successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Course Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Course Description'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: addCourse,
                  child: Text('Add Course'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No courses available.'));
                }
                final courses = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return ListTile(
                      title: Text(course['title']),
                      subtitle: Text(course['description']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteCourse(course.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}