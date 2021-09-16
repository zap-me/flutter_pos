import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:bip39/bip39.dart' as bip39;
import 'globals.dart' as globals;
import 'passwordpage.dart';

const URL_BASE = "https://mtoken-test.zap.me/";
const WS_URL = "https://mtoken-test.zap.me/paydb";
String base64EncodedPic = "";
String posEmail = "";

void main() async {
  initApiKeys();
  await callUserInfo();
  globals.pkHasBeenSet = await checkIfPKSet();
  runApp(MyApp());
}

int nonce() {
  return DateTime.now().toUtc().millisecondsSinceEpoch;
}

Future<void> setUpWS(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  IO.Socket socket = IO.io(WS_URL, <String, dynamic>{
    'secure': true,
    'transports': ['websocket'],
  });
  int currentNonce = nonce();
  String signature = await sign(currentNonce.toString());
  socket.onConnect((_) {
    socket.emit('auth', {
      "signature": signature,
      "api_key": prefs.getString("api_key"),
      "nonce": currentNonce
    });
    print('connect');
  });
  socket.on('tx', (data) {
    print(data);
    Alert(
      context: context,
      title: "Transaction Recieved",
      content: Text("Recieved Tx"),
    ).show();
  });
  socket.on('connecting', (_) {
    print('ws connecting');
  });
  socket.on('connect_error', (err) {
    print('ws connect error ($err)');
  });
  socket.on('connect_timeout', (_) {
    print('ws connect timeout');
  });
}

Future<void> initApiKeys() async {
  // Provides default values for initial api Keys
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_key', 'bgPfjilKLfk');
  await prefs.setString('secret', 'Zw_EayWw_CZ0M-L3ril9uA');
  await prefs.setString('asset-ticker', 'FRT');
}

Future<void> callUserInfo() async {
  // Test localstorage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String nonceRes = nonce().toString();
  await prefs.setString('nonce', nonceRes);
  dynamic response = await postPayDb("paydb/user_info", {"email": null});
  response = jsonDecode(response.body);
  base64EncodedPic = response["photo"];
  posEmail = response["email"];
  //return {"base64EncodedPic" : response.body.image};
}

Future<bool> checkIfPKSet() async {
  bool returnResult = false;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('seed')) {
    returnResult = true;
    globals.privKey = prefs.getString('seed') ?? "";
  }
  return returnResult;
}

Future<String> sign(data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var secretBytes = utf8.encode(prefs.getString('secret') ?? "");
  var messageBytes = utf8.encode(data);
  Hmac hmacSha256 = Hmac(sha256, secretBytes);
  Digest bytesDigest = hmacSha256.convert(messageBytes);
  return base64.encode(bytesDigest.bytes);
}

