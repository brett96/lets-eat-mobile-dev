import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signUpPage.dart';
import 'PasswordReset.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginSignUpPage extends StatefulWidget {
  LoginSignUpPage({this.auth, this.onSignedIn});

  final BaseAuth auth;
  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => new _LoginSignUpPageState();
}

enum FormMode { LOGIN, SIGNUP }

class _LoginSignUpPageState extends State<LoginSignUpPage> {
  final _formKey = new GlobalKey<FormState>();

  String _email;
  String _password;
  String _errorMessage;
  String username;
  String id;
  String gmail;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;
  bool _isIos;
  bool _isLoading;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  void _updateData() async {
    try {
      var results = Firestore.instance.collection('users').where(
          'username', isEqualTo: username // Get current user id
      );

      var querySnap = await results.getDocuments();
      var length = querySnap.documents.length;

      String googleUsername = username;
      if(length > 0){
        var num = 1;
        while(length > 0){
          googleUsername = username + num.toString();
          results = Firestore.instance.collection('users').where(
              'username', isEqualTo: googleUsername  // Get current user id
          );

          var querySnap = await results.getDocuments();
          length = querySnap.documents.length;
          num += 1;
        }
      }


      if (googleUsername.length > 0) {
        Future<DocumentReference> userDoc;

        Firestore.instance.collection('friends').add(
            { // Add user to firestore w/ generated userID
              "id": id,
              "friends": [],
            }).then((fDoc) {
          Firestore.instance.collection('preferences').add(
              {
                "id": id,
              }
          ).then((pDoc) {
            Firestore.instance.collection('likedRestaurants').add(
                {
                  "id": id,
                  "restaurantIDs": [],
                }
            ).then((lDoc) {
              print("Friend ID = " + fDoc.documentID);
              // Add new user to Users collection & include Friends Document ID
              userDoc = Firestore.instance.collection('users').add(
                  {
                    // Add user to firestore w/ generated userID
                    "email": gmail,
                    "id": id,
                    "friendsDocID": fDoc.documentID,
                    // Document ID for current user's Friends document
                    "likedRestaurantsID": lDoc.documentID,
                    "preferencesID": pDoc.documentID,
                    "firstname": username,
                    "username": googleUsername,
                  });
            });
          });
        });
      }
    }
    catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        if (_isIos) {
          _errorMessage = e.details;
        } else
          _errorMessage = e.message;
      });
    }
  }

  Future<String> signInWithGoogle() async {
    print("Starting");
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount.authentication;
    print("SIGN IN COMPLETE");

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    print("OBTAINED GOOGLE CREDENTIALS");

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;
    print("AUTHENTICATED");

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    print("VALIDATED USER");

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
    username = user.displayName;
    id = user.uid;
    gmail = user.email;
    var results = Firestore.instance.collection('users').where(
        'id', isEqualTo: id // Get current user id
    );

    var querySnap = await results.getDocuments();
    var length = querySnap.documents.length;
    if(length == 0){
      _updateData();
    }
    print("SUCCESS!!!!!!");

    return 'signInWithGoogle succeeded: $user';
  }

  void signOutGoogle() async{
    await googleSignIn.signOut();

    print("User Sign Out");
  }

  // Check if form is valid before perform login or signup
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (_validateAndSave()) {
      String userId = "";
      try {
        if (_formMode == FormMode.LOGIN) {
          //_password = new DBCrypt().hashpw(_password, new DBCrypt().gensalt());
          userId = await widget.auth.signIn(_email, _password);
          print('Signed In: $userId');
        } else {
          Route route = MaterialPageRoute(builder: (context) => SignupPage(auth: widget.auth, email: _email, pass: _password,));
          Navigator.push(context, route);
        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId != null && _formMode == FormMode.LOGIN) {
          widget.onSignedIn();
        }

      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          if (_isIos) {
            _errorMessage = e.details;
          } else
            _errorMessage = e.message;
        });
      }
    }
  }


  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  void _changeFormToSignUp() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Sign In'),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _showCircularProgress(){
      if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } return Container(height: 0.0, width: 0.0,);

  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _showBody(){
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              _showLogo(),
              _showEmailInput(),
              _showPasswordInput(),
              _showPrimaryButton(),
              _signInButton(),
              _showSecondaryButton(),
              _showResetPassword(),
              _showErrorMessage(),
            ],
          ),
        ));
  }

  Widget _signInButton() {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: () {
        signInWithGoogle().whenComplete(() {
          widget.onSignedIn();
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage("assets/google_logo.png"), height: 20.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget _showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/logo.gif'),
        ),
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) {
          if(value.isEmpty){
            return "Email can\'t be empty";
          }
          if(!value.contains("@") || !value.contains(".")){
            return "Email not properly formatted";
          }
          return null;
        },
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) {
          if(value.isEmpty){
            return "Password can\'t be empty";
          }
          if(value.length < 6){
            return "Password must be at least 6 characters";
          }
          return null;
        },
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }



  Widget _showSecondaryButton() {
    return new FlatButton(
      child: _formMode == FormMode.LOGIN
          ? new Text('Create an account',
          style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
          : new Text('Have an account? Sign in',
          style:
          new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
      onPressed: _formMode == FormMode.LOGIN
          ? _changeFormToSignUp
          : _changeFormToLogin,
    );
  }

  Widget _showResetPassword() {
    return new FlatButton(
      child: new Text('Forgot Password?',
          style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
      onPressed: () {
        Route route = MaterialPageRoute(builder: (context) => PasswordResetPage(auth: widget.auth,));
        Navigator.push(context, route);
      }
    );
  }

  Widget _showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 10.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: _formMode == FormMode.LOGIN
                ? new Text('Login',
                style: new TextStyle(fontSize: 20.0, color: Colors.white))
                : new Text('Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: _validateAndSubmit,
          ),
        ));
  }

}