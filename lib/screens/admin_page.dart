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
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();
  // Add this new controller for the category
  final TextEditingController categoryController = TextEditingController();

  List<Map<String, dynamic>> quiz = [];
  
  // Added variables for edit mode
  bool isEditMode = false;
  String? editingCourseId;

  Future<void> addOrUpdateCourse() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        videoUrlController.text.isEmpty ||
        quiz.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    // Create the course data map
    Map<String, dynamic> courseData = {
      'title': titleController.text,
      'description': descriptionController.text,
      'videoUrl': videoUrlController.text,
      'duration': durationController.text,
      'imageUrl': imageUrlController.text,
      'quiz': quiz,
    };

    try {
      if (isEditMode && editingCourseId != null) {
        // Update existing course
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(editingCourseId)
            .update(courseData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course updated successfully')),
        );
      } else {
        // Add new course
        courseData['createdAt'] = Timestamp.now();
        courseData['createdBy'] = 'admin@gmail.com';
        
        await FirebaseFirestore.instance
            .collection('courses')
            .add(courseData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course added successfully')),
        );
      }

      // Reset form and exit edit mode
      clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      print('Error: $e');
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    videoUrlController.clear();
    imageUrlController.clear();
    durationController.clear();
    quiz.clear();
    setState(() {
      isEditMode = false;
      editingCourseId = null;
    });
  }

  void startEditing(QueryDocumentSnapshot course) {
    // Populate form with existing course data
    titleController.text = course['title'];
    descriptionController.text = course['description'];
    videoUrlController.text = course['videoUrl'];
    imageUrlController.text = course['imageUrl'] ?? '';
    durationController.text = course['duration'] ?? '';
    
    // Load quiz questions
    quiz = List<Map<String, dynamic>>.from(course['quiz']);
    
    // Set edit mode
    setState(() {
      isEditMode = true;
      editingCourseId = course.id;
    });
    
    // Scroll to top of the form
    ScrollableState? scrollable = Scrollable.of(context);
    if (scrollable != null) {
      scrollable.position.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void addQuizQuestion() {
    if (quiz.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only add up to 10 questions.')),
      );
      return;
    }

    if (questionController.text.isNotEmpty &&
        optionAController.text.isNotEmpty &&
        optionBController.text.isNotEmpty &&
        optionCController.text.isNotEmpty &&
        optionDController.text.isNotEmpty &&
        correctAnswerController.text.isNotEmpty) {
      
      // Validate correct answer format (must be A, B, C, or D)
      String correctAnswer = correctAnswerController.text.trim().toUpperCase();
      if (!['A', 'B', 'C', 'D'].contains(correctAnswer)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Correct answer must be A, B, C, or D')),
        );
        return;
      }
      
      quiz.add({
        'question': questionController.text,
        'options': {
          'A': optionAController.text,
          'B': optionBController.text,
          'C': optionCController.text,
          'D': optionDController.text,
        },
        'correctAnswer': correctAnswer,
        'category': categoryController.text.isEmpty ? 'General' : categoryController.text,
      });
      
      // Clear all form fields
      questionController.clear();
      optionAController.clear();
      optionBController.clear();
      optionCController.clear();
      optionDController.clear();
      correctAnswerController.clear();
      categoryController.clear();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All question fields are required')),
      );
    }
  }

  Future<void> deleteCourse(String courseId) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Course'),
        content: Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('courses').doc(courseId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course deleted successfully')),
        );
        
        // If we're editing this course, clear the form
        if (isEditMode && editingCourseId == courseId) {
          clearForm();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting course: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Course' : 'Admin Panel'),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (isEditMode)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: clearForm,
              tooltip: 'Cancel Editing',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Text(
                isEditMode ? 'Edit Course' : 'Add New Course',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 16),
              
              // Course form
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Course Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(
                  labelText: 'Video URL',
                  border: OutlineInputBorder(),
                  hintText: 'YouTube video URL',
                  prefixIcon: Icon(Icons.video_library),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Course Image URL',
                  hintText: 'Enter a valid image URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Course Duration',
                  hintText: 'e.g., 2h 30m or 4 weeks',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              SizedBox(height: 24),
              
              // Quiz section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Quiz Questions (Max 10)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: questionController,
                        decoration: InputDecoration(
                          labelText: 'Question',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Add category field
                      TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          labelText: 'Question Category (optional)',
                          hintText: 'e.g., Basic, Advanced, Theory, Practice',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      SizedBox(height: 12),
                      // Options section with improved UI
                      Text(
                        'Answer Options:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'A: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionAController,
                              decoration: InputDecoration(
                                hintText: 'Option A',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'B: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionBController,
                              decoration: InputDecoration(
                                hintText: 'Option B',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'C: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionCController,
                              decoration: InputDecoration(
                                hintText: 'Option C',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'D: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionDController,
                              decoration: InputDecoration(
                                hintText: 'Option D',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Correct answer section with dropdown
                      Row(
                        children: [
                          Text(
                            'Correct Answer: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 120,
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              ),
                              value: correctAnswerController.text.isEmpty ? null : correctAnswerController.text.toUpperCase(),
                              hint: Text('Select'),
                              items: ['A', 'B', 'C', 'D'].map((option) {
                                return DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  correctAnswerController.text = value;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: addQuizQuestion,
                        icon: Icon(Icons.add),
                        label: Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              // Quiz questions list
              if (quiz.isNotEmpty) ...[
                Text(
                  'Quiz Questions:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: quiz.length,
                  itemBuilder: (context, index) {
                    var q = quiz[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text('${index+1}. ${q['question']}'),
                            ),
                            if (q['category'] != null && q['category'].toString().isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  q['category'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('A: ${q['options']['A']}'),
                            Text('B: ${q['options']['B']}'),
                            Text('C: ${q['options']['C']}'),
                            Text('D: ${q['options']['D']}'),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Correct Answer: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    q['correctAnswer'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              quiz.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
              
              SizedBox(height: 24),
              // Submit button
              Center(
                child: ElevatedButton.icon(
                  onPressed: addOrUpdateCourse,
                  icon: Icon(isEditMode ? Icons.save : Icons.add),
                  label: Text(isEditMode ? 'Update Course' : 'Add Course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditMode ? Colors.green : Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              // Existing courses section
              Text(
                'Existing Courses:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No courses available.'),
                      ),
                    );
                  }
                  final courses = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final isCurrentlyEditing = isEditMode && editingCourseId == course.id;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: isCurrentlyEditing ? Colors.blue.withOpacity(0.1) : null,
                        child: ListTile(
                          title: Text(
                            course['title'],
                            style: TextStyle(
                              fontWeight: isCurrentlyEditing ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(course['description']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => startEditing(course),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteCourse(course.id),
                              ),
                            ],
                          ),
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