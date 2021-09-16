import 'package:encrypt/encrypt.dart'as ep;
import 'globals.dart' as globals;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bip32/bip32.dart';
import 'package:hex/hex.dart';
import 'package:defichaindart/defichaindart.dart';

class PasswordPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordValue = TextEditingController();

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: Text('Password'),
      ),
      body:   
	Form(
	  key: _formKey,
	  child: Column(
	    children: <Widget>[
	      Text("Enter a password to encrypt your mnemonic"),
	      TextFormField(
		  controller: passwordValue,
		  validator: (value) {
		    if (value == null || value.isEmpty) {
		      return "please a password";
		    }
		  },
		  decoration: InputDecoration(
		      icon: Icon(Icons.vpn_key),
		      labelText: "password")),
		      DialogButton(
			  onPressed: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
			    if (_formKey.currentState!.validate()) {
                              String convertedSeed = globals.privKey;
                              HEX.decode(convertedSeed);
                              BIP32 nodeFromSeed = new BIP32.fromSeed(Uint8List.fromList(HEX.decode(convertedSeed)));
                              final node = nodeFromSeed.derivePath("m/84'/0'/0'/0/0");
                              final address = P2WPKH(data: new PaymentData(pubkey: node.publicKey)).data?.address;
                              globals.segwitAddress = address ?? "";
                              print(address);
			      final key = ep.Key.fromUtf8("${md5.convert(utf8.encode(passwordValue.text))}");
			      final iv = ep.IV.fromLength(16);
                              globals.ivValue = iv;
			      final encrypter = ep.Encrypter(ep.AES(key));
			      final encrypted = encrypter.encrypt(convertedSeed, iv: iv);
                              globals.privKey = encrypted.base64;
			      //final decrypted = encrypter.decrypt(encrypted, iv: iv);
                              await prefs.setString('iv-value', iv.toString());
			      await prefs.setString('seed', encrypted.base64);
			      await prefs.setString('address', address ?? "");
			      Navigator.of(context, rootNavigator: true)
				  .pop();
			    }
			  },
			  child: Text("OK")),
	    ],
	  ),
	),

     );
  }

}


