import 'dart:io';
import 'package:mini_server/mini_server.dart';
import 'package:flutter/material.dart';

ValueNotifier<int> value = ValueNotifier(0);
void main() {
  final miniServer = MiniServer(
    host: '10.0.0.146',
    port: 8080,
  );

  miniServer.get("/", (HttpRequest httpRequest) async {
    value.value++;
    return httpRequest.response.write(value.value);
  });

  miniServer.post("/test", (HttpRequest httpRequest) async {
    final res = await MiniResponse().init(httpRequest);
    return httpRequest.response.write(res.parameters);
  });

  miniServer.post("/test02", (HttpRequest httpRequest) async {
    final res = await MiniResponse().init(httpRequest);
    return httpRequest.response.write(res.body);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: value,
        builder: (_, value, __) {
          return Center(
            child: Text(
              "$value",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 100,
              ),
            ),
          );
        },
      ),
    );
  }
}
