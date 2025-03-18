
//get character list
// RxList<CharacterModel> charactersList = <CharacterModel>[].obs;
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../api_checker.dart';
import '../api_client.dart';
import '../api_constants.dart';
import '../constants.dart';
import '../enum_file.dart';
import '../prefs_helpers.dart';

class CallScreenController extends GetxController {

  var isLoading=false.obs;
//get all users
  getUserList() async {
    isLoading(true);
    try {
      var response = await ApiClient().getData(ApiConstants.getAllUsers);

      if (response.statusCode == 200) {
        //  showInfo(response.body.toString());
        //   charactersList.value = (response.body['data']['attributes'] as List)
        //       .map((e) => CharacterModel.fromJson(e))
        //       .toList();
      } else {
        //  showWarning(response.body.toString());
        ApiChecker.checkApi(response);
        isLoading(false);
      }
    } finally {
      isLoading(false);
    }


  }
  //register for a account
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  registerAnAccount() async {

    var fcmToken = await PrefsHelper.getString(Constants.fcmToken);

    isLoading(true);
    Map<String, dynamic> body = {
      "username": userNameController.text,
      "email": emailController.text,
      "password":passwordController.text,
      "fcmToken":fcmToken
    };

    // Map<String, dynamic> body = {
    //
    //     "username": "sdfjksdkjfhsdjkfh",
    //     "email": "sdfjksdkjfhsdjkfh@gmail.com",
    //     "password":"123456",
    //     "fcmToken":"cOLKxnGSTQ-WEtJ7kw_q-I:APA91bEVLxsJBq1HO8-4KK5fXvOEUA7ngkkuibIYMKqAbGGcj7SprgjgC1iJqABdECc2rO2ey7d66-ytKunV2ccYoTUYnGQIprGBH-918rbU3zopH3FLwgM"
    //
    // };
    var headers = {
      'Content-Type': 'application/json'
    };

    print("jacce body===========>"+body.toString());
    var response = await ApiClient().postData(
      ApiConstants.register,
      jsonEncode(body),
       headers: headers,
    );
    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      isLoading(false);
      if (kDebugMode) {
        print("SUCCESS BODY========>${response.body}");
      }

    } else if (response.statusCode == 400) {
      isLoading(false);

    } else {
      isLoading(false);
      ApiChecker.checkApi(response);
    }
  }


}