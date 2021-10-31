import 'package:chatapp/login.dart';
import 'package:chatapp/userinfo.dart';
import 'package:chatapp/chatscreen.dart';
import 'package:chatapp/user_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/authentication.dart';

void main() async {
  await Firebase.initializeApp();
  runApp(MaterialApp(home: Homepage()));
}

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var users;
  var signedOutSnackBar = SnackBar(content: Text('Signed Out!'));

  @override
  void initState() {
    super.initState();
  }

  void getUserDetails() {
    firestore
        .collection("users")
        .orderBy('firstName', descending: true)
        .get()
        .then((querySnapshot) {
      print(querySnapshot.docs.toString());
      setState(() => users = querySnapshot.docs);
    });
  }

  Widget _userDetails() {
    return ListView.builder(
      itemCount: users != null ? users.length : 0,
      itemBuilder: (context, index) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
          child: Authentication.getCurrentUser()!.uid.toString() ==
                  users[index]['userId']
              ? null
              : ListTile(
                  title: Text(
                      "Name: " +
                          users[index]['firstName'] +
                          " " +
                          users[index]['lastName'],
                      style: const TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Date Joined: " + (users[index]['registrationTime'])),
                  leading: Image.network(
                    users[index]['displayPicture'],
                    height: 100,
                    width: 50,
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChatScreen(
                                userId: Authentication.getCurrentUser()!
                                    .uid
                                    .toString(),
                                peerId: users[index]['userId'])));
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (users == null) {
      getUserDetails();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                        title: const Text('Are you sure you want to logout?'),
                        actions: <Widget>[
                          ElevatedButton(
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.blueGrey,
                            ),
                            child: Text('CANCEL'),
                            onPressed: () {
                              setState(() {
                                Navigator.pop(context);
                              });
                            },
                          ),
                          ElevatedButton(
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                            ),
                            child: Text('LOGOUT'),
                            onPressed: () {
                              Authentication.signOut();
                              setState(() {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(signedOutSnackBar);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Login()));
                              });
                            },
                          ),
                        ]);
                  },
                );
              })
        ],
      ),
      body: _userDetails(),
      floatingActionButton: Visibility(
          child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SearchUser()));
              },
              label: Text('New Chat'),
              icon: Icon(Icons.messenger))),
    );
  }
}
