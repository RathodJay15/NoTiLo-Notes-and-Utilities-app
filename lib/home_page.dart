// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter/services.dart';
// import 'login_page.dart';
// import 'note_page.dart';
// import 'utility_page.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
//   String username = "User";
//   late TabController _tabController;
//
//   final user = FirebaseAuth.instance.currentUser;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _loadUsername();
//   }
//
//   Future<void> _loadUsername() async {
//     if (user != null) {
//       final doc = await firestore.collection("users").doc(user!.uid).get();
//       setState(() {
//         username = doc.data()?["username"] ?? "User";
//       });
//     }
//   }
//
//   Future<void> _logout() async {
//     await FirebaseAuth.instance.signOut();
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//       );
//     }
//   }
//
//   Future<void> _confirmDelete(Function onDelete) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Confirm Delete"),
//         content: const Text("Do you want to delete?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
//           TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
//         ],
//       ),
//     );
//     if (confirmed == true) {
//       onDelete();
//     }
//   }
//
//   void _addNewItem() {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => Wrap(
//         children: [
//           ListTile(
//             leading: const Icon(Icons.note),
//             title: const Text("New Note"),
//             onTap: () {
//               Navigator.pop(ctx);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const NotePage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.vpn_key),
//             title: const Text("New Utility"),
//             onTap: () {
//               Navigator.pop(ctx);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilityPage()));
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDateTime(DateTime dt) {
//     return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (user == null) return const Center(child: CircularProgressIndicator());
//
//     final notesRef = firestore.collection("users").doc(user!.uid).collection("notes").orderBy("updatedAt", descending: true);
//     final utilitiesRef = firestore.collection("users").doc(user!.uid).collection("utilities").orderBy("createdAt", descending: true);
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Text('Hello, $username', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18)),
//         actions: [
//           TextButton(
//             onPressed: _logout,
//             style: TextButton.styleFrom(
//               backgroundColor: const Color(0xFF5C5C5C),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
//           ),
//           const SizedBox(width: 10),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: const Color(0xFF5C5C5C),
//           labelColor: Colors.black,
//           unselectedLabelColor: Colors.grey,
//           labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//           tabs: const [Tab(text: 'Notes'), Tab(text: 'Utilities')],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // Notes Tab
//           StreamBuilder<QuerySnapshot>(
//             stream: notesRef.snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
//               final docs = snapshot.data?.docs ?? [];
//               if (docs.isEmpty) return const Center(child: Text("No notes added yet.", style: TextStyle(color: Colors.black54)));
//               return ListView.builder(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: docs.length,
//                 itemBuilder: (context, index) {
//                   final note = docs[index];
//                   final data = note.data() as Map<String, dynamic>;
//                   return GestureDetector(
//                     onTap: () {
//                       // Navigate to NotePage with existing note
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => NotePage(note: note, noteId: note.id),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 2))],
//                       ),
//                       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(data['title'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
//                             IconButton(
//                               onPressed: () => _confirmDelete(() async {
//                                 await note.reference.delete();
//                               }),
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Text(data['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14)),
//                         const SizedBox(height: 6),
//                         Text(_formatDateTime((data['updatedAt'] as Timestamp).toDate()), style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)),
//                       ]),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//
//           // Utilities Tab
//           StreamBuilder<QuerySnapshot>(
//             stream: utilitiesRef.snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
//               final docs = snapshot.data?.docs ?? [];
//               if (docs.isEmpty) return const Center(child: Text("No utilities added yet.", style: TextStyle(color: Colors.black54)));
//
//               return ListView.builder(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: docs.length,
//                 itemBuilder: (context, index) {
//                   final utility = docs[index];
//                   final data = utility.data() as Map<String, dynamic>;
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 2))],
//                     ),
//                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                       Text(data['url'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
//                       const SizedBox(height: 4),
//                       Text(data['username'] ?? '', style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14)),
//                       const SizedBox(height: 4),
//                       Text(data['password'] ?? '', style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14)),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           ElevatedButton(
//                             onPressed: () async {
//                               // Open URL
//                               final url = Uri.parse(data['url'] ?? '');
//                               if (await canLaunchUrl(url)) {
//                                 await launchUrl(url);
//                               }
//                               // Copy username/email
//                               if (data['username'] != null) {
//                                 Clipboard.setData(ClipboardData(text: data['username']));
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C5C5C)),
//                             child: const Text("Open"),
//                           ),
//                           const SizedBox(width: 6),
//                           ElevatedButton(
//                             onPressed: () {
//                               if (data['username'] != null) {
//                                 Clipboard.setData(ClipboardData(text: data['username']));
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
//                             child: const Text("Copy"),
//                           ),
//                           const SizedBox(width: 6),
//                           ElevatedButton(
//                             onPressed: () => _confirmDelete(() async {
//                               await utility.reference.delete();
//                             }),
//                             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                             child: const Icon(Icons.delete, color: Colors.white, size: 18),
//                           ),
//                         ],
//                       ),
//                     ]),
//                   );
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xFF5C5C5C),
//         onPressed: _addNewItem,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'note_page.dart';
import 'utility_page.dart';
import 'login_page.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String username = "User";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      setState(() {
        username = doc.data()?["username"] ?? "User";
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _openUrlAndCopy(String url, String usernameOrEmail) async {
    await Clipboard.setData(ClipboardData(text: usernameOrEmail));
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New"),
        content: const Text("Select what you want to add"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotePage()),
              );
            },
            child: const Text("New Note"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UtilityPage()),
              );
            },
            child: const Text("New Utility"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          username,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF5C5C5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5C5C5C),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Utilities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // NOTES TAB
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .collection("notes")
                .orderBy("updatedAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final notes = snapshot.data!.docs;

              if (notes.isEmpty) {
                return const Center(child: Text("No notes found"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final title = note['title'];
                  final description = note['description'];
                  final updatedAt = (note['updatedAt'] as Timestamp).toDate();

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotePage(note: note),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: title + delete
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: const Text("Do you want to delete this note?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm ?? false) {
                                    await note.reference.delete();
                                  }
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // description
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${updatedAt.day}/${updatedAt.month}/${updatedAt.year} ${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')}",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // UTILITIES TAB
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .collection("utilities")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final utilities = snapshot.data!.docs;

              if (utilities.isEmpty) {
                return const Center(child: Text("No utilities found"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: utilities.length,
                itemBuilder: (context, index) {
                  final utility = utilities[index];
                  final url = utility['url'];
                  final usernameOrEmail = utility['usernameOrEmail'];


                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UtilityPage(utility: utility),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            url,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(usernameOrEmail, style: GoogleFonts.poppins(fontSize: 14)),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _openUrlAndCopy(url, usernameOrEmail),
                                child: const Text("Open"),
                              ),
                              TextButton(
                                onPressed: () => _copyToClipboard(usernameOrEmail),
                                child: const Text("Copy"),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: const Text("Do you want to delete this utility?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm ?? false) {
                                    await utility.reference.delete();
                                  }
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5C5C5C),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
