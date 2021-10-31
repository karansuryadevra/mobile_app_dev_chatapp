import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/login.dart';
import 'package:chatapp/chatscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchUser extends StatefulWidget {
  SearchUser({Key? key}) : super(key: key);

  @override
  _SearchUserState createState() => _SearchUserState();
}

// post class
class Post {
  final String title;
  final String imageURL;

  Post(this.title, this.imageURL);
}

class _SearchUserState extends State<SearchUser> {
  TextEditingController _textController = TextEditingController();

  final Stream<QuerySnapshot> _userStream =
      FirebaseFirestore.instance.collection('users').snapshots();

  static const border = OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(5)));

  var userId = "";
  Map<String, dynamic> datax = {};
  var _arr = [];
  var _loading = false;

  @override
  void initState() {
    super.initState();

    // if user is not signed in then send him to all login
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Login()));
      }
      setState(() {
        userId = user!.uid;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: const Text("Search Users"),
      ),
      body: Container(
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(10),
                  hintText: 'Search By First Name',
                  border: border,
                  errorBorder: border,
                  disabledBorder: border,
                  focusedBorder: border,
                  focusedErrorBorder: border,
                  suffixIcon: Container(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _textController.clear();
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _arr = [];
                              });
                              print('search button pressed');
                              setState(() {
                                _loading = true;
                              });
                              // query the users buy first Name
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .where('firstName',
                                      isEqualTo: _textController.text.trim())
                                  .get()
                                  .then((QuerySnapshot querySnapshot) {
                                var arr = [];
                                querySnapshot.docs.forEach((doc) {
                                  Map<String, String> d = {};

                                  d['firstName'] = doc['firstName'];
                                  d['lastName'] = doc['lastName'];
                                  d['imageURL'] = doc['displayPicture'];
                                  d['peerId'] = doc['userId'];

                                  arr.add(d);

                                  setState(() {
                                    _arr = arr;
                                  });
                                });
                              });
                              print(_arr);
                              setState(() {
                                _loading = false;
                              });
                              _textController.clear();
                            },
                            icon: Icon(Icons.search),
                          ),
                        ],
                      ))),
            ),
            Padding(padding: const EdgeInsets.only(top: 20)),
            Expanded(
              child: _arr.isEmpty
                  ? const Text("No Users found")
                  : ListView.builder(
                      itemCount: _arr.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (_arr[index]['peerId'] != userId) {
                          return Card(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      userId: userId,
                                      peerId: _arr[index]['peerId'],
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                    radius: 40.0,
                                    backgroundImage:
                                        NetworkImage(_arr[index]['imageURL'])),
                                title: Text(_arr[index]["firstName"] +
                                    " " +
                                    _arr[index]["lastName"]),
                              ),
                            ),
                          );
                        } else {
                          return const ListTile(
                            title: Text("This User already logged in"),
                          );
                        }
                      }),
            ),
          ],
        ),
      ),
    );
  }
}
