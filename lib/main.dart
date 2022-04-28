import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:soccer_wagering/storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
import "dart:math";
import "package:tuple/tuple.dart";
import "package:http/http.dart" as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert' as convert;

final FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseApp wageringApp = Firebase.app('Fantasy Soccer Wagering');
late bool _userSignedIn;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _auth.authStateChanges().listen((User? user) {
    if (user == null) {
      _userSignedIn = false;
      print('user is currently signed out!');
    } else {
      _userSignedIn = true;
      print('user is signed in!');
    }
  });
  runApp(const SoccerWagering());
}

class SoccerWagering extends StatelessWidget {
  const SoccerWagering({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // return Scaffold(
      title: 'Soccer Wagering',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: "Home Page"),
      initialRoute: '/',
      routes: {
        '/sign-up': (context) => SignUp(storage: ProfileStorage()),
        '/login': (context) => Login(storage: ProfileStorage()),
        '/new-wager': (context) => NewWager(
              storage: ProfileStorage(),
            ),
        '/leaderboards': (context) => Leaderboards(storage: ProfileStorage()),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  // static const TextStyle optionStyle =
  //     TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  final List<Widget> _widgetTabs = <Widget>[
    Text("Home Page"),
    NewWager(storage: ProfileStorage()),
    Leaderboards(storage: ProfileStorage()),
    AccountPage(storage: ProfileStorage()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetTabs.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Wager',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        onTap: _onItemTapped,
      ),
      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: [
      //       const DrawerHeader(
      //         decoration: BoxDecoration(
      //           color: Colors.blue,
      //         ),
      //         child: Text('Drawer Header'),
      //       ),
      //       // _userSignedIn
      //       //     ? ListTile(
      //       //         title: const Text('Log Out'),
      //       //         onTap: () async {
      //       //           _userSignedIn = false;
      //       //           await FirebaseAuth.instance.signOut();
      //       //           // Navigator.pushNamed(context, '/logout');
      //       //         },
      //       //       )
      //       //     : ListTile(
      //       //         title: const Text('Log In'),
      //       //         onTap: () {
      //       //           Navigator.pushNamed(context, '/sign-up');
      //       //         },
      //       //       ),
      //       ListTile(
      //         title: const Text('Log In'),
      //         onTap: () {
      //           Navigator.pushNamed(context, '/login');
      //         },
      //       ),
      //       ListTile(
      //         title: const Text('Sign Up'),
      //         onTap: () {
      //           Navigator.pushNamed(context, '/sign-up');
      //         },
      //       ),
      //       ListTile(
      //         title: const Text('New Wager'),
      //         onTap: () {
      //           Navigator.pushNamed(context, '/new-wager');
      //         },
      //       ),
      //       ListTile(
      //         title: const Text('Leaderboards'),
      //         onTap: () {
      //           Navigator.pushNamed(context, '/leaderboards');
      //         },
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}

class Login extends StatelessWidget {
  Login({Key? key, required this.storage}) : super(key: key);
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ProfileStorage storage;

  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Log In'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (String? value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (String? value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                        child: const Text('Log In'),
                      ),
                    ],
                  )),
            ],
          ),
        ));
  }
}

class SignUp extends StatelessWidget {
  SignUp({Key? key, required this.storage}) : super(key: key);
  final ProfileStorage storage;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    String username = _usernameController.text;
    try {
      await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((cred) {
        storage.createProfile(cred.user!.uid, username);
        return true;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Sign Up'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // children: const <Widget>[Text("Hello")]))
            children: <Widget>[
              Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (String? value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(labelText: 'Username'),
                        validator: (String? value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (String? value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _register();
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ))
            ],
          ),
        ));
  }
}

class AccountPage extends StatelessWidget {
  AccountPage({Key? key, required this.storage}) : super(key: key);
  final ProfileStorage storage;

  @override
  Widget build(BuildContext context) {
    return (StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ElevatedButton(
              onPressed: () {
                _auth.signOut();
              },
              child: Text("Log Out"),
            );
          } else {
            return Login(storage: storage);
          }
        }));
  }
}

class Leaderboards extends StatefulWidget {
  const Leaderboards({Key? key, required this.storage}) : super(key: key);
  final ProfileStorage storage;
  @override
  State<Leaderboards> createState() => _LeaderboardsState();
}

class _LeaderboardsState extends State<Leaderboards> {
  User? user = _auth.currentUser;
  late Future<List<Tuple2<String, int>>> _leaderboard;

  @override
  void initState() {
    super.initState();
    _leaderboard = widget.storage.getLeaderboards();
    // print(_leaderboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Leaderboards"),
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<List<Tuple2<String, int>>>(
                  future: _leaderboard,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Tuple2<String, int>>> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return const CircularProgressIndicator();
                      default:
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          if (snapshot.data != null) {
                            List<Tuple2<String, int>>? leaderboards =
                                snapshot.data;
                            print(leaderboards);
                            if (leaderboards != null) {
                              for (var entry in leaderboards) {
                                // print(entry.runtimeType);
                                print(entry.item1);
                              }
                            }
                            return ListView.builder(
                                // itemCount: _lea
                                shrinkWrap: true,
                                itemCount: leaderboards?.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                      child: Center(
                                    child: Text(
                                        "${leaderboards![index].item1} : ${leaderboards[index].item2} tokens"),
                                  ));
                                  // child: Center(child: Text("$index"),)
                                });
                          }
                          return Text("NO DATA");
                        }
                    }
                  }),
            ]));
  }
}

class NewWager extends StatefulWidget {
  const NewWager({Key? key, required this.storage}) : super(key: key);

  final ProfileStorage storage;
  @override
  State<NewWager> createState() => _NewWagerState();
}

class _NewWagerState extends State<NewWager> {
  late bool _validWager;
  late Future<int> _userBalance;
  String team = "Real Madrid";
  final _amountController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String apiKey = const String.fromEnvironment("API_KEY", defaultValue: "123");
  Future getGames() async {
    var headers = {
      "X-RapidAPI-Host": "api-football-v1.p.rapidapi.com",
      "X-RapidAPI-Key": apiKey
    };
    var endpoint = "/v3/fixtures?date=2022-04-30&league=39&season=2021";
    var request = http.Request(
        'GET', Uri.parse('https://api-football-v1.p.rapidapi.com/$endpoint'));
    request.headers.addAll(headers);
    http.StreamedResponse streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // var request = await http.get(url, headers: {
    if (response.statusCode == 200) {
      final jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      final games = jsonResponse['response'];
      return games;
      // for (var game in games) {
      //   print(game['teams']['home']['name'] +
      //       ' vs. ' +
      //       game['teams']['away']['name']);
      // }
      // print(jsonResponse['response']);
      // var jsonResponse = await response.stream.print(jsonResponse);
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }

  @override
  void initState() {
    super.initState();
    if (_userSignedIn) {
      User? user = _auth.currentUser;
      final userID = user!.uid;
      _userBalance = widget.storage.getUserBalance(userID);
    }
  }

  void _processWager() async {
    print("PROCESSING WAGER");
    final int amount = int.parse(_amountController.text);
    if (_formKey.currentState!.validate()) {
      User? user = _auth.currentUser;
      final userID = user!.uid;
      if (amount > await widget.storage.getUserBalance(userID)) {
        _validWager = false;
        print("NOT ENOUGH TOKENS");
      } else {
        print("WAGER IS VALID");
        widget.storage.saveWager(userID, team, amount);
        _simulateMatch(userID, team, amount);
        setState(() {
          _userBalance = widget.storage.getUserBalance(userID);
        });
      }
    } else {
      print("INVALID INPUT");
      _validWager = false;
    }
  }

  void _simulateMatch(String userID, String userTeam, int amount) {
    final _teams = [
      "Real Madrid",
      "Manchester United",
      "Borussia Dortmund",
      "Juventus",
    ];
    String _opponent;
    while (true) {
      _opponent = (_teams..shuffle()).first;
      if (_opponent != userTeam) {
        break;
      }
    }
    Random random = Random();
    final _opponentOdds = random.nextInt(100);
    final _userOdds = random.nextInt(100);
    print("USER ODDS: $_userOdds");
    print("OPPONENT ODDS: $_opponentOdds");
    if (_opponentOdds > _userOdds) {
      amount *= -1;
      print("YOU LOST :(");
    } else {
      print("YOU WON :)");
    }
    widget.storage.updateUserBalance(userID, amount);
  }

  String? textValidator(value) {
    print("VALIDATING TEXT");
    if (value == null || value.isEmpty) {
      return "Please enter a wager amount";
    }
    return null;
  }

  String dropdownValue = 'Real Madrid';
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: const Text("Place Wager"),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FutureBuilder<int>(
                          future: _userBalance,
                          builder: (BuildContext context,
                              AsyncSnapshot<int> snapshot) {
                            switch (snapshot.connectionState) {
                              case ConnectionState.waiting:
                                return const CircularProgressIndicator();
                              default:
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return Text('BALANCE: ${snapshot.data}');
                                }
                            }
                          }),
                      FutureBuilder<dynamic>(
                          future: getGames(),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            switch (snapshot.connectionState) {
                              case ConnectionState.waiting:
                                return const CircularProgressIndicator();
                              default:
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return Expanded(
                                      child: ListView.builder(
                                          itemCount: snapshot.data.length,
                                          itemBuilder: (context, index) {
                                            return Row(children: <Widget>[
                                              ElevatedButton(
                                                  onPressed: () {},
                                                  child: Text(snapshot
                                                          .data[index]['teams']
                                                      ['home']['name'])),
                                              Text("Vs."),
                                              ElevatedButton(
                                                  onPressed: () {},
                                                  child: Text(snapshot
                                                          .data[index]['teams']
                                                      ['away']['name'])),
                                            ]);
                                          }));
                                }
                            }
                          })
                      // Form(
                      //   key: _formKey,
                      //   child: Column(
                      //     children: <Widget>[
                      //       DropdownButtonFormField<String>(
                      //         decoration: const InputDecoration(
                      //             labelText: 'Team',
                      //             icon: Icon(Icons.groups_sharp)),
                      //         value: dropdownValue,
                      //         icon: const Icon(Icons.keyboard_arrow_down_sharp),
                      //         elevation: 16,
                      //         onChanged: (String? newValue) {
                      //           setState(() {
                      //             team = newValue!;
                      //             dropdownValue = newValue;
                      //           });
                      //         },
                      //         items: <String>[
                      //           'Real Madrid',
                      //           'Manchester United',
                      //           'Borussia Dortmund',
                      //           'Juventus'
                      //         ].map<DropdownMenuItem<String>>((String value) {
                      //           return DropdownMenuItem<String>(
                      //             value: value,
                      //             child: Text(value),
                      //           );
                      //         }).toList(),
                      //       ),
                      //       SizedBox(
                      //         child: TextFormField(
                      //           controller: _amountController,
                      //           keyboardType: TextInputType.number,
                      //           decoration: const InputDecoration(
                      //               labelText: 'Amount',
                      //               icon: Icon(Icons.attach_money_sharp)),
                      //           inputFormatters: [
                      //             FilteringTextInputFormatter.digitsOnly
                      //           ],
                      //           validator: (value) {
                      //             if (value!.isEmpty) {
                      //               return 'Please enter a token amount';
                      //             } else {
                      //               print("ALL GOOD");
                      //             }
                      //             return null;
                      //           },
                      //         ),
                      //         width: 500.0,
                      //       ),
                      //       ElevatedButton(
                      //         onPressed: () async {
                      //           if (_formKey.currentState!.validate()) {
                      //             _processWager();
                      //           }
                      //         },
                      //         // ElevatedButton(
                      //         //     onPressed: () async {
                      //         //       if (_formKey.currentState!.validate()) {
                      //         //         _register();
                      //         //       }
                      //         //     },
                      //         //     child: const Text('Submit'),
                      //         //   ),
                      //         child: const Text('Submit'),
                      //       ),
                      //       // _validWager == true
                      //       //     ? const Text("NOT ENOUGH TOKENS")
                      //       //     : const Text("VALID"),

                      //       // if(_validWager == true) {
                      //       //   Text: ("NOT ENOUGH TOKENS");
                      //       // },
                      //     ],
                      //   ),
                      // ),
                      // Form(
                      //     key: _formKey,
                      //     child: Column(
                      //       children: <Widget>[
                      //         // Add TextFormFields and ElevatedButton here.
                      //         Container(
                      //           child: TextFormField(
                      //             controller: _amountController,
                      //             // The validator receives the text that the user has entered.
                      //             validator: textValidator,
                      //           ),
                      //           width: 500.0,
                      //         ),
                      //         ElevatedButton(
                      //           onPressed: _processWager,
                      //           child: const Text('Submit'),
                      //         ),
                      //       ],
                      //     )),
                    ],
                  ),
                ));
          } else {
            return Login(storage: ProfileStorage());
          }
        });
  }
}
