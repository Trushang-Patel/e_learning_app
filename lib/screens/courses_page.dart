import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_learning_app/screens/admin_page.dart';
import 'course_detail_page.dart';

class CoursesPage extends StatefulWidget {
  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Exit'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: _isSearching ? _buildSearchAppBar() : _buildRegularAppBar(),
        body: Column(
          children: [
            // Search bar - visible even when not in search mode
            if (!_isSearching)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              
            // Courses list (with search filter)
            Expanded(
              child: _buildCoursesList(),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildRegularAppBar() {
    return AppBar(
      title: Text('Courses'),
      backgroundColor: Colors.blueAccent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.admin_panel_settings),
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && user.email == 'admin@gmail.com') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPage()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Access denied: Only admins can access this page.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search courses...',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.blueAccent),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _searchQuery = '';
          });
        },
      ),
    );
  }

  Widget _buildCoursesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  'No courses available.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Change this line - explicitly cast to the correct type
        final List<QueryDocumentSnapshot<Object?>> allCourses = snapshot.data!.docs;
        
        // Filter courses based on search query
        final filteredCourses = _searchQuery.isEmpty
            ? allCourses
            : allCourses.where((doc) {
                final title = doc['title'].toString().toLowerCase();
                final description = doc['description'].toString().toLowerCase();
                return title.contains(_searchQuery) || description.contains(_searchQuery);
              }).toList();
              
        if (filteredCourses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  'No courses match your search.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  child: Text('Clear Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredCourses.length,
            itemBuilder: (context, index) {
              final course = filteredCourses[index];
              return _buildCourseCard(course);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildCourseCard(QueryDocumentSnapshot<Object?> course) {
  // Get the course data safely
  final Map<String, dynamic> data = course.data() as Map<String, dynamic>;
  
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailPage(course: course),
        ),
      );
    },
    child: Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image or placeholder - KEEP THIS FIXED HEIGHT
          Container(
            height: 100, // Reduced from 120 to give more space to content
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              image: data.containsKey('imageUrl') && data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(data['imageUrl']),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        return;
                      },
                    )
                  : null,
            ),
            child: (!data.containsKey('imageUrl') || data['imageUrl'] == null || data['imageUrl'].toString().isEmpty)
                ? Center(
                    child: Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                : null,
          ),
          
          // This is the content area - make it flexible with Expanded
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Reduced padding from 12 to 8
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.containsKey('title') ? data['title'] : 'Untitled Course',
                    style: TextStyle(
                      fontSize: 14, // Reduced from 16
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    maxLines: 1, // Reduced from 2
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4), // Reduced from 8
                  Text(
                    data.containsKey('description') ? data['description'] : 'No description available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(), // Push duration to bottom
                  // Duration row
                  Row(
                    children: [
                      Icon(Icons.access_time, 
                           size: 14, // Reduced from 16
                           color: Colors.blueAccent),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.containsKey('duration') && data['duration'] != null 
                              ? data['duration'] 
                              : 'Duration not specified',
                          style: TextStyle(
                            fontSize: 12, // Reduced from 14
                            color: Colors.blueAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}