import 'dart:async';
import 'package:tmw/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:tmw/model/post_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart' as crypto;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter App',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}

// Used for controlling whether the user is loggin or creating an account
enum FormType { login, register }

class _LoginPageState extends State<LoginPage> {
    User sessionUser;

  List _counties = [];
  List _cities = [];

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailFilter = new TextEditingController();
  final TextEditingController _passwordFilter = new TextEditingController();
  final TextEditingController _lastNameFilter = new TextEditingController();
  final TextEditingController _firstNameFilter = new TextEditingController();
  final TextEditingController _countyFilter = new TextEditingController();
  final TextEditingController _cityFilter = new TextEditingController();

  String _county;

//  String _city;
  String _selectedCity;

//  final TextEditingController _typeAheadController = TextEditingController();

  String _email = "";
  String _password = "";
  FormType _form = FormType.login; // our default setting is to login, and we should switch to creating an account when the user chooses to

  _LoginPageState();

  Future<File> get _usersDataFile async {
    File usersDataFile = File(await _localPath + '/usersData.json');
    if (await usersDataFile.exists() == false) {
      await usersDataFile.create();
    }

    return usersDataFile;
  }

  // Swap in between our two forms, registering and logging in
  void _formChange() async {
    setState(() {
      if (_form == FormType.register) {
        _form = FormType.login;
      } else {
        _form = FormType.register;
      }
    });
  }

    void _loginUser(User user) {
        setState(() {
            sessionUser = user;
        });
    }

    void _logoutUser() {
        setState(() {
            sessionUser = null;
        });
    }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: _buildBar(context),
        body: SingleChildScrollView(
          child: new Container(
            padding: EdgeInsets.all(16.0),
            child: _authOrApp(),
          ),
        ));
  }

  Column _authOrApp() {
      if(sessionUser != null) {
          return new Column(
              children: <Widget>[
                  _authenticatedView(),
          ],);
      } else {
          return new Column(
              children: <Widget>[
                  _buildTextFields(),
                  _buildButtons(),
              ],
          );
      }
  }

  Widget _authenticatedView() {
      return Center(
          child: Column(
             children: <Widget>[
                 Text(
                     'You are logged in!',
                     textAlign: TextAlign.center,
                 ),
                 new RaisedButton(
                     child: new Text('Logout'),
                     color: Colors.red,
                     textColor: Colors.white,
                     onPressed: () {
                         return this._logoutUser();
                     },
                 )
             ],
          ),
      );
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      title: new Text("TMW Login"),
      centerTitle: true,
    );
  }

  Form _buildLoginTextFieldsContainer() {
    return new Form(
      key: _formKey,
      child: new Column(
        children: <Widget>[
          new Container(
            child: new TextFormField(
              controller: _emailFilter,
              decoration: new InputDecoration(labelText: 'FirstName'),
              validator: (value) {
                if (value.isEmpty) return 'Mandatory parameter';
              },
            ),
          ),
          new Container(
            child: new TextFormField(
                controller: _passwordFilter,
                decoration: new InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value.isEmpty) return 'Mandatory parameter';
                }),
          ),
        ],
      ),
    );
  }

  Form _buildRegisterTextFieldsContainer() {
    return Form(
      key: _formKey,
      child: new Column(
        children: <Widget>[
          new Container(
            child: new TextFormField(
              controller: _firstNameFilter,
              decoration: new InputDecoration(labelText: 'FirstName'),
              validator: (value) {
                if (value.isEmpty) return 'Mandatory parameter';
              },
            ),
          ),
          new Container(
            child: new TextFormField(
              controller: _lastNameFilter,
              decoration: new InputDecoration(labelText: 'LastName'),
              validator: (value) {
                if (value.isEmpty) return 'Mandatory parameter';
              },
            ),
          ),
          new Container(
            child: new TextFormField(
              controller: _emailFilter,
              decoration: new InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value.isEmpty) return 'Mandatory parameter';
              },
            ),
          ),
          new Container(
            child: new TextFormField(
              controller: _passwordFilter,
              decoration: new InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value.isEmpty) return 'Mandatory parameter';
              },
              obscureText: true,
            ),
          ),
          new Container(
            child: getCountiesFutureBuilder(),
          ),
          new Container(
            child: getCitiesFutureBuilder(),
          )
        ],
      ),
    );
  }

  Widget _buildTextFields() {
    if (_form == FormType.login) {
      return _buildLoginTextFieldsContainer();
    } else {
      return _buildRegisterTextFieldsContainer();
    }
  }

  Widget _buildButtons() {
    if (_form == FormType.login) {
      return new Form(
        child: new Column(
          children: <Widget>[
            new RaisedButton(
              child: new Text('Login'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  return _loginPressed();
                }
              },
            ),
            new FlatButton(
              child: new Text('Dont have an account? Tap here to register.'),
              onPressed: _formChange,
            ),
            new FlatButton(
              child: new Text('Forgot Password?'),
              onPressed: _passwordReset,
            )
          ],
        ),
      );
    } else {
      return new Form(
        child: new Column(
          children: <Widget>[
            new RaisedButton(
              child: new Text('Create an Account'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  return _createAccountPressed();
                }
              },
            ),
            new FlatButton(
              child: new Text('Have an account? Click here to login.'),
              onPressed: _formChange,
            )
          ],
        ),
      );
    }
  }

  // These functions can self contain any user auth logic required, they all have access to _email and _password
  void _loginPressed() async {
    String email = _emailFilter.text;
    String password = generateMd5(_passwordFilter.text);

    File usersDataFile = await this._usersDataFile;

    usersDataFile.readAsString().then((String contents) {
      Map<String, dynamic> usersData = {};

      if (contents != null && contents.isNotEmpty) {
        usersData = json.decode(contents);
      }

      if (usersData.containsKey(email) && usersData[email]['password'] == password) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(content: Text('Success.'));
            });
            var userFromJson = usersData[email];

            _loginUser(User(
                email: email,
                lastName: userFromJson['lastName'],
                county: userFromJson['county'],
                firstName: userFromJson['firstName'],
                city: userFromJson['city'],
                password: userFromJson['password']
            ));

      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(content: Text('Invalid email / password.'));
            });
      }
    });
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  String generateMd5(String stringToEncrypt) {
    return crypto.md5.convert(Utf8Encoder().convert(stringToEncrypt)).toString();
  }

  void _createAccountPressed() async {
    String email = _emailFilter.text;
    String firstName = _firstNameFilter.text;
    String lastName = _lastNameFilter.text;
    String county = _county;
    String city = _cityFilter.text;
    String password = generateMd5(_passwordFilter.text);

    File usersDataFile = await this._usersDataFile;

    usersDataFile.readAsString().then((String contents) {
      Map<String, dynamic> usersData = {};

      if (contents != null && contents.isNotEmpty) {
        usersData = json.decode(contents);
      }
      if (usersData.containsKey(email)) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(content: Text('Email address already in use.'));
            });
      } else {
        usersData[email] = {'email': email, 'firstName': firstName, 'lastName': lastName, 'county': county, 'city': city, 'password': password};

        try {
          print(json.encode(usersData));
          usersDataFile.writeAsString(json.encode(usersData), mode: FileMode.write, encoding: utf8);
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(content: Text('Account created. Please login!'));
              });
          _formChange();
        } catch (exception) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(content: Text('Could not create account. Please try again'));
              });
        }
      }
    });
  }

  void _passwordReset() {
    print("The user wants a password reset request sent to $_email");
  }

  FutureBuilder getCountiesFutureBuilder() {
    List<DropdownMenuItem<String>> _countiesDropDown;
    Text _hint = new Text('Loading...');

    return FutureBuilder(
        future: _getCounties(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data != null) {
            _selectedCity = null;
            _countiesDropDown = snapshot.data.map<DropdownMenuItem<String>>((value) {
              if (value['auto'].length > 0 && value['nume'].length > 0) {
                return new DropdownMenuItem(
                  key: Key(value['auto'].toString()),
                  value: value['auto'].toString(),
                  child: new Text(value['nume'].toString()),
                );
              }
            }).toList();
            _hint = new Text('');
          } else {}
          return Container(
            child: new DropdownButtonFormField(
              decoration: new InputDecoration(labelText: 'County', isDense: true),
              value: _county,
              hint: _hint,
              onChanged: (String newValue) {
                setState(() {
                  _county = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please select a county';
              },
              items: _countiesDropDown,
            ),
          );
        });
  }

  TypeAheadFormField<String> getCitiesFutureBuilder() {
    return TypeAheadFormField(
      textFieldConfiguration: TextFieldConfiguration(
        controller: this._cityFilter,
        decoration: InputDecoration(labelText: 'City'),
      ),
      suggestionsCallback: (String pattern) async {
        return await _getCitiesByPattern(pattern);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
      transitionBuilder: (context, suggestionsBox, controller) {
        return suggestionsBox;
      },
      onSuggestionSelected: (suggestion) {
        this._cityFilter.text = suggestion;
      },
      validator: (value) {
        if (value.isEmpty) {
          return 'Please select a city';
        }
      },
      onSaved: (value) => this._selectedCity = value,
    );
  }

  Future _getCounties() async {
    if (_counties.isEmpty) {
      return await new Post().getcounties();
    } else {
      return _counties;
    }
  }

  Future _getCities() async {
    if (_cities.isEmpty) {
      return await new Post().getcities(_county);
    } else {
      return _cities;
    }
  }

  FutureOr<List<String>> _getCitiesByPattern(String pattern) async {
    var cities = await _getCities();
    List<String> citiesByCounty = [];
    cities.cast<String>();
    citiesByCounty = cities.map<String>((value) {
      return value['nume'].toString();
    }).where((String value) {
      return pattern.length == 0 || value.toLowerCase().contains(pattern.toLowerCase());
    }).toList();

    return citiesByCounty;
  }
}
