import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:soccer_wagering/firebase_config.dart';
import 'package:soccer_wagering/main.dart';
import 'package:tuple/tuple.dart';

class Match {
  int? id;
  String? homeTeamName;
  String? awayTeamName;
  String? dateTimeString;
  DateTime? dateTimeObj;
  String? winningTeam;
  Match(this.id, this.homeTeamName, this.awayTeamName, this.dateTimeString,
      this.dateTimeObj);
}

class Wager {
  int? betAmount;
  String? userID;
  String? predictedWinner;
  int? matchID;
  Wager(this.betAmount, this.userID, this.predictedWinner, this.matchID);
}

class ProfileStorage {
  bool _initialized = false;

  Future<void> initializeDefault() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseConfig.platformOptions);
    _initialized = true;
  }

  ProfileStorage() {
    initializeDefault();
  }

  Future<bool> createProfile(String userID, String username) async {
    if (!_initialized) {
      await initializeDefault();
    }
    // ADD FUNCTIONALITY TO ENSURE USERNAMES ARE UNIQUE =====****)))))&&&&&&
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore
        .collection('profiles')
        .doc(userID)
        .set({'username': username, 'tokens': 5000})
        .then((value) => print("Profile created"))
        .catchError((error) => print("Failed to create profile"));
    return true;
  }

  Future<bool> saveGame(Match match) async {
    if (!_initialized) {
      await initializeDefault();
    }
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore
        .collection('games')
        .doc(match.id.toString())
        .set({
          'homeTeam': match.homeTeamName,
          'awayTeam': match.awayTeamName,
          'id': match.id,
          'dateTimeString': match.dateTimeString,
          'dateTimeObj': match.dateTimeObj,
          'winner': ""
        })
        .then((value) => print("Game created"))
        .catchError((error) => print("Failed to create game"));
    return true;
  }

  // Future<bool> saveWager(Wager wager)
  Future<bool> saveWager(Wager wager) async {
    print("In save wager");
    if (!_initialized) {
      await initializeDefault();
    }
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    final gameDocRef =
        firestore.collection('games').doc(wager.matchID.toString());
    firestore
        .collection('profiles')
        .doc(wager.userID)
        .collection('wagers')
        .add({
          'predictedWinner': wager.predictedWinner,
          'game': gameDocRef,
          'amount': wager.betAmount,
        })
        .then((value) => print("Wager Saved"))
        .catchError((error) => print("Failed to update count: $error"));
    print("AFTER");
    return true;
  }

  Future<String> getUserName(String userID) async {
    if (!_initialized) {
      await initializeDefault();
    }
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot value =
        await firestore.collection('profiles').doc(userID).get();
    Map<String, dynamic>? data = (value.data()) as Map<String, dynamic>?;
    return data!['username'];
  }

  Future<bool> updateUserBalance(
      String userID, Map<dynamic, dynamic> matchResults, int amount) async {
    print("Updating balance");
    if (!_initialized) {
      await initializeDefault();
    }
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userDoc = firestore.collection('profiles').doc(userID);
    if (matchResults['userWonBool'] == true) {
      print("POSSIBLE PAYOUT");
      userDoc
          .update(
              {'tokens': FieldValue.increment(matchResults['possiblePayout'])})
          .then((value) => print("Tokens updated"))
          .catchError((error) => print("Failed to update tokens: $error"));
    } else {
      userDoc
          .update({'tokens': FieldValue.increment(-amount)})
          .then((value) => print("Tokens updated"))
          .catchError((error) => print("Failed to update tokens: $error"));
    }
    print("AFTER");
    return true;
  }

  Future<int> getUserBalance(String userID) async {
    print("GETTING USRE BALANCE");
    if (!_initialized) {
      await initializeDefault();
    }
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot value =
        await firestore.collection('profiles').doc(userID).get();
    Map<String, dynamic>? data = (value.data()) as Map<String, dynamic>?;
    print("HELLOERll");
    print(data!['tokens']);
    print("BYE");
    return data['tokens'];
    // return 0;
  }

  Future<List<Tuple2<String, int>>> getLeaderboards() async {
    if (!_initialized) {
      await initializeDefault();
    }
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference _profilesColl = firestore.collection('profiles');
    QuerySnapshot querySnapshot = await _profilesColl.get();
    final List<DocumentSnapshot> profileDocs = querySnapshot.docs;
    Map<String, int> unsortedLeaderboardMap = {};
    List<Tuple2<String, int>> leaderboardList = [];
    for (var profile in profileDocs) {
      Map<String, dynamic>? profileData =
          (profile.data() as Map<String, dynamic>?);
      // unsortedLeaderboard[profile.id] = profileData!["tokens"];
      unsortedLeaderboardMap[profileData!["username"]] = profileData["tokens"];
      var item = Tuple2<String, int>(
          profileData["username"].toString(), profileData["tokens"] as int);
      leaderboardList.add(item);
    }
    leaderboardList.sort((a, b) => b.item2.compareTo(a.item2));
    print(leaderboardList);
    return leaderboardList;
  }
}