Future<dynamic> postPayDb(String endpoint, Map<String, dynamic> params) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  params['api_key'] = prefs.getString('api_key') ?? "";
  params['nonce'] = nonce().toString();
  var mapInJsonString = json.encode(params);
  var sig = await sign(mapInJsonString);
  Map<String, String> customHeaders = {
    "Content-Type": "application/json",
    "X-Signature": sig
  };
  Uri url = Uri.parse(URL_BASE + endpoint);
  var response =
      await http.post(url, headers: customHeaders, body: json.encode(params));
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
  bool? isPremio;
  bool? alreadyHasPK = globals.pkHasBeenSet;
  String freshMnemonic = bip39.generateMnemonic();

  void initState() {
    isPremio = true;
  }

  @override
  Widget build(BuildContext context) {
  if(alreadyHasPK == false) {
    () async {
      bool isPKSet = await checkIfPKSet();
      setState(
        () {
          alreadyHasPK = isPKSet;
        }
      );
    };
  }
    setUpWS(context);
    Uint8List bytes = Base64Codec().decode(base64EncodedPic);
    return isPremio == true ?
      Scaffold(
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
              child: Row(
                children: <Widget>[
                  Card(
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                  Text(posEmail),
                ],
              ),
            ),
            SizedBox(height: 80),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              GestureDetector(
                onTap: () {
                  final _formKey = GlobalKey<FormState>();
                  TextEditingController amountValue = TextEditingController();
                  TextEditingController msgValue = TextEditingController();
                  TextEditingController emailValue = TextEditingController();
                  Alert(
                    context: context,
                    title: "Send",
                    content: Column(children: <Widget>[
                      Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                                controller: amountValue,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "please enter an amount";
                                  }
                                },
                                decoration: InputDecoration(
                                    icon: Icon(Icons.monetization_on),
                                    labelText: "amount")),
                            TextFormField(
                                controller: msgValue,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "please enter a tx message";
                                  }
                                },
                                decoration: InputDecoration(
                                    icon: Icon(Icons.message),
                                    labelText: "message")),
                            TextFormField(
                                controller: emailValue,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "please enter a receiver email";
                                  }
                                },
                                decoration: InputDecoration(
                                    icon: Icon(Icons.create_rounded),
                                    labelText: "recipient")),
                          ],
                        ),
                      ),
                    ]),
                    buttons: [
                      DialogButton(
                        child: Text("OK"),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            postPayDb('payment_create', {
                              "recipient": emailValue.text,
                              "amount": (double.parse(amountValue.text) * 100),
                              "message": 1,
                              "reason": msgValue.text,
                              "category": "testing"
                            });
                            Navigator.of(context, rootNavigator: true).pop();
                            Alert(
                              context: context,
                              title: "Sent",
                              content: Text("Sent payment"),
                            ).show();
                          }
                        },
                      ),
                    ],
                  ).show();
                },
                child: Container(
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
                  final _formKey = GlobalKey<FormState>();
                  TextEditingController amountValue = TextEditingController();
                  TextEditingController msgValue = TextEditingController();
                  Alert(
                    context: context,
                    title: "Recieve",
                    content: Column(children: <Widget>[
                      Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                                controller: amountValue,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "please enter an amount";
                                  }
                                },
                                decoration: InputDecoration(
                                    icon: Icon(Icons.monetization_on),
                                    labelText: "amount")),
                            TextFormField(
                                controller: msgValue,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "please enter a tx message";
                                  }
                                },
                                decoration: InputDecoration(
                                    icon: Icon(Icons.message),
                                    labelText: "message")),
                          ],
                        ),
                      ),
                    ]),
                    buttons: [
                      DialogButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              Navigator.of(context, rootNavigator: true).pop();
                              Alert(
                                context: context,
                                title: "Pressed",
                                content: Column(
                                  children: <Widget>[
                                    QrImage(
                                      data: 'premiofrankie://' +
                                          posEmail +
                                          "?amount=${int.parse(amountValue.text) * 100}&attachment={'invoiceid':'${msgValue.text}'}",
                                      version: QrVersions.auto,
                                      size: 180,
                                      gapless: false,
                                    )
                                  ],
                                ),
                              ).show();
                            }
                          },
                          child: Text("OK")),
                    ],
                  ).show();
                },
                child: Container(
                  child: FaIcon(FontAwesomeIcons.chevronDown),
                  alignment: Alignment.center,
                  width: 90.0,
                  height: 90.0,
                  color: Colors.blue,
                ),
              ),
            ]),
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
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    TextEditingController apiValue =
                        TextEditingController(text: prefs.getString('api_key'));
                    TextEditingController secretValue =
                        TextEditingController(text: prefs.getString('secret'));
                    TextEditingController tickerValue = TextEditingController(
                        text: prefs.getString('asset-ticker'));
                    Alert(
                      context: context,
                      title: "Settings",
                      content: Column(children: <Widget>[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                  controller: apiValue,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "please enter an api-key";
                                    }
                                  },
                                  decoration: InputDecoration(
                                      icon: Icon(Icons.vpn_key),
                                      labelText: "apikey")),
                              TextFormField(
                                  controller: secretValue,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "please enter a secret";
                                    }
                                  },
                                  decoration: InputDecoration(
                                      icon: Icon(Icons.lock),
                                      labelText: "secret")),
                              TextFormField(
                                  controller: tickerValue,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "please enter an asset ticker";
                                    }
                                  },
                                  decoration: InputDecoration(
                                      icon: Icon(Icons.create_rounded),
                                      labelText: "asset name")),
                              Text('Server: ' + URL_BASE),
                            ],
                          ),
                        ),
                      ]),
                      buttons: [
                        DialogButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await prefs.setString('api_key', apiValue.text);
                                await prefs.setString(
                                    'secret', secretValue.text);
                                await prefs.setString(
                                    'asset-ticker', tickerValue.text);
                                callUserInfo();
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              }
                            },
                            child: Text("OK")),
                      ],
                    ).show();
                  },
                  child: Container(
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
	onPressed: () {
          setState(
            (){
              isPremio = false;
            }
          );
	},
	child: const FaIcon(FontAwesomeIcons.bitcoin),
	backgroundColor: Colors.amber,
    ),
    ) :
      Scaffold(
	appBar: AppBar(
	  title: Text(widget.title),
	),
	body: alreadyHasPK == false ? Center(
          child: Column(
              children: <Widget>[
                SizedBox(height: 100),
                Text(freshMnemonic),
                SizedBox(height: 100),
		DialogButton(
		    onPressed: () async {
                      globals.privKey = bip39.mnemonicToSeedHex(freshMnemonic);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PasswordPage()),
                      );
                      setState(
                        (){
                          alreadyHasPK = true;
                        }
                      );
                    },
		    child: Text("SAVE")),
                
              ],
            ),
          ) : 
          Center(
          child: Text("priv key is ${globals.privKey}"),
          ),
        );
  }
}
