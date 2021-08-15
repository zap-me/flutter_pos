import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'dart:convert';


void main() {
  const URL_BASE = "https://mtoken-test.zap.me/";
  const WS_URL = "https://mtoken-test.zap.me/paydb";
  setLocalStorage();
  runApp(MyApp());
}

int nonce() {
  return ((DateTime.now().millisecondsSinceEpoch) / 1000).floor();
}

String sign(data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var secretBytes = utf8.encode(prefs.getString('secret'));
  var nonceBytes = utf8.encode(data);
  Hmac hmacSha256 = Hmac(sha256, secretBytes);
  Digest bytesDigest = hmacSha256.convert(nonceBytes);
  String base65Hmac = base64.encode(bytesDigest.bytes);
  return base64Hmac;
}

Future<void> setLocalStorage() async {
  // Test localstorage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_key', 'bgPfjilKLfk');
  await prefs.setString('secret', 'Zw_EayWw_CZ0M-L3ril9uA');
  await prefs.setString('asset-ticker','FRT');
  int nonceRes = nonce();
  await prefs.setInt('nonce', nonceRes);
}

Future<void> postPayDb(String endpoint, Map<String, String> params) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  params['api_key'] = await prefs.getString('api_key') ?? "";
  params['nonce'] = nonce().toString();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '💳'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
	    Row(
              mainAxisAlignment: MainAxisAlignment.center,
	      children: <Widget>[
		Container(
                  child: Text("↙️", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
                  alignment: Alignment.center,
		  width: 180.0,
		  height: 180.0,
                  color: Colors.blue,
		),
		SizedBox(width: 100),
		Container(
                  child: Text("↗️", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
                  alignment: Alignment.center,
		  width: 180.0,
		  height: 180.0,
                  color: Colors.blue,
		),
	      ]
	    ),
            SizedBox(height: 100),
	    Row(
              mainAxisAlignment: MainAxisAlignment.center,
	      children: <Widget>[
		Container(
                  child: Text("🎁", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
                  alignment: Alignment.center,
		  width: 180.0,
		  height: 180.0,
                  color: Colors.blue,
		),
		SizedBox(width: 100),
		Container(
                  child: Text("⚙️", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
                  alignment: Alignment.center,
		  width: 180.0,
		  height: 180.0,
                  color: Colors.blue,
		),
	      ],
	    ),
          ],
            ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
