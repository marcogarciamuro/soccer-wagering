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
import 'package:intl/intl.dart';

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

class SoccerMatch extends StatefulWidget {
  // const HomePage({Key? key, required this.title}) : super(key: key);
  // final String title;
  // @override
  // State<HomePage> createState() => _HomePageState();
  const SoccerMatch(
      {Key? key,
      required this.storage,
      required this.matchID,
      required this.matchHomeTeamName,
      required this.matchAwayTeamName,
      required this.matchDateObj,
      required this.matchDateString})
      : super(key: key);
  final matchID;
  final storage;
  final matchHomeTeamName;
  final matchAwayTeamName;
  final matchDateString;
  final matchDateObj;

  State<SoccerMatch> createState() => _SoccerMatchState();
}

late Future<int> _userBalance;

enum ChosenTeam { home, away }

class _SoccerMatchState extends State<SoccerMatch> {
  late bool _validWager;
  final _formKey = GlobalKey<FormState>();
  String team = "Real Madrid";
  final _amountController = TextEditingController();
  ChosenTeam? _team = ChosenTeam.home;

  void _saveWager(Wager wager, Match match) async {
    User? user = _auth.currentUser;
    final userID = user!.uid;
    print("PROCESSING WAGER");
    // save game details
    await widget.storage.saveGame(match);
    // if (wager.betAmount! > await widget.storage.getUserBalance(userID)) {
    //   _validWager = false;
    //   print("NOT ENOUGH TOKENS");
    // } else {
    print("WAGER IS VALID");
    widget.storage.saveWager(wager);
    _simulateMatch(userID, team, wager.betAmount);
    setState(() {
      _userBalance = widget.storage.getUserBalance(userID);
    });
    // }
  }

  void _simulateMatch(String userID, String userTeam, int? amount) {
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
      print("YOU LOST :(");
    } else {
      print("YOU WON :)");
    }
    widget.storage.updateUserBalance(userID, amount);
  }

  void initState() {
    super.initState();
    if (_userSignedIn) {
      User? user = _auth.currentUser;
      final userID = user!.uid;
      _userBalance = widget.storage.getUserBalance(userID);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Match Details')),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
              Text("Home       Away"),
              Text(
                  "${widget.matchHomeTeamName} vs. ${widget.matchAwayTeamName}"),
              Text("${widget.matchDateString}"),
              Text("${widget.matchID}"),
              ListTile(
                title: Text("${widget.matchHomeTeamName}"),
                leading: Radio<ChosenTeam>(
                  value: ChosenTeam.home,
                  groupValue: _team,
                  onChanged: (ChosenTeam? value) {
                    setState(() {
                      _team = value;
                    });
                  },
                ),
              ),
              ListTile(
                title: Text("${widget.matchAwayTeamName}"),
                leading: Radio<ChosenTeam>(
                  value: ChosenTeam.away,
                  groupValue: _team,
                  onChanged: (ChosenTeam? value) {
                    setState(() {
                      _team = value;
                    });
                  },
                ),
              ),
              SizedBox(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount',
                      icon: Icon(Icons.attach_money_sharp)),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a token amount';
                    } else {
                      print("ALL GOOD");
                    }
                    return null;
                  },
                ),
                width: 500.0,
              ),
              ElevatedButton(
                  //   if (_team == ChosenTeam.home) {

                  //     print("${widget.matchHomeTeamName}");
                  //     print(_amountController.text);
                  //   } else {
                  //     print("${widget.matchAwayTeamName}");
                  //     print(_amountController.text);
                  //   }
                  // },
                  onPressed: () async {
                    late String selectedTeamName;
                    if (_team == ChosenTeam.home) {
                      selectedTeamName = widget.matchHomeTeamName;
                    } else
                      selectedTeamName = widget.matchAwayTeamName;
                    String homeTeamName = widget.matchHomeTeamName;
                    String awayTeamName = widget.matchAwayTeamName;
                    int matchID = widget.matchID;
                    String matchDateString = widget.matchDateString;
                    DateTime matchDateObj = widget.matchDateObj;
                    final int amount = int.parse(_amountController.text);
                    User? user = _auth.currentUser;
                    final userID = user!.uid;
                    Match matchObj = Match(matchID, homeTeamName, awayTeamName,
                        matchDateString, matchDateObj);
                    Wager wagerObj =
                        Wager(amount, userID, selectedTeamName, matchID);
                    _saveWager(wagerObj, matchObj);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                NewWager(storage: ProfileStorage())));
                  },
                  child: Text("Place Wager"))
            ])));
  }
}

class _NewWagerState extends State<NewWager> {
  String apiKey = const String.fromEnvironment("API_KEY", defaultValue: "123");
  Future getGames() async {
    var headers = {
      "X-RapidAPI-Host": "api-football-v1.p.rapidapi.com",
      "X-RapidAPI-Key": apiKey
    };
    final leagues = {
      "Premier League": 39,
      "La Liga": 140,
      "Serie A": 135,
      "Bundesliga": 78,
      "Ligue 1": 61,
    };

    final allLeagueGames = [];

    // for(int leagueID in leagues.values)
    // var endpoint = "/v3/fixtures?date=2022-04-30&league=$leagueID&season=2021";
    // allLeagueGames[]

    DateTime now = DateTime.now();
    DateTime datetime = DateTime(now.year, now.month, now.day);
    String curDate = datetime.toString().replaceAll(" 00:00:00.000", "");
    DateTime inOneWeekDateTime = datetime.add(const Duration(days: 7));
    String inOneWeekDate =
        inOneWeekDateTime.toString().replaceAll(" 00:00:00.000", "");

    var endpoint =
        "/v3/fixtures?league=39&season=2021&from=$curDate&to=$inOneWeekDate";
    var request = http.Request(
        'GET', Uri.parse('https://api-football-v1.p.rapidapi.com/$endpoint'));
    request.headers.addAll(headers);
    http.StreamedResponse streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      final games = jsonResponse['response'];
      var gamesCleaned = [];
      for (var game in games) {
        var rawGameDate = game['fixture']['date'];
        DateTime gameDateObj = DateTime.parse(rawGameDate);
        DateTime localGameDateObj = gameDateObj.toLocal();
        String localGameDateStringFormatted =
            DateFormat('MMMM d, hh:mm a').format(localGameDateObj);
        game['fixture']['dateString'] = localGameDateStringFormatted;
        if (game['fixture']['status']['long'] == "Not Started") {
          game['fixture']['dateObj'] = localGameDateObj;
          gamesCleaned.add(game);
        }
      }
      return gamesCleaned;
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

  String? textValidator(value) {
    print("VALIDATING TEXT");
    if (value == null || value.isEmpty) {
      return "Please enter a wager amount";
    }
    return null;
  }

  int _selectedMatchID = 0;
  String _selectedMatchHomeTeamName = "";
  String _selectedMatchAwayTeamName = "";
  String _selectedMatchDate = "";

  String dropdownValue = 'Premier League';
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<int>(
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
                                    return Text(
                                      'Balance: ${snapshot.data}',
                                      style: TextStyle(fontSize: 20),
                                    );
                                  }
                              }
                            }),
                      ),
                      Align(
                          alignment: Alignment.topRight,
                          child: DropdownButton<String>(
                            value: dropdownValue,
                            icon: const Icon(Icons.keyboard_arrow_down_sharp),
                            elevation: 16,
                            underline: Container(
                                height: 2, color: Colors.deepPurpleAccent),
                            onChanged: (String? newValue) {
                              setState(() {
                                dropdownValue = newValue!;
                              });
                            },
                            items: <String>[
                              'Premier League',
                              'La Liga',
                              'Serie A',
                              'Bundesliga',
                              'Ligue 1'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          )),
                      FutureBuilder<dynamic>(
                          future: getGames(),
                          // if(dropdownValue == "Ligue 1") ... return getGames(),
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
                                              Expanded(
                                                  child: Card(
                                                      child: Column(
                                                children: [
                                                  ListTile(
                                                    title: Text(
                                                        "${snapshot.data[index]['teams']['home']['name']} vs ${snapshot.data[index]['teams']['away']['name']}"),
                                                    subtitle: Text(
                                                        "${snapshot.data[index]['fixture']['dateString']}"),
                                                    trailing: ElevatedButton(
                                                        onPressed: () {
                                                          // _selectedMatchAwayTeamName =
                                                          //     snapshot.data[
                                                          //                 index]
                                                          //             ['teams'][
                                                          //         'away']['name'];
                                                          // _selectedMatchHomeTeamName =
                                                          //     snapshot.data[
                                                          //                 index]
                                                          //             ['teams'][
                                                          //         'away']['name'];
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          SoccerMatch(
                                                                            storage:
                                                                                ProfileStorage(),
                                                                            matchID:
                                                                                snapshot.data[index]['fixture']['id'],
                                                                            matchHomeTeamName:
                                                                                snapshot.data[index]['teams']['home']['name'],
                                                                            matchAwayTeamName:
                                                                                snapshot.data[index]['teams']['away']['name'],
                                                                            matchDateString:
                                                                                snapshot.data[index]['fixture']['dateString'],
                                                                            matchDateObj:
                                                                                snapshot.data[index]['fixture']['dateObj'],
                                                                          )));
                                                        },
                                                        child: const Text(
                                                            "Bet on Match")),
                                                  ),
                                                ],
                                              )))
                                            ]);
                                          }));
                                }
                            }
                          })
                    ],
                  ),
                ));
          } else {
            return Login(storage: ProfileStorage());
          }
        });
  }
}
