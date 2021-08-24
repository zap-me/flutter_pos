import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'dart:html';

const URL_BASE = "https://mtoken-test.zap.me/";
const WS_URL = "wss://mtoken-test.zap.me/paydb";
String base64EncodedPic = "";
String posEmail = "";

void main() async {
  initApiKeys();
  await callUserInfo();
  setUpWS(); 
  runApp(MyApp());
}

int nonce() {
  return DateTime.now().toUtc().millisecondsSinceEpoch;
}

Future<void> setUpWS() async {
  var webSocket = new WebSocket(WS_URL);
  webSocket.onMessage.listen((MessageEvent e) {
    print(e.data);
  });
}

Future<void> initApiKeys() async {
  // Provides default values for initial api Keys
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_key', 'bgPfjilKLfk');
  await prefs.setString('secret', 'Zw_EayWw_CZ0M-L3ril9uA');
  await prefs.setString('asset-ticker','FRT');
}

Future<void> callUserInfo() async {
  // Test localstorage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String nonceRes = nonce().toString();
  await prefs.setString('nonce', nonceRes);
  dynamic response = await postPayDb("paydb/user_info", {"email" : null});
  response = jsonDecode(response.body);
  print("response is ${response.map}");
  base64EncodedPic = response["photo"];
  posEmail = response["email"];
  //return {"base64EncodedPic" : response.body.image};
}

Future<String> sign(data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var secretBytes = utf8.encode(prefs.getString('secret') ?? "");
  var messageBytes = utf8.encode(data);
  Hmac hmacSha256 = Hmac(sha256, secretBytes);
  Digest bytesDigest = hmacSha256.convert(messageBytes);
  return base64.encode(bytesDigest.bytes);
}

Future<dynamic> postPayDb(String endpoint, Map<String, dynamic?> params) async {
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
    Uint8List bytes = Base64Codec().decode(base64EncodedPic);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 360.0,
              height: 90.0,
              color: Colors.grey,
              child: 
                Row(
                  children: <Widget>[
		    Card(
		      child: Image.memory(bytes, fit: BoxFit.cover),
		    ),
                    Text(posEmail),
                  ],
                ),
            ),
            SizedBox(height: 80),
	    Row(
              mainAxisAlignment: MainAxisAlignment.center,
	      children: <Widget>[
                GestureDetector(
                  onTap: () {
		    TextEditingController amountValue = TextEditingController();
		    TextEditingController msgValue = TextEditingController();
                    TextEditingController emailValue = TextEditingController();
                    Alert(
                      context: context,
                      title: "Recieve",
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
			  TextField(
                            controller: emailValue,
			    decoration: InputDecoration(
			      icon: Icon(Icons.message),
			      labelText: "email"
			    )
			  ),
			],
                      ),
                      buttons: [
                        DialogButton(
                          onPressed: () async {
                            postPayDb('payment_create', {"recipient": emailValue.text, "amount": (double.parse(amountValue.text) * 100), "message": 1, "reason": msgValue.text, "category": "testing"});
                            Navigator.of(context, rootNavigator: true).pop();
                            Alert(
                              context: context,
                              title: "Sent",
                              content: Text("Sent payment"),
                            ).show();
                          },
                          child: Text("OK")
                        ),
                      ],
                    ).show();
                  },
                  child: 
		    Container(
		      child: Text("↙️", textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
		      alignment: Alignment.center,
		      width: 90.0,
		      height: 90.0,
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
		      width: 90.0,
		      height: 90.0,
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
                  child: Icon(Icons.card_giftcard, size: 40, color: Colors.white),
                  alignment: Alignment.center,
		  width: 90.0,
		  height: 90.0,
                  color: Colors.blue,
		),
		SizedBox(width: 100),
                GestureDetector(
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    TextEditingController apiValue = TextEditingController(text: await prefs.getString('api_key'));
                    TextEditingController secretValue = TextEditingController(text: await prefs.getString('secret'));
                    TextEditingController tickerValue = TextEditingController(text: await prefs.getString('asset-ticker'));
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
                          Text('Server: ${URL_BASE}'),
			],
                      ),
                      buttons: [
                        DialogButton(
                          onPressed: () async {
                            await prefs.setString('api_key', apiValue.text);
                            await prefs.setString('secret', secretValue.text);
                            await prefs.setString('asset-ticker', tickerValue.text);
                            callUserInfo();
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: Text("OK")
                        ),
                      ],
                    ).show();
                  },
                  child: 
		    Container(
                      child: Icon(Icons.settings, size: 40, color: Colors.white),
		      alignment: Alignment.center,
		      width: 90.0,
		      height: 90.0,
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
