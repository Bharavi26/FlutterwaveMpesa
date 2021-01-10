


import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'Constant.dart';

class MpesaPageActivity extends StatefulWidget {


  @override
  MpesaPageState createState() => MpesaPageState();
}

class MpesaPageState extends State<MpesaPageActivity> {
  TextEditingController edtmobileno = TextEditingController();
  TextEditingController edtamount = TextEditingController();
  TextEditingController edtname = TextEditingController();
  TextEditingController edtemail = TextEditingController();
  bool isloading = false;
  final _formKey = GlobalKey<FormState>();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(key: scaffoldKey,
      appBar: AppBar(

        title: Text('FlutterWave Mpesa'),
      ),
      body: Center(

        child: Form(key: _formKey,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(15),
                child: TextFormField(
                  controller: edtname,
                  keyboardType: TextInputType.name,
                  validator: (val) => val.trim().isEmpty ? 'Enter Name' : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Name',
                    hintText: 'Enter Name',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: TextFormField(
                  controller: edtemail,
                  keyboardType: TextInputType.name,
                  validator: (val) => Constant.validateEmail(val),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Email',
                    hintText: 'Enter Email',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: TextFormField(
                  controller: edtmobileno,
                  keyboardType: TextInputType.phone,
                  validator: (val) => Constant.validateMobile(val),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Mobile Number',
                    hintText: 'Enter Mobile Number',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: TextFormField(
                  controller: edtamount,
                  keyboardType: TextInputType.number,
                  validator: (val) => val.trim().isEmpty || double.parse(val.trim()) <= 0 ? "Enter Amount" : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Amount',
                    hintText: 'Enter Amount',
                  ),
                ),
              ),
              if(isloading)
                Center(child: new CircularProgressIndicator()),
              Padding(
                padding: const EdgeInsets.all(15),
                child: RaisedButton(
                  textColor: Colors.white,
                  color: Colors.blue,
                  child: Text('Send Amount'),
                  onPressed: (){
                    if(_formKey.currentState.validate() && !isloading){
                      MPesaPayment(edtmobileno.text, edtamount.text, edtemail.text, edtname.text);
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),

    );
  }

  MPesaPayment(String phonenumber, String mainamt,String uemail,String uname) async {

    if(!isloading)
    setState(() {
      isloading = true;
    });

    String url;
    if(Constant.isFlutterwaveTest){
      url = Constant.mpesatesturl;
    }else{
      url = Constant.mpesaliveurl;
    }

    String txref = "${new DateTime.now().millisecond}";


    Map data = {
      'tx_ref': "$txref",
      'amount':mainamt,
      'type':'mpesa',
      'currency': Constant.FlutterwaveCurrency,
      'country': Constant.FlutterwaveCountry,
      'email':uemail,
      'phone_number':phonenumber,
      'fullname':uname,
      'public_key':Constant.FlutterwavePubKey,
      "is_mpesa":"1",
      "is_mpesa_lipa":"1"
    };

    var body = utf8.encode(json.encode(data));

    Response response = await post(
      url,
      body: body,
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer " + Constant.FlutterwaveSecKey
      },
    );

    setState(() {
      isloading = false;
    });


    print("mpesa-**--${response.statusCode}");
    print("mpesa---${response.body.toString()}");
    final res = json.decode(response.body);
    if (response.statusCode == 200) {
      print("mpesa---${response.body.toString()}");

      String status = res['status'];
      if(status.trim().toLowerCase() == "success" || status.trim().toLowerCase() == "successful"){
        scaffoldKey.currentState.showSnackBar(SnackBar(content: Text("Verifying Transaction")));

        //verifying transaction
        setState(() {
          isloading = true;
        });
        Map vdata = {
          'txref': "$txref",
          'SECKEY':Constant.FlutterwaveSecKey
        };

        var vbody = utf8.encode(json.encode(vdata));

        Response vresponse = await post(
          Constant.FlutterwaveVerifyUrl,
          body: vbody,
          headers: {
            "content-type": "application/json"
            //"Authorization": "Bearer " + Constant.FlutterwaveSecKey
          },
        );

        setState(() {
          isloading = false;
        });

        final vres = json.decode(vresponse.body);
        if (vresponse.statusCode == 200) {
          print("mpesa--verify-${vresponse.body.toString()}");

          String vstatus = vres['status'];
          if(vstatus.trim().toLowerCase() == "success" || vstatus.trim().toLowerCase() == "successful"){

            //SetTransactionData
            //here we can get success transaction we can set transaction reference in out backend from here


            scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(vres['message'] ?? "Transaction Success")));
            edtname.clear();
            edtemail.clear();
            edtamount.clear();
            edtmobileno.clear();
            setState(() {

            });
          }else{
            scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(vres['message'] ?? "Transaction Failed")));
          }
        }else{
          scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(vres['message'] ?? "Transaction Failed")));
        }

      }else{
        scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(res['message'] ?? "Transaction Failed")));
      }
    }else{
      scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(res['message'] ?? "Transaction Failed")));
    }

  }

}