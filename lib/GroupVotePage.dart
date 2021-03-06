import 'dart:async' as prefix0;

import 'package:flutter/material.dart';
import 'Accounts/authentication.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Friends.dart';
import 'Group.dart';
import 'package:location/location.dart';
import 'CreateGroup.dart';
import 'ViewGroup.dart';

class GroupVotePage extends StatefulWidget {
  GroupVotePage({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new _GroupVotePageState();
}

class _GroupVotePageState extends State<GroupVotePage> {

  ///
  /// Group creator presses 'Create new group'
  /// New Group Document is created, w/ user's username as only participant
  /// Store user's username as group creator
  /// When user selects an active group, if that user is the creator, show a
  ///   delete group button
  ///

  bool _isIos;
  bool _isLoading;
  String _errorMessage;
  String _friendUName;
  String uid;
  String friendsID;
  String fDocID;
  final controller = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseUser user;
  bool _isEmailVerified = false;
  var location = new Location();

  @override
  void initState(){
    _errorMessage = "";
    _isLoading = false;
    getCurrentUserInfo();  // store info for current user
    super.initState();
    _checkEmailVerification();
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content:
          new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resentVerifyEmail() {
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text(
              "Please verify your account in the link sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Resent link"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _checkEmailVerification() async {
    user = await FirebaseAuth.instance.currentUser();
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {
      _showVerifyEmailDialog();
    }
  }


  void getCurrentUserInfo() async{
    final FirebaseUser user = await FirebaseAuth.instance.currentUser();//auth.currentUser();
    uid = user.uid;
    print("UID = " + uid);

    Firestore.instance.collection('users').where(
        'id', isEqualTo: uid // Get current user id
    ).snapshots().listen(
      // Update Friends collection that contains current user ID
            (data) =>
        friendsID = data.documents[0]['friendsDocID']);
    //print("Friends ID = " + friendsID);
  }

  Widget _addFriendField()  // Display input field to add friend
  {
    // getCurrentUserInfo();
    return Padding(
      padding: EdgeInsets.fromLTRB(5.0, 10.0, 0.0, 0.0),
      child: new TextFormField(
        controller: controller,
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Enter Friend\'s username',
            icon: new Icon(
              Icons.person_add,
              color: Colors.grey,
            )
        ),
        validator: (value) => value.isEmpty ? 'Username can\'t be empty' : null,
        onSaved: (value) => _friendUName = value.trim(),
      ),
    );
  }

  Future<List<Group>> getGroups() async{  // Get friends list for current user
    getCurrentUserInfo();
    List<Group> groups = [];

    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    String username = currentUser.displayName;

    await Future.delayed(const Duration(milliseconds: 700), (){});  // Wait for promise to return friendsID
    Firestore.instance.collection("groups").where(
        'Participants', arrayContains: username).snapshots().forEach((QuerySnapshot snapshot) {
          snapshot.documents.forEach((DocumentSnapshot snap) async {
            groups.add(Group.fromSnapshot(snap));
          });
    });
    await Future.delayed(const Duration(milliseconds: 700), (){});
    return groups;

//        .getDocuments().then(
//        (data) {
//          try {
//            if(data.documents.length > 0) {
//              print("Group found!");
//              return Group.fromSnapshot(data);
//            }
//            else{
//              print("No groups found");
//            }
//          } catch (e) {
//            print("ERROR::: " + e);
//            return null;
//          }
//        }
//    );

  }

  void loadGroup(){

  }

  Widget _showPrimaryButton() {
    //getCurrentUserInfo();
    return new Padding(
      padding: EdgeInsets.fromLTRB(90.0, 30.0, 10.0, 0.0),
      child: SizedBox(
        height: 40.0,
        width: 200,
        child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: new Text('Create New Group',
                style: new TextStyle(fontSize: 16.0, color: Colors.white)),
            onPressed: () {
              createGroup();
            }
        ),
      ),
    );
  }

  void createGroup() async {
    var latitude;
    var longitude;
    var currentLocation = await location.getLocation();
    latitude = currentLocation.latitude;
    longitude = currentLocation.longitude;
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    Firestore.instance.collection('groups').add({ // Add user to firestore w/ generated userID
      "creatorID": user.uid,
      "Participants": [user.displayName],
      "Preferences": [],
      "lat": latitude,
      "long": longitude,
      "location": "",
      "Result": "",
      "Messages": [],
    }).then((doc) {
      Route route = MaterialPageRoute(builder: (context) => CreateGroupPage(docId: doc.documentID));
      Navigator.push(context, route);
    });
  }

  Widget _showGroupsLabel(){
    return new Padding(
      padding: EdgeInsets.fromLTRB(15.0, 100.0, 0.0, 0.0),
      child: Text("Active Groups:", style: new TextStyle(fontSize: 18.0)),
    );
  }

  Widget _showGroups() {  // Display ListView of Friends
    //getCurrentUserInfo();
    return new Padding(
        padding: EdgeInsets.fromLTRB(10.0, 120.0, 0.0, 0.0),
        child: Center(
            child: FutureBuilder<List<Group>> (
                future: getGroups(),
                builder: (BuildContext c, AsyncSnapshot<List<Group>> data) {
                  if(data.hasData) {
                    return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                            itemCount: data.data.length,
                            itemBuilder: (c, index) {
                              return Center(
                                  child: Card(
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            //Padding(padding: const EdgeInsets.all(8.0)),
                                            ListTile(
                                              title: Text('${data.data[index].participants.toString().substring(1,
                                                  data.data[index].participants.toString().length - 1)}'),
                                              onTap: (){
                                                Route route = MaterialPageRoute(builder: (context) => ViewGroupPage(docId: data.data[index].documentID));
                                                Navigator.push(context, route);
                                              },
                                            ),
                                          ])
                                  )
                              );
                            }
                        )
                    );
                  }
                  else if (data.hasError) {
                    print("error: " + data.error.toString());
                    return Padding(padding: const EdgeInsets.all(8.0), child: Text("You must be logged in to participate in Group Votes"));
                  }
//                  else {
//                    return Padding(padding: const EdgeInsets.all(8.0), child: Text("No Groups Found"));
//                  }

                  // By default, show a loading spinner
                  return CircularProgressIndicator();
                }
            )
        )

//      child: SizedBox(
//        height: 100.0,
//        child: StreamBuilder<Friends>(
//          stream: getFriends(),
//          builder: (BuildContext c, AsyncSnapshot<Friends> data) {
//            if(data?.data == null) return Text("No Friends Found");
//            print("DATA =" + data.toString());
//            Friends friend = data.data;
//
//            return Text("Friends:\n\n${friend.friends}");
//          },
//        )
//      ),
    );
  }
//
//  Widget _showPrimaryButton() {
//    return new Padding(
//        padding: EdgeInsets.fromLTRB(20.0, 45.0, 20.0, 0.0),
//        child: SizedBox(
//          height: 40.0,
//          child: new RaisedButton(
//            elevation: 5.0,
//            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
//            color: Colors.blue,
//            child: new Text('Create Group',
//                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
//            onPressed: () {
//
//            },
//          ),
//        ));
//  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Group Voting'),
        ),
        body: Stack(
          children: <Widget>[
            _showGroupsLabel(),
            _showGroups(),
            //_addFriendField(),
            _showPrimaryButton(),
//            StreamBuilder<Friends>(
//              stream: getFriends(),
//              builder: (BuildContext c, AsyncSnapshot<Friends> data) {
//                if(data?.data == null) return Text("No Friends Found");
//                print("DATA =" + data.toString());
//                Friends friend = data.data;
//
//                return Text("${friend.friends}");
//              },
//            )
          ],
        ));
  }

}