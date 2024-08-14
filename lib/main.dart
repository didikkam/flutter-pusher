import 'package:flutter/material.dart';
import 'package:flutter_chat/models/Todo.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final String apiKey = ''; // Ganti dengan kunci API Anda
  final String cluster = 'ap1'; // Ganti dengan cluster Anda
  final String channelName = 'todos'; // Nama channel yang digunakan
  final String eventName = 'todo.updated'; // Nama event yang digunakan

  List<Todo> todos = [];

  @override
  void initState() {
    super.initState();
    initPusher();
  }

  void initPusher() async {
    try {
      await pusher.init(
        apiKey: apiKey,
        cluster: cluster,
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
      );
      await pusher.subscribe(channelName: channelName);
      await pusher.connect();
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("Connection state: $currentState");
  }

  void onError(String message, int? code, dynamic e) {
    print("Error: $message code: $code exception: $e");
  }

  void onEvent(PusherEvent event) {
    print("Event received: ${event.data}");
    try {
      // Decode JSON string menjadi Map
      final Map<String, dynamic> data = jsonDecode(event.data as String);

      // Ambil todo dari data
      final todo = Todo.fromJson(data['todo']);
      setState(() {
        final index = todos.indexWhere((t) => t.id == todo.id);
        if (index >= 0) {
          todos[index] = todo;
        } else {
          todos.add(todo);
        }
      });
    } catch (e) {
      print("Failed to parse event data: $e");
    }
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("Subscription succeeded: $channelName");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return ListTile(
            title: Text(todo.name),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    pusher.unsubscribe(channelName: channelName);
    pusher.disconnect();
    super.dispose();
  }
}
