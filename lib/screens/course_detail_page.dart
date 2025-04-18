import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class CourseDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot course;

  CourseDetailPage({required this.course});

  @override
  _CourseDetailPageState createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final Map<int, String> userAnswers = {}; // Stores user answers for each question
  int score = 0;
  
  // YouTube Player controller
  YoutubePlayerController? _youtubeController;
  bool _isPlayerReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeYoutubePlayer();
  }

  void _initializeYoutubePlayer() {
    try {
      final videoUrl = widget.course['videoUrl'];
      
      if (videoUrl != null && videoUrl.toString().isNotEmpty) {
        // Extract video ID from the URL using regex
        RegExp regExp = RegExp(
          r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
          caseSensitive: false,
          multiLine: false,
        );
        
        Match? match = regExp.firstMatch(videoUrl.toString());
        String? videoId;
        
        if (match != null && match.groupCount >= 2) {
          videoId = match.group(2);
          print("Extracted YouTube ID: $videoId");
        } else {
          print("Could not extract YouTube ID from: $videoUrl");
        }
        
        if (videoId != null) {
          _youtubeController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
            params: const YoutubePlayerParams(
              showControls: true,
              mute: false,
              showFullscreenButton: true,
              loop: false,
            ),
          );
          
          // Set the ready state once the controller is initialized
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isPlayerReady = true;
              });
            }
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid YouTube URL: Could not extract video ID';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No video URL provided';
        });
      }
    } catch (e) {
      print('Error initializing YouTube player: $e');
      setState(() {
        _errorMessage = 'Error initializing video: $e';
      });
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

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

  // Add the missing dialog methods
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

  Widget _buildVideoPlayer() {
    if (_youtubeController != null && _isPlayerReady) {
      return Container(
        height: 300, // Increased from 220 to 300
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: YoutubePlayer(
            controller: _youtubeController!,
            // aspectRatio: 16 / 9,
          ),
        ),
      );
    } else if (_errorMessage != null) {
      // Show error message
      return Container(
        height: 200, // Increased from 220 to 300
        
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 40),
              SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              if (widget.course['videoUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'URL: ${widget.course['videoUrl']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Loading state
      return Container(
        height: 300, // Increased from 220 to 300
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading video player...',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }
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
              _buildVideoPlayer(),
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