import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

const apiURL = "https://simple-books-api.glitch.me/books";

@immutable
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  Person.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        age = json["id"] as int;

  String toString() => "Person ($name, $age years old)";
}

Future<Iterable<Person>> getPersons() => HttpClient()
    .getUrl(Uri.parse(apiURL))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
abstract class Action {
  const Action();
}

@immutable
class LoadPeopleAction extends Action {
  const LoadPeopleAction();
}

@immutable
class SuccessfullyFetchedPeople extends Action {
  final Iterable<Person> persons;
  const SuccessfullyFetchedPeople({required this.persons});
}

@immutable
class FailedToFetchPeople extends Action {
  final Object error;
  const FailedToFetchPeople({required this.error});
}

@immutable
class State {
  final bool isLoading;
  final Iterable<Person>? fetchedPersons;
  final Object? error;

  State(
      {required this.isLoading,
      required this.fetchedPersons,
      required this.error});
  const State.empty()
      : isLoading = false,
        fetchedPersons = null,
        error = null;
}

State reducer(State oldState, action) {
  final NextDispatcher bla;
  if (action is LoadPeopleAction) {
    return State(error: null, fetchedPersons: null, isLoading: true);
  } else if (action is SuccessfullyFetchedPeople) {
    return State(error: null, fetchedPersons: action.persons, isLoading: false);
  } else if (action is FailedToFetchPeople) {
    return State(
      error: action.error,
      fetchedPersons: oldState.fetchedPersons,
      isLoading: false,
    );
  } else {
    return oldState;
  }
}

void loadPeopleMiddleware(
  Store<State> store,
  action,
  NextDispatcher next,
) {
  if (action is LoadPeopleAction) {
    getPersons().then((persons) {
      store.dispatch(SuccessfullyFetchedPeople(persons: persons));
    }).catchError((e) {
      store.dispatch(FailedToFetchPeople(error: e));
    });
  }
  next(action);
}

class SecondHomePage extends StatelessWidget {
  const SecondHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Store(
      reducer,
      initialState: State.empty(),
      middleware: [loadPeopleMiddleware],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
      ),
      body: StoreProvider(
        store: store,
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                store.dispatch(LoadPeopleAction());
              },
              child: Text("LoadPersons"),
            ),
            StoreConnector<State, bool>(
              converter: (store) => store.state.isLoading,
              builder: (context, isLoading) {
                if (isLoading) {
                  return CircularProgressIndicator();
                } else
                  return SizedBox();
              },
            ),
            StoreConnector<State, Iterable<Person>?>(
              converter: (store) => store.state.fetchedPersons,
              builder: (context, people) {
                if (people == null) {
                  return SizedBox();
                }
                return Expanded(
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text("${people.elementAt(index).name}"),
                        subtitle: Text("Age: ${people.elementAt(index).age}"),
                      );
                    },
                    itemCount: people.length,
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
