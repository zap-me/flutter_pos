import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'dart:convert';

const URL_BASE = "https://mtoken-test.zap.me/";
const WS_URL = "https://mtoken-test.zap.me/paydb";

void main() {
  setLocalStorage();
  runApp(MyApp());
}

int nonce() {
  return ((DateTime.now().millisecondsSinceEpoch) / 1000).floor();
}

Future<String> sign(data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var secretBytes = utf8.encode(prefs.getString('secret') ?? "");
  var messageBytes = utf8.encode(data);
  Hmac hmacSha256 = Hmac(sha256, secretBytes);
  Digest bytesDigest = hmacSha256.convert(messageBytes);
  String base64Hmac = base64.encode(bytesDigest.bytes);
  return base64Hmac;
}

Future<void> setLocalStorage() async {
  // Test localstorage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_key', 'XX');
  await prefs.setString('secret', 'XX');
  await prefs.setString('asset-ticker','FRT');
  int nonceRes = nonce();
  await prefs.setInt('nonce', nonceRes);
  postPayDb("paydb/user_info", {"email" : ""});
}

Future<dynamic> postPayDb(String endpoint, Map<String, String> params) async {
  var mapInJsonString = json.encode(params);
  var sig = await sign(mapInJsonString);
  Map<String, String> customHeaders = {
    "Content-Type" : "application/json",
    "X-Signature" : sig
  };
  SharedPreferences prefs = await SharedPreferences.getInstance();
  params['api_key'] = await prefs.getString('api_key') ?? "";
  params['nonce'] = nonce().toString();
  Uri url = Uri.parse(URL_BASE + endpoint);
  var response = await http.post(url, headers: customHeaders, body: json.encode(params));
  return response;
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
                GestureDetector(
                  onTap: () {
                    Alert(
                      context: context,
                      title: "Recieve",
                      content: Column(
			children: <Widget>[
			  TextField(
			    decoration: InputDecoration(
			      icon: Icon(Icons.monetization_on),
			      labelText: "amount"
			    )
			  ),
			  TextField(
			    decoration: InputDecoration(
			      icon: Icon(Icons.message),
			      labelText: "message"
			    )
			  ),
			],
                      ),
                    ).show();
                  },
                  child: 
		    Container(
		      child: Text("↙️", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
		      alignment: Alignment.center,
		      width: 180.0,
		      height: 180.0,
		      color: Colors.blue,
		    ),
                ),
		SizedBox(width: 100),
                GestureDetector(
                  onTap: () {
                    Alert(
                      context: context,
                      title: "Send",
                      content: Column(
			children: <Widget>[
			  TextField(
			    decoration: InputDecoration(
			      icon: Icon(Icons.monetization_on),
			      labelText: "amount"
			    )
			  ),
			  TextField(
			    decoration: InputDecoration(
			      icon: Icon(Icons.message),
			      labelText: "message"
			    )
			  ),
			],
                      ),
                    ).show();
                  },
                  child: 
		    Container(
                      child: Text("↗️", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
		      alignment: Alignment.center,
		      width: 180.0,
		      height: 180.0,
		      color: Colors.blue,
		    ),
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
                GestureDetector(
                  onTap: () {
                    Alert(
                      context: context,
                      title: "Settings",
                      content: Column(
			children: <Widget>[
			  TextField(
			    decoration: InputDecoration(
			      icon: Icon(Icons.vpn_key),
			      labelText: "apikey"
			    )
			  ),
			  TextField(
			    decoration: InputDecoration(
			      icon: Icon(Icons.lock),
			      labelText: "secret"
			    )
			  ),
			  TextField(
			    decoration: InputDecoration(
			      icon: Icon(Icons.create_rounded),
			      labelText: "asset name"
			    )
			  ),
			],
                      ),
                    ).show();
                  },
                  child: 
		    Container(
                      child: Text("⚙️", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
		      alignment: Alignment.center,
		      width: 180.0,
		      height: 180.0,
		      color: Colors.blue,
		    ),
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
