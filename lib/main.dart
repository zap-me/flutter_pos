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
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:io';
import 'package:web_socket_channel/io.dart';


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
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String apiKeyAuth = await prefs.getString('api_key') ?? "";
  var nonceVal = nonce(); 
  var sig = sign("${nonceVal}");
  Map<String, dynamic> authHeaders = {"signature" : sig, "api_key" : apiKeyAuth, "nonce": "${nonceVal}" };
  var channel = IOWebSocketChannel.connect(Uri.parse(WS_URL), headers: authHeaders);
  channel.stream.listen((message) {
    channel.sink.add('received!');
    print('got message');
    channel.sink.close(status.goingAway);
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
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
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
                            String cameraScanResult = "";
                            void setQRController(QRViewController controller) {
                              this.controller = controller;
			      controller.scannedDataStream.listen((scanData) {
				  cameraScanResult = scanData.code;
				  postPayDb('payment_create', {"recipient": cameraScanResult, "amount": (double.parse(amountValue.text) * 100), "message": 1, "reason": msgValue.text, "category": "testing"});
			      });
                            }
                            Alert(
                              context: context,
                              title: "Scan email",
                              content: QRView(
                                key: qrKey,
                                onQRViewCreated: setQRController,
                              ),
                            ).show();
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
		      child: FaIcon(FontAwesomeIcons.chevronUp),
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
		      child: FaIcon(FontAwesomeIcons.chevronDown),
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
		  child: FaIcon(FontAwesomeIcons.gifts),
                  alignment: Alignment.center,
		  width: 90.0,
		  height: 90.0,
                  color: Colors.blue,
		),
		SizedBox(width: 100),
                GestureDetector(
                  onTap: () async {
                    final _formKey = GlobalKey<FormState>();
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    TextEditingController apiValue = TextEditingController(text: await prefs.getString('api_key'));
                    TextEditingController secretValue = TextEditingController(text: await prefs.getString('secret'));
                    TextEditingController tickerValue = TextEditingController(text: await prefs.getString('asset-ticker'));
                    Alert(
                      context: context,
                      title: "Settings",
                      content: Column(
                        children: <Widget>[
                          Form(
                            key: _formKey,
                            child: Column(
			      children: <Widget>[
				TextFormField(
				  controller: apiValue,
				  validator: (value) {
				    if(value == null || value.isEmpty) {
				      return "please enter an api-key";
				    }
				  },
				  decoration: InputDecoration(
				    icon: Icon(Icons.vpn_key),
				    labelText: "apikey"
				  )
				),
				TextFormField(
				  controller: secretValue,
				  validator: (value) {
				    if(value!.isEmpty) {
				      return "please enter a secret";
				    }
				  },
				  decoration: InputDecoration(
				    icon: Icon(Icons.lock),
				    labelText: "secret"
				  )
				),
				TextFormField(
				  controller: tickerValue,
				  validator: (value) {
				    if(value!.isEmpty) {
				      return "please enter an asset ticker";
				    }
				  },
				  decoration: InputDecoration(
				    icon: Icon(Icons.create_rounded),
				    labelText: "asset name"
				  )
				),
				Text('Server: ${URL_BASE}'),
			      ],
                            ),
                          ),
                        ]
                      ),
                      buttons: [
                        DialogButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
			      await prefs.setString('api_key', apiValue.text);
			      await prefs.setString('secret', secretValue.text);
			      await prefs.setString('asset-ticker', tickerValue.text);
			      callUserInfo();
			      Navigator.of(context, rootNavigator: true).pop();
                            }
                          },
                          child: Text("OK")
                        ),
                      ],
                    ).show();
                  },
                  child: 
		    Container(
		      child: FaIcon(FontAwesomeIcons.slidersH),
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
