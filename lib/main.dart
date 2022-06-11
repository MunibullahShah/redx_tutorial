import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:flutter_hooks/flutter_hooks.dart' as hooks;
import 'package:redx_tutorial/middleWareCode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SecondHomePage(),
    );
  }
}

enum ItemFilter { all, longText, shortText }

@immutable
class State {
  final Iterable<String> items;
  final ItemFilter filter;

  const State({
    required this.items,
    required this.filter,
  });

  Iterable<String> get filteredItems {
    switch (filter) {
      case ItemFilter.all:
        return items;
      case ItemFilter.longText:
        return items.where((element) => element.length >= 10);
      case ItemFilter.shortText:
        return items.where((element) => element.length <= 3);
    }
  }
}

@immutable
class ChangeFilterTypeAction extends Action {
  final ItemFilter filter;
  const ChangeFilterTypeAction(this.filter);
}

@immutable
abstract class Action {
  const Action();
}

@immutable
abstract class ItemAction extends Action {
  final String item;
  const ItemAction(this.item);
}

@immutable
class AddItemAction extends ItemAction {
  const AddItemAction(String item) : super(item);
}

@immutable
class RemoveItemAction extends ItemAction {
  const RemoveItemAction(String item) : super(item);
}

extension AddremoveItems<T> on Iterable<T> {
  Iterable<T> operator +(T other) => followedBy([other]);
  Iterable<T> operator -(T other) => where((element) => element != other);
}

Iterable<String> addItemReducer(
        Iterable<String> previousItems, AddItemAction action) =>
    previousItems + action.item;

Iterable<String> removeItemReducer(
        Iterable<String> previousItems, RemoveItemAction action) =>
    previousItems - action.item;

Reducer<Iterable<String>> itemsReducer = combineReducers<Iterable<String>>([
  TypedReducer<Iterable<String>, AddItemAction>(addItemReducer),
  TypedReducer<Iterable<String>, RemoveItemAction>(removeItemReducer),
]);

ItemFilter itemFilterReducer(State oldState, Action action) {
  if (action is ChangeFilterTypeAction) {
    return action.filter;
  } else {
    return oldState.filter;
  }
}

State appStateReducer(State oldState, action) => State(
    items: itemsReducer(oldState.items, action),
    filter: itemFilterReducer(oldState, action));

class MyHomePage extends hooks.HookWidget {
  @override
  Widget build(BuildContext context) {
    final store = Store(appStateReducer,
        initialState: State(items: [], filter: ItemFilter.all));

    final textController = hooks.useTextEditingController();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home Page"),
        ),
        body: StoreProvider(
          store: store,
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      store.dispatch(ChangeFilterTypeAction(ItemFilter.all));
                    },
                    child: Text("All"),
                  ),
                  TextButton(
                    onPressed: () {
                      store.dispatch(
                          ChangeFilterTypeAction(ItemFilter.shortText));
                    },
                    child: Text("Short items"),
                  ),
                  TextButton(
                    onPressed: () {
                      store.dispatch(
                          ChangeFilterTypeAction(ItemFilter.longText));
                    },
                    child: Text("Long items"),
                  ),
                ],
              ),
              TextField(
                controller: textController,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      store.dispatch(AddItemAction(textController.text));
                      textController.clear();
                    },
                    child: Text("Add"),
                  ),
                  TextButton(
                    onPressed: () {
                      store.dispatch(RemoveItemAction(textController.text));
                      textController.clear();
                    },
                    child: Text("Remove"),
                  ),
                ],
              ),
              StoreConnector<State, Iterable<String>>(
                  builder: (context, items) {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items.elementAt(index);
                          return ListTile(
                            title: Text(item),
                          );
                        },
                      ),
                    );
                  },
                  converter: (store) => store.state.filteredItems),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {}
}
