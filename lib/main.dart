import 'package:cloud_firestore/cloud_firestore.dart';
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
// import 'package:firebase_storage/firebase_storage.dart';

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
      home: const HomePage(
        title: "Home Page",
        widgetIndex: 0,
      ),
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
  const HomePage({Key? key, required this.title, required this.widgetIndex})
      : super(key: key);
  final String title;
  final int widgetIndex;
  @override
  State<HomePage> createState() => _HomePageState();
}

int _selectedIndex = 0;
final List<Widget> _widgetTabs = <Widget>[
  Scaffold(
    body: Center(
      child: Container(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Text("Fantasy Soccer Wagering",
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 10),
                Text(
                    "Place wagers on simulated upcoming soccer games, and increase your token balance.",
                    style: TextStyle(fontSize: 20)),
              ]),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.purple, Colors.white]))),
    ),
  ),
  NewWager(storage: ProfileStorage()),
  Leaderboards(storage: ProfileStorage()),
  AccountPage(storage: ProfileStorage()),
];

class _HomePageState extends State<HomePage> {
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
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Log In",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 20),
                  SizedBox(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email)),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    width: 350,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.vpn_key)),
                        obscureText: true,
                        validator: (String? value) {
                          if (value!.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      width: 350),
                  const SizedBox(height: 10),
                  SizedBox(
                      width: 350,
                      child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _login();

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage(
                                            title: "Home",
                                            widgetIndex: 1,
                                          )));
                            }
                          },
                          child: const Text('Log In'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.purple,
                          ))),
                  const SizedBox(height: 5),
                  InkWell(
                      child: RichText(
                          text: const TextSpan(
                              text: "Don't have an account?",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 15),
                              children: <TextSpan>[
                            TextSpan(
                                text: ' Sign Up',
                                style: TextStyle(color: Colors.blue))
                          ])),
                      // Text("Don't have an account? Sign Up"),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SignUp(storage: ProfileStorage()))))
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
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text("Sign Up",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 10),
          Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email)),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    width: 350,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    child: TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_box)),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    width: 350,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.vpn_key)),
                      obscureText: true,
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    width: 350,
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                      child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _register();
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Submit',
                          )),
                      width: 350),
                ],
              ))
        ],
      ),
    ));
  }
}

class AccountPageState extends State<AccountPage> {
  User? user = _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return (StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _auth.signOut();
                    },
                    child: const Text("Log Out"),
                  ),
                ]);
          } else {
            return Login(storage: widget.storage);
          }
        }));
  }
}

class AccountPage extends StatefulWidget {
  AccountPage({Key? key, required this.storage}) : super(key: key);
  final ProfileStorage storage;
  User? user = _auth.currentUser;

  State<AccountPage> createState() => AccountPageState();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Leaderboards"),
        ),
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: <
            Widget>[
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
                        List<Tuple2<String, int>>? leaderboards = snapshot.data;
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
                              return Center(
                                  child: Card(
                                      child: Column(
                                children: [
                                  ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("${index + 1}."),
                                        Text("${leaderboards![index].item1}"),
                                        Text("  "),
                                        Text("${leaderboards[index].item2}"),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.attach_money,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              )));
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

enum ChosenTeam { home, away, tie }

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
    setState(() {
      _userBalance = widget.storage.getUserBalance(userID);
    });
    // }
  }

  Future<Map<String, double>> _getGameOdds(Wager wager, Match match) async {
    String apiKey =
        const String.fromEnvironment("API_KEY", defaultValue: "123");
    var headers = {
      "X-RapidAPI-Host": "api-football-v1.p.rapidapi.com",
      "X-RapidAPI-Key": apiKey
    };
    String matchID = match.id.toString();

    var endpoint = "/v3/odds?fixture=$matchID";
    var request = http.Request(
        'GET', Uri.parse('https://api-football-v1.p.rapidapi.com/$endpoint'));
    request.headers.addAll(headers);
    http.StreamedResponse streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    late Map<String, double> gameOdds;

    if (response.statusCode == 200) {
      final jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonResponse['results'] == 0) {
        gameOdds = {"homeWin": 100 / 3, "tie": 100 / 3, "awayWin": 100 / 3};
      } else {
        final bookmakers = jsonResponse['response'][0]['bookmakers'];
        var bookmaker = bookmakers[0];
        var bookmakerOdds = bookmaker['bets'][0]['values'];
        gameOdds = {
          "homeWin": double.parse(bookmakerOdds[0]['odd']),
          "tie": double.parse(bookmakerOdds[1]['odd']),
          "awayWin": double.parse(bookmakerOdds[2]['odd']),
        };
      }
    }
    return gameOdds;
  }

  Future<Map<dynamic, dynamic>> _simulateMatch(
      String userID, Wager wager, Match match) async {
    late int possiblePayout;
    String? userResultPrediction = wager.predictedWinner;
    print("PREDICTION: $userResultPrediction");
    Map<String, double> gameOdds = await _getGameOdds(wager, match);
    double? homeTeamWinOdds = gameOdds['homeWin'];
    double? awayTeamWinOdds = gameOdds['awayWin'];
    double? tieOdds = gameOdds['tie'];
    late Map<String, dynamic> matchResults = {};
    if (userResultPrediction == match.homeTeamName) {
      matchResults["possiblePayout"] =
          (homeTeamWinOdds! * wager.betAmount!.toDouble()).round().toInt();
    } else if (userResultPrediction == match.awayTeamName) {
      matchResults["possiblePayout"] =
          (awayTeamWinOdds! * wager.betAmount!.toDouble()).round().toInt();
    } else {
      matchResults["possiblePayout"] =
          (tieOdds! * wager.betAmount!.toDouble().round()).toInt();
    }
    print(matchResults['possiblePayout'].runtimeType);

    Random random = Random();
    double? homeWinHeuristic = random.nextInt(100) * awayTeamWinOdds!;
    double? awayWinHeuristic = random.nextInt(100) * homeTeamWinOdds!;
    double? tieHeuristic = random.nextInt(100) * tieOdds!;
    print("HOME TEAM: $homeWinHeuristic");
    print("AWAY TEAM: $awayWinHeuristic");
    print("TIE: $tieHeuristic");
    late int homeTeamGoals;
    late int awayTeamGoals;
    if (homeWinHeuristic > awayWinHeuristic &&
        homeWinHeuristic > tieHeuristic) {
      while (true) {
        homeTeamGoals = random.nextInt(5);
        awayTeamGoals = random.nextInt(5);
        if (homeTeamGoals > awayTeamGoals) {
          break;
        }
      }
      if (userResultPrediction == match.homeTeamName) {
        matchResults["userWonBool"] = true;
        print("YOU WON");
      } else {
        matchResults["userWonBool"] = false;
      }
    }
    // If Away team won
    else if (awayWinHeuristic > homeWinHeuristic &&
        awayWinHeuristic > tieHeuristic) {
      while (true) {
        homeTeamGoals = random.nextInt(5);
        awayTeamGoals = random.nextInt(5);
        if (homeTeamGoals < awayTeamGoals) {
          break;
        }
      }
      // If User predicted away team win
      if (userResultPrediction == match.awayTeamName) {
        print("YOU WON");
        matchResults["userWonBool"] = true;
      }
      // If user did not predict away team win
      else {
        matchResults["userWonBool"] = false;
      }
    }
    // If game ended in tie
    else {
      if (userResultPrediction == "tie") {
        matchResults["userWonBool"] = true;
      } else {
        matchResults["userWonBool"] = false;
      }
      while (true) {
        homeTeamGoals = random.nextInt(5);
        awayTeamGoals = random.nextInt(5);
        if (homeTeamGoals == awayTeamGoals) {
          break;
        }
      }
    }
    matchResults['homeTeamGoals'] = homeTeamGoals;
    matchResults['awayTeamGoals'] = awayTeamGoals;
    return matchResults;

    // widget.storage.updateUserBalance(userID, wager.betAmount);
  }

  void initState() {
    super.initState();
    if (_userSignedIn) {
      User? user = _auth.currentUser;
      final userID = user!.uid;
      _userBalance = widget.storage.getUserBalance(userID);
    }
  }

  bool _insufficientFunds = false;
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Match Details')),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: <
                    Widget>[
          FutureBuilder<int>(
              future: _userBalance,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Align(
                          alignment: Alignment.topRight,
                          child: RichText(
                              text: TextSpan(children: [
                            const WidgetSpan(
                              child: Icon(Icons.attach_money_sharp,
                                  color: Colors.green),
                            ),
                            TextSpan(
                              text: '${snapshot.data}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 25,
                              ),
                            )
                          ])));
                    }
                }
              }),
          Text("Home       Away"),
          Text(
            "${widget.matchHomeTeamName} vs. ${widget.matchAwayTeamName}",
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          Text("${widget.matchDateString}"),
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
            title: Text("Tie"),
            leading: Radio<ChosenTeam>(
              value: ChosenTeam.tie,
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
          Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Bet Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money_sharp)
                          // icon:
                          //     Icon(Icons.attach_money_sharp, color: Colors.green)),
                          ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (betAmountStr) {
                        bool good = true;
                        if (betAmountStr == null || betAmountStr.isEmpty) {
                          return 'Please enter a token amount';
                        }
                        User? user = _auth.currentUser;
                        final userID = user!.uid;
                        late int betAmountInt;
                        late int balance;
                        widget.storage.getUserBalance(userID).then((balance) {
                          balance = balance;
                          betAmountInt = int.parse(betAmountStr);
                          if (betAmountInt > balance) {
                            setState(() {
                              _insufficientFunds = true;
                              _formKey.currentState!.validate();
                            });
                          }
                        });
                        if (_insufficientFunds == true) {
                          return 'Insufficient tokens';
                        }
                        return null;
                      },
                    ),
                    width: 300.0,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          late String selectedTeamName;
                          if (_team == ChosenTeam.home) {
                            selectedTeamName = widget.matchHomeTeamName;
                          } else if (_team == ChosenTeam.tie) {
                            selectedTeamName = "tie";
                          } else {
                            selectedTeamName = widget.matchAwayTeamName;
                          }
                          String homeTeamName = widget.matchHomeTeamName;
                          String awayTeamName = widget.matchAwayTeamName;
                          int matchID = widget.matchID;
                          String matchDateString = widget.matchDateString;
                          DateTime matchDateObj = widget.matchDateObj;
                          final int amount = int.parse(_amountController.text);
                          User? user = _auth.currentUser;
                          final userID = user!.uid;
                          Match matchObj = Match(matchID, homeTeamName,
                              awayTeamName, matchDateString, matchDateObj);
                          Wager wagerObj =
                              Wager(amount, userID, selectedTeamName, matchID);
                          _saveWager(wagerObj, matchObj);
                          Map matchResults =
                              await _simulateMatch(userID, wagerObj, matchObj);
                          widget.storage.updateUserBalance(
                              userID, matchResults, wagerObj.betAmount);
                          // Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MatchResult(
                                      wager: wagerObj,
                                      match: matchObj,
                                      matchResults: matchResults,
                                      storage: widget.storage)));
                        }
                      },
                      child: const Text("Place Wager"))
                ],
              ))
        ])));
  }
}

class MatchResultState extends State<MatchResult> {
  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    final userID = user!.uid;
    _userBalance = widget.storage.getUserBalance(userID);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Results"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<int>(
              future: _userBalance,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Align(
                          alignment: Alignment.topRight,
                          child: RichText(
                              text: TextSpan(children: [
                            const WidgetSpan(
                              child: Icon(Icons.attach_money_sharp,
                                  color: Colors.green),
                            ),
                            TextSpan(
                              text: '${snapshot.data}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 25,
                              ),
                            )
                          ])));
                    }
                }
              }),
          const Text("Final Score",
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
              )),
          Text(
              "${widget.match.homeTeamName} ${widget.matchResults['homeTeamGoals']} - ${widget.matchResults['awayTeamGoals']} ${widget.match.awayTeamName}",
              style: const TextStyle(
                fontSize: 20,
              )),
          Text(() {
            if (widget.wager.predictedWinner == widget.match.homeTeamName) {
              return "You bet on ${widget.match.homeTeamName}";
            } else if (widget.wager.predictedWinner ==
                widget.match.awayTeamName) {
              return "You bet on ${widget.match.awayTeamName}";
            }
            return "You bet on a tie";
          }()),

          Text(() {
            if (widget.matchResults['userWonBool'] == true) {
              return "You won!";
            }
            return "You Lost :(";
          }()),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomePage(
                              title: "Home",
                              widgetIndex: 1,
                            )));
              },
              child: const Text('Place Another Wager'))
          // Text("${matchResults['userWonBool']}"),
        ],
      )),
    );
  }
}

class MatchResult extends StatefulWidget {
  const MatchResult({
    Key? key,
    required this.wager,
    required this.match,
    required this.matchResults,
    required this.storage,
  });
  final storage;
  final matchResults;
  final wager;
  final match;
  @override
  State<MatchResult> createState() => MatchResultState();
}

class _NewWagerState extends State<NewWager> {
  String apiKey = const String.fromEnvironment("API_KEY", defaultValue: "123");
  Future getGames(String league) async {
    print(league);
    var headers = {
      "X-RapidAPI-Host": "api-football-v1.p.rapidapi.com",
      "X-RapidAPI-Key": apiKey
    };
    final leagues = {
      "Premier League": '39',
      "La Liga": '140',
      "Serie A": '135',
      "Bundesliga": '78',
      "Ligue 1": '61',
      "MLS": '253'
    };
    String seasonYear = '2021';
    if (league == "MLS") seasonYear = '2022';

    final allLeagueGames = [];
    final String? requestedLeagueID = leagues[league];

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
        "/v3/fixtures?league=$requestedLeagueID&season=$seasonYear&from=$curDate&to=$inOneWeekDate";
    var request = http.Request(
        'GET', Uri.parse('https://api-football-v1.p.rapidapi.com/$endpoint'));
    request.headers.addAll(headers);
    http.StreamedResponse streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      final games = jsonResponse['response'];
      print(games);
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
                  automaticallyImplyLeading: false,
                ),
                body: Stack(children: <Widget>[
                  Center(
                      child: Column(
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
                                  return Align(
                                      alignment: Alignment(-0.8, -0.8),
                                      child: Container(
                                          child: RichText(
                                              text: TextSpan(children: [
                                        const WidgetSpan(
                                          child: Icon(Icons.attach_money_sharp,
                                              color: Colors.green),
                                        ),
                                        TextSpan(
                                          text: '${snapshot.data}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 25,
                                          ),
                                        )
                                      ]))));
                                }
                            }
                          }),
                    ],
                  )),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
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
                                'Ligue 1',
                                'MLS'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            )),
                        FutureBuilder<dynamic>(
                            future: getGames(dropdownValue),
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
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            SoccerMatch(
                                                                              storage: ProfileStorage(),
                                                                              matchID: snapshot.data[index]['fixture']['id'],
                                                                              matchHomeTeamName: snapshot.data[index]['teams']['home']['name'],
                                                                              matchAwayTeamName: snapshot.data[index]['teams']['away']['name'],
                                                                              matchDateString: snapshot.data[index]['fixture']['dateString'],
                                                                              matchDateObj: snapshot.data[index]['fixture']['dateObj'],
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
                  )
                ]));
          } else {
            return Login(storage: ProfileStorage());
          }
        });
  }
}
