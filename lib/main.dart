import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

const URL_BASE = "https://mtoken-test.zap.me/";
const WS_URL = "https://mtoken-test.zap.me/paydb";

void main() {
  setLocalStorage();
  runApp(MyApp());
}

int nonce() {
  return DateTime.now().toUtc().millisecondsSinceEpoch;
}


Future<void> setLocalStorage() async {
  // Test localstorage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_key', 'bgPfjilKLfk');
  await prefs.setString('secret', 'Zw_EayWw_CZ0M-L3ril9uA');
  await prefs.setString('asset-ticker','FRT');
  String nonceRes = nonce().toString();
  await prefs.setString('nonce', nonceRes);
  postPayDb("paydb/user_info", {"email" : "mtokentest@protonmail.com"});
}

Future<String> sign(data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var secretBytes = utf8.encode(prefs.getString('secret') ?? "");
  var messageBytes = utf8.encode(data);
  Hmac hmacSha256 = Hmac(sha256, secretBytes);
  Digest bytesDigest = hmacSha256.convert(messageBytes);
  return base64.encode(bytesDigest.bytes);
}

Future<dynamic> postPayDb(String endpoint, Map<String, String> params) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  params['api_key'] = await prefs.getString('api_key') ?? "";
  params['nonce'] = nonce().toString();
  var mapInJsonString = json.encode(params);
  var sig = await sign(mapInJsonString);
  Map<String, String> customHeaders = {
    "Content-Type" : "application/json",
    "X-Signature" : sig
  };
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
                    TextEditingController amountValue = TextEditingController();
                    TextEditingController msgValue = TextEditingController();
                    Alert(
                      context: context,
                      title: "Send",
                      content: Column(
			children: <Widget>[
			  TextField(
                            controller: amountValue,
			    decoration: InputDecoration(
			      icon: Icon(Icons.monetization_on),
			      labelText: "amount"
			    )
			  ),
			  TextField(
                            controller: msgValue,
			    decoration: InputDecoration(
			      icon: Icon(Icons.message),
			      labelText: "message"
			    )
			  ),
			],
                      ),
                      buttons: [
                        DialogButton(
                          onPressed: () async {
                            Navigator.of(context, rootNavigator: true).pop();
                            Alert(
                              context: context,
                              title: "Pressed",
                              content: Column(
                                children: <Widget>[
                                  QrImage(
				    data: 'premiofrankie://mtokentest@protonmail.com?amount=${int.parse(amountValue.text)*100}&attachment={"invoiceid":"${msgValue.text}}',
				    version: QrVersions.auto,
				    size: 180,
				    gapless: false,
				  )
                                ],
                              ),
                            ).show();
                          },
                          child: Text("OK")
                        ),
                      ],
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
                    TextEditingController apiValue = TextEditingController();
                    TextEditingController secretValue = TextEditingController();
                    TextEditingController tickerValue = TextEditingController();
                    Alert(
                      context: context,
                      title: "Settings",
                      content: Column(
			children: <Widget>[
			  TextField(
                            controller: apiValue,
			    decoration: InputDecoration(
			      icon: Icon(Icons.vpn_key),
			      labelText: "apikey"
			    )
			  ),
			  TextField(
                            controller: secretValue,
			    decoration: InputDecoration(
			      icon: Icon(Icons.lock),
			      labelText: "secret"
			    )
			  ),
			  TextField(
                            controller: tickerValue,
			    decoration: InputDecoration(
			      icon: Icon(Icons.create_rounded),
			      labelText: "asset name"
			    )
			  ),
			],
                      ),
                      buttons: [
                        DialogButton(
                          onPressed: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setString('api_key', apiValue.text);
                            await prefs.setString('secret', secretValue.text);
                            await prefs.setString('asset-ticker', tickerValue.text);
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: Text("OK")
                        ),
                      ],
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
