import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController videoUrlController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();

  List<Map<String, dynamic>> quiz = [];

  Future<void> addCourse() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        videoUrlController.text.isEmpty ||
        quiz.isEmpty) {
      print('All fields are required');
      return;
    }

    await FirebaseFirestore.instance.collection('courses').add({
      'title': titleController.text,
      'description': descriptionController.text,
      'videoUrl': videoUrlController.text,
      'quiz': quiz,
      'createdAt': Timestamp.now(),
      'createdBy': 'admin@gmail.com', // Replace with dynamic admin email if needed
    });

    titleController.clear();
    descriptionController.clear();
    videoUrlController.clear();
    quiz.clear();
    setState(() {});
    print('Course added successfully');
  }

  void addQuizQuestion() {
    if (quiz.length >= 10) {
      print('You can only add up to 10 questions.');
      return;
    }

    if (questionController.text.isNotEmpty &&
        optionAController.text.isNotEmpty &&
        optionBController.text.isNotEmpty &&
        optionCController.text.isNotEmpty &&
        optionDController.text.isNotEmpty &&
        correctAnswerController.text.isNotEmpty) {
      quiz.add({
        'question': questionController.text,
        'options': {
          'A': optionAController.text,
          'B': optionBController.text,
          'C': optionCController.text,
          'D': optionDController.text,
        },
        'correctAnswer': correctAnswerController.text,
      });
      questionController.clear();
      optionAController.clear();
      optionBController.clear();
      optionCController.clear();
      optionDController.clear();
      correctAnswerController.clear();
      setState(() {});
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Course Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Course Description'),
              ),
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(labelText: 'Video URL'),
              ),
              SizedBox(height: 20),
              Text(
                'Add Quiz Questions (Max 10)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: questionController,
                decoration: InputDecoration(labelText: 'Question'),
              ),
              TextField(
                controller: optionAController,
                decoration: InputDecoration(labelText: 'Option A'),
              ),
              TextField(
                controller: optionBController,
                decoration: InputDecoration(labelText: 'Option B'),
              ),
              TextField(
                controller: optionCController,
                decoration: InputDecoration(labelText: 'Option C'),
              ),
              TextField(
                controller: optionDController,
                decoration: InputDecoration(labelText: 'Option D'),
              ),
              TextField(
                controller: correctAnswerController,
                decoration: InputDecoration(labelText: 'Correct Answer (A, B, C, or D)'),
              ),
              ElevatedButton(
                onPressed: addQuizQuestion,
                child: Text('Add Question'),
              ),
              SizedBox(height: 10),
              Text(
                'Quiz Questions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...quiz.map((q) => ListTile(
                    title: Text(q['question']),
                    subtitle: Text(
                        'A: ${q['options']['A']}, B: ${q['options']['B']}, C: ${q['options']['C']}, D: ${q['options']['D']}'),
                    trailing: Text('Answer: ${q['correctAnswer']}'),
                  )),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addCourse,
                child: Text('Add Course'),
              ),
              SizedBox(height: 20),
              Text(
                'Existing Courses:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              StreamBuilder<QuerySnapshot>(
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
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
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
            ],
          ),
        ),
      ),
    );
  }
}