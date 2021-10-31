import 'package:chatapp/login.dart';
import 'package:chatapp/authentication.dart';
import 'package:chatapp/contact_info.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  ChatScreen({
    Key? key,
    required this.userId,
    required this.peerId,
  }) : super(key: key);

  final String peerId;
  final String userId;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? documentId;

  String? _message;

  List<dynamic>? messageList;

  double _rating = 1.0;

  var format = DateFormat("d/M/y hh:mm a");
  var userName = "userName";
  var conversationId;

  final _formKey = GlobalKey<FormState>();

  final textEditingController = TextEditingController();

  String? _peerIdToBeSentToUserInfoScreen;

  getConversationID(String userId, String peerId) {
    userId.hashCode <= peerId.hashCode
        ? conversationId = userId + peerId
        : conversationId = peerId + userId;

    return conversationId;
  }

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.blueGrey, letterSpacing: 0.5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    print("total" + widget.userId + widget.peerId);

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Login()));
      }
    });

    // get user's firstName and lastName
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.peerId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        print('Document data: ${data['firstName']}');
        setState(() {
          userName = data['firstName'] + " " + data['lastName'];
          _peerIdToBeSentToUserInfoScreen = widget.peerId;
        });
      } else {
        print('Document does not exist on the database');
      }
    });

    // print("peerId")
  }

  Widget buildItem(int index, var d, var userId) {
    if (d[index]['msgBy'] == userId) {
      // Right (my message)
      return Row(
        children: <Widget>[
          // Text
          Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Bubble(
                  color: Colors.blueGrey,
                  elevation: 0,
                  padding: const BubbleEdges.all(10.0),
                  nip: BubbleNip.rightTop,
                  child: Text(d[index]['msgBody'],
                      style: TextStyle(color: Colors.white))),
              width: 200)
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              Container(
                child: Bubble(
                    color: Colors.blueGrey,
                    elevation: 0,
                    padding: const BubbleEdges.all(10.0),
                    nip: BubbleNip.leftTop,
                    child: Text(d[index]['msgBody'],
                        style: const TextStyle(color: Colors.white))),
                width: 200.0,
                margin: const EdgeInsets.only(left: 10.0),
              )
            ])
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            title: Text(userName),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: <Widget>[
              IconButton(
                  onPressed: () {
                    // open alert dialog box
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                              title: const Text("Leave a rating for this chat!",
                                  textAlign: TextAlign.center),
                              actions: <Widget>[
                                Container(
                                  child: RatingBar.builder(
                                    initialRating: _rating,
                                    minRating: 0,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {
                                      print(rating);
                                      setState(() {
                                        _rating = rating;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                    color: Colors.white,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              {Navigator.of(context).pop()},
                                          child: const Text('Discard'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // push the rating in the backend
                                            var arr = [];
                                            // get the array from the backend
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(widget.peerId)
                                                .get()
                                                .then((DocumentSnapshot
                                                    documentSnapshot) {
                                              if (documentSnapshot.exists) {
                                                print("Found the doc!!!");
                                                // get the data from this document snapshot
                                                var data =
                                                    documentSnapshot.data()
                                                        as Map<String, dynamic>;
                                                arr = data['ranks'];
                                                // update the arr
                                                arr.add(_rating);

                                                print(
                                                    "after adding to the array");

                                                // push this array back into user collection
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(widget.peerId)
                                                    .update({
                                                  'ranks': arr
                                                }).then((value) {
                                                  print(
                                                      "rank updated successfully");
                                                  Navigator.of(context).pop();
                                                }).catchError((error) => print(
                                                        "error in rank updation"));
                                              }
                                            });
                                          },
                                          child: const Text('Submit Rating'),
                                        ),
                                      ],
                                    ))
                              ],
                            ));
                  },
                  icon: const Icon(Icons.star_border_rounded)),
              IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => contactInfo(
                          xpeerId: _peerIdToBeSentToUserInfoScreen.toString(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info)),
            ]),
        // body: const Center(
        //   child: Text("hello world"),
        // ),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('conversations')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Loading");
            }

            print(
                "UID+PID = " + getConversationID(widget.userId, widget.peerId));

            // get the document from collection
            int i = 0, k = 100;
            Map<String, dynamic> data = {};

            for (var j = 0; j < snapshot.data!.docs.length; j++) {
              if (snapshot.data!.docs[j].id == widget.userId + widget.peerId ||
                  snapshot.data!.docs[j].id == widget.peerId + widget.userId) {
                // id matched
                data = snapshot.data!.docs[j].data()! as Map<String, dynamic>;
                k = j;
                break;
              }
            }

            if (k != 100) {
              // k is not changed.
              // chat has not been started
              var arr = List.from(data['messages'].reversed);

              if (arr.isNotEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemBuilder: (BuildContext context, int index) =>
                      buildItem(index, arr, widget.userId),
                  itemCount: data['messages'].length,
                  reverse: true,
                );
              }
            }

            return const Text("No messages.");
          },
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Form(
            key: _formKey,
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                        hintText: "Type in a Message",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                        fillColor: Colors.black),

                    // onChanged: (val) {
                    //   setState(() {
                    //     _message = val;
                    //   });
                    // }
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                FloatingActionButton(
                  onPressed: () async {
                    // insert the message into document
                    if (textEditingController.text != "") {
                      print("hello");
                      await FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(getConversationID(widget.userId, widget.peerId))
                          .get()
                          .then((DocumentSnapshot documentSnapshot) {
                        if (documentSnapshot.exists) {
                          print('Document exists on the database');
                          Map<String, dynamic> data =
                              documentSnapshot.data()! as Map<String, dynamic>;

                          var messages = data['messages'];

                          // now we need to update this message
                          // we need to create one map
                          Map<String, dynamic> obj = new Map<String, dynamic>();
                          obj["msgBody"] = textEditingController.text;
                          obj["msgBy"] = widget.userId;
                          obj["createdAt"] = DateTime.now();

                          messages.add(obj);

                          FirebaseFirestore.instance
                              .collection("conversations")
                              .doc(getConversationID(
                                  widget.userId, widget.peerId))
                              .update({'messages': messages})
                              .then((value) =>
                                  print("document updated successfully."))
                              .then((value) => {
                                    // clear the message
                                    textEditingController.clear()
                                  });
                        } else {
                          print(
                              "document does not exists in the database. checking other document.");
                          FirebaseFirestore.instance
                              .collection('conversations')
                              .doc(getConversationID(
                                  widget.peerId, widget.userId))
                              .get()
                              .then((DocumentSnapshot documentSnapshot) {
                            if (documentSnapshot.exists) {
                              print('Document exists on the database');
                              Map<String, dynamic> data = documentSnapshot
                                  .data()! as Map<String, dynamic>;

                              var messages = data['messages'];

                              // now we need to update this message
                              // we need to create one map
                              Map<String, dynamic> obj =
                                  new Map<String, dynamic>();
                              obj["msgBody"] = textEditingController.text;
                              obj["msgBy"] = widget.userId;
                              obj["createdAt"] = DateTime.now();

                              messages.add(obj);

                              FirebaseFirestore.instance
                                  .collection("conversations")
                                  .doc(getConversationID(
                                      widget.peerId, widget.userId))
                                  .update({'messages': messages})
                                  .then((value) =>
                                      print("document updated successfully."))
                                  .then((value) => {
                                        // clear the message
                                        textEditingController.clear()
                                      });
                            } else {
                              // userId+peerId // peerId + userId does not exist.
                              print("nothing exists");

                              // create new document
                              // set foloowing data
                              Map<String, dynamic> obj =
                                  new Map<String, dynamic>();
                              obj["msgBody"] = textEditingController.text;
                              obj["msgBy"] = widget.userId;
                              obj["createdAt"] = DateTime.now();

                              var messages = [];
                              messages.add(obj);

                              FirebaseFirestore.instance
                                  .collection('conversations')
                                  .doc(getConversationID(
                                      widget.userId, widget.peerId))
                                  .set({'messages': messages}).then((value) {
                                print("new document is created");
                                textEditingController.clear();
                              }).catchError((onError) => print(
                                      "error occurred while creating new document"));
                            }
                          });
                        }
                      });
                    } else {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   FireAuth.customSnackBar(
                      //     content: "Please type message",
                      //   ),
                      // );
                    }

                    // get the array out of document

                    // update the array

                    // insert array into document
                  },
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                ),
              ],
            ),
          ),
        ));
  }
}
