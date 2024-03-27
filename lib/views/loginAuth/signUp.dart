import 'package:tb_deliveryapp/all.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  FirebaseService firebaseService = FirebaseService();

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

        final profileImageUploadTask = profileImageRef.putFile(
            _profileImage!,
            SettableMetadata(
              contentType: 'image/jpeg',
            ));
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
        final frontIdImageUploadTask = frontIdImageRef.putFile(
            _frontIdImage!,
            SettableMetadata(
              contentType: 'image/jpeg',
            ));
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
        final backIdImageUploadTask = backIdImageRef.putFile(
            _backIdImage!,
            SettableMetadata(
              contentType: 'image/jpeg',
            ));
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
        'photo_url': profileImageUrl,
        'back_idProof': backIdImageUrl,
        'front_idProof': frontIdImageUrl,
        // You can add more fields here as needed
      });
    } catch (e) {
      print("Error adding user data to Firestore: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Set the image quality (adjust as needed)
        preferredCameraDevice: CameraDevice.front,
      );
      setState(() {
        if (pickedFile != null) {
          _profileImage = File(pickedFile.path);
        }
      });
    } catch (e) {
      print("Error picking profile image: $e");
    }
  }

  Future<void> _pickFrontIdImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      setState(() {
        if (pickedFile != null) {
          _frontIdImage = File(pickedFile.path);
        }
      });
    } catch (e) {
      print("Error picking front ID image: $e");
    }
  }

  Future<void> _pickBackIdImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      setState(() {
        if (pickedFile != null) {
          _backIdImage = File(pickedFile.path);
        }
      });
    } catch (e) {
      print("Error picking back ID image: $e");
    }
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
      ),
      body: Stack(
        children: [
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
                        } else if (!RegExp(r'^\d{1,10}$').hasMatch(value)) {
                          return 'Please enter a valid phone number (up to 10 digits)';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _phoneNumber = value;
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
                        ? Center(
                            child:
                                CircularProgressIndicator()) // Show loading indicator when isLoading is true
                        : ElevatedButton(
                            onPressed: () async {
                              try {
                                setState(() {
                                  _isLoading = true;
                                });

                                // Check if profile images are not uploaded
                                if (_profileImage == null ||
                                    _frontIdImage == null ||
                                    _backIdImage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please upload all required images.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  UserCredential userCredential =
                                      await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                    email: _email!,
                                    password: _password!,
                                  );

                                  if (userCredential.user != null) {
                                    await _addUserDataToFirestore(
                                        userCredential.user!);
                                    // Send email and wait for completion
                                    await firebaseService
                                        .sendEmail(_email!)
                                        .then((_) {
                                      // Email sent successfully, proceed with navigation
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Thank You!'),
                                            content: Text(
                                                'Thank you for signing up.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () async {
                                                  await firebaseService
                                                      .sendEmail(_email!);
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context)
                                                      .pushReplacement(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          LoginPage(),
                                                    ),
                                                  );
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }).catchError((error) {
                                    // Handle error if email sending fails
                                    print("Error sending email: $error");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error sending email. Please try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    });
                                  }
                                }
                              } catch (e) {
                                print("Error: $e");
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            },
                            child: Text('Sign Up'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
