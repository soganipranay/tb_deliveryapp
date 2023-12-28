import 'package:tb_deliveryapp/all.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _email;
  String? _password;
  String? _confirmPassword;
  String? _userType;
  File? _profileImage;
  File? _frontIdImage;
  File? _backIdImage;
  String? _phoneNumber;
  bool _showPassword = false;
  bool _isLoading = false;
  final List<String> _userTypes = ['Delivery Partner', 'Representative'];

  Future<void> _addUserDataToFirestore(User user) async {
    try {
      // Reference to the users collection in Firestore
      CollectionReference users =
          FirebaseFirestore.instance.collection('Users');
      String? profileImageUrl;
      if (_profileImage != null) {
        final profileImageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('photo_url')
            .child(user.uid);
        final profileImageUploadTask = profileImageRef.putFile(_profileImage!);
        await profileImageUploadTask.whenComplete(() async {
          profileImageUrl = await profileImageRef.getDownloadURL();
        });
      }
      String? frontIdImageUrl;
      if (_frontIdImage != null) {
        final frontIdImageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('front_idProof')
            .child(user.uid);
        final frontIdImageUploadTask = frontIdImageRef.putFile(_frontIdImage!);
        await frontIdImageUploadTask.whenComplete(() async {
          frontIdImageUrl = await frontIdImageRef.getDownloadURL();
        });
      }
      String? backIdImageUrl;
      if (_backIdImage != null) {
        final backIdImageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('back_idProof')
            .child(user.uid);
        final backIdImageUploadTask = backIdImageRef.putFile(_backIdImage!);
        await backIdImageUploadTask.whenComplete(() async {
          backIdImageUrl = await backIdImageRef.getDownloadURL();
        });
      }
      // Create a new document with a unique ID for the user
      await users.doc(user.uid).set({
        'display_name': _name,
        'email': _email,
        'userType': _userType,
        'adminApproved': "Awaiting Approval",
        'phone_number': _phoneNumber,

        // You can add more fields here as needed
      });
    } catch (e) {
      print("Error adding user data to Firestore: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
      }
    });
  }

  Future<void> _pickFrontIdImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _frontIdImage = File(pickedFile.path);
      }
    });
  }

  Future<void> _pickBackIdImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _backIdImage = File(pickedFile.path);
      }
    });
  }

  Widget _buildFrontIdImage() {
    if (_frontIdImage == null) {
      return ElevatedButton(
        onPressed: _pickFrontIdImage,
        child: Text('Pick Front ID Image'),
      );
    } else {
      return Column(
        children: [
          Image.file(
            _frontIdImage!,
            width: 100,
            height: 100,
          ),
          ElevatedButton(
            onPressed: _pickFrontIdImage,
            child: Text('Change Front ID Image'),
          ),
        ],
      );
    }
  }

  Widget _buildBackIdImage() {
    if (_backIdImage == null) {
      return ElevatedButton(
        onPressed: _pickBackIdImage,
        child: Text('Pick Back ID Image'),
      );
    } else {
      return Column(
        children: [
          Image.file(
            _backIdImage!,
            width: 100,
            height: 100,
          ),
          ElevatedButton(
            onPressed: _pickBackIdImage,
            child: Text('Change Back ID Image'),
          ),
        ],
      );
    }
  }

  Widget _buildProfileImage() {
    if (_profileImage == null) {
      return ElevatedButton(
        onPressed: _pickProfileImage,
        child: Text('Pick Profile Image'),
      );
    } else {
      return Column(
        children: [
          Image.file(
            _profileImage!,
            width: 100,
            height: 100,
          ),
          ElevatedButton(
            onPressed: _pickProfileImage,
            child: Text('Change Profile Image'),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => LoginPage(),
            )); // Navigate back when back button is pressed
          },
        ),
        // leading: Padding(
        //   padding: const EdgeInsets.all(6.0),
        //   child: Image.asset(
        //     'assets/TummyBox_Logo_wbg.png', // Replace with the actual path to your logo image
        //     width: 40, // Adjust the width as needed
        //     height: 40, // Adjust the height as needed
        //   ),
        // ),
      ),
      body: Stack(children: [
        const BackgroundWidget(),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        print("email $value");
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!value.isValidEmail()) {
                          return 'Email not Valid';
                        }
                        // You can add more email validation here if needed
                        return null;
                      },
                      onSaved: (value) {
                        _email = value;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        print("phone $value");
                        if (value == null || value.isEmpty) {
                          return 'Please enter your number';
                        }
                        // You can add more email validation here if needed
                        return null;
                      },
                      onSaved: (value) {
                        _phoneNumber = (value);
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: false,
                      validator: (value) {
                        _password = value;
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        // You can add more password validation here if needed
                        return null;
                      },
                      onSaved: (value) {
                        _password = value;
                      },
                    ),
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: 'Confirm Password'),
                      obscureText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _password) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _confirmPassword = value;
                        print("password4: $value  value1: $_password");
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'User Type'),
                      value: _userType,
                      items: _userTypes.map((String userType) {
                        return DropdownMenuItem<String>(
                          value: userType,
                          child: Text(userType),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _userType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a user type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildProfileImage(),
                    SizedBox(height: 16.0),
                    _buildFrontIdImage(),
                    SizedBox(height: 16.0),
                    _buildBackIdImage(),
                    SizedBox(height: 16.0),
                    _isLoading
                        ? Center(child: CircularProgressIndicator()) // Show loading indicator when isLoading is true
                        : ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                try {
                                  // Create a new user with email and password
                                  UserCredential userCredential =
                                      await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                    email: _email!,
                                    password: _password!,
                                  );

                                  // Check if the user is created successfully
                                  if (userCredential.user != null) {
                                    // User creation was successful
                                    // Add additional user data to Firestore
                                    await _addUserDataToFirestore(
                                        userCredential.user!);

                                    // Navigate to the next screen or perform any desired action
                                    // For example:
                                    Navigator.of(context)
                                        .pushReplacement(MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ));
                                  }
                                } catch (e) {
                                  // Handle any errors that occurred during user creation
                                  print("Error: $e");
                                } finally {
                                  setState(() {
                                    _isLoading =
                                        false; // Set loading state to false
                                  });
                                }
                              }
                            },
                            child: Text('Sign Up')),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}
