This package was developed to create a server while your flutter application is running.
Ex: imagine the following scenario, a desktop app with Sqlite database was developed and the need arises to create a mobile app to consume this same data, as long as it is on the same local network, this package is able to carry out this communication.
 
Note: Not tested in large applications.
Note: This server only works while the application is open.

### Features

- GET 
- POST 
- PUT
- DELETE

### Step - 1
----
Import the dependencies
```
import 'dart:io';
import 'package:mini_server/mini_server.dart';

```

### Step - 2
----
Create an instance
```
final miniServer = MiniServer(
    host: 'localhost',
    port: 8080,
  );

```

### Step - 3
----
Generate your routes
```
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

```

### Example
---
Note : 
If you want to test the example, replace the "localhost" with the current "IP" of the computer. Access your mobile browser on the url add your IP with the previously configured port, ex: 10.0.0.145:8080.
keep updating the page and see the counter increment.
```
 import 'dart:io';
import 'package:mini_server/mini_server.dart';
import 'package:flutter/material.dart';

ValueNotifier<int> value = ValueNotifier(0);
void main() {
  final miniServer = MiniServer(
    host: 'localhost',
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


```




