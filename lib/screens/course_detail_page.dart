import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CourseDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot course;

  CourseDetailPage({required this.course});

  @override
  _CourseDetailPageState createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final Map<int, String> userAnswers = {}; // Stores user answers for each question
  int score = 0;

  void calculateScore() {
    final quiz = List<Map<String, dynamic>>.from(widget.course['quiz']);
    score = 0;

    for (int i = 0; i < quiz.length; i++) {
      if (userAnswers[i] == quiz[i]['correctAnswer']) {
        score += 10; // Each correct answer gives 10 marks
      }
    }

    // Check if the user passed
    if (score >= 75) {
      showCertificateDialog();
    } else {
      showRetryDialog();
    }
  }

  void showCertificateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You scored $score/100 and earned a certificate!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: generateCertificate,
              child: Text('Download Certificate'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Try Again'),
        content: Text('You scored $score/100. You need at least 75 to pass.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> generateCertificate() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Certificate of Achievement',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This is to certify that',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'John Doe', // Replace with the user's name
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'has successfully completed the course',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                widget.course['title'],
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'with a score of $score/100.',
                style: pw.TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );

    // Save the PDF to a file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/certificate.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Certificate downloaded to ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = List<Map<String, dynamic>>.from(widget.course['quiz']);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course['title']),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Title
              Text(
                widget.course['title'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),

              // Course Description
              Text(
                widget.course['description'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),

              // Course Video Section
              Text(
                'Course Video:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.black12,
                child: Center(
                  child: Text(
                    'Video Player Placeholder\n(Video URL: ${widget.course['videoUrl']})',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Quiz Section
              Text(
                'Quiz:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              ...quiz.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> question = entry.value;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${question['question']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...question['options'].entries.map((option) {
                          String optionKey = option.key;
                          String optionValue = option.value;

                          return RadioListTile<String>(
                            title: Text('$optionKey: $optionValue'),
                            value: optionKey,
                            groupValue: userAnswers[index],
                            onChanged: (value) {
                              setState(() {
                                userAnswers[index] = value!;
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: 20),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: calculateScore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Submit Quiz',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}