import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:patox/homePage.dart';
import 'package:patox/utils/logger.dart';
import 'package:patox/utils/preferences_util.dart' as preference_util;
import 'package:patox/utils/user_util.dart' as user_util;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    try {
      super.initState();

      Timer(const Duration(seconds: 1), () async {
        await preference_util.initInstance();
        await fcmSetting();

        Navigator.pushNamed(
          context,
          HomePage.HomePageRouteName,
        );
      });
    } catch (e) {
      logger.e(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue,
    );
  }
}

Future<void> fcmSetting() async {
  String pushDevice = 'etc';
  String? pushToken;

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  try {
    await Firebase.initializeApp();
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    await firebaseMessaging.setAutoInitEnabled(true);

    NotificationSettings notificationSettings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    switch (notificationSettings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        logger.i('푸시 - 권한 부여.');
        break;

      case AuthorizationStatus.notDetermined:
        logger.w('푸시 - 한번 허용.');
        break;

      case AuthorizationStatus.provisional:
        logger.w('푸시 - 임시 권한 부여.');
        break;

      default:
        throw const FormatException('푸시 - 권한을 거부했거나 승인하지 않았습니다.');
    }

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        //iOS: DarwinInitializationSettings(),
        iOS: IOSInitializationSettings(),
      ),
       onSelectNotification: (String? payload) {},
      //onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    if (Platform.isAndroid) {
      pushDevice = 'android';
      const AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
        'NOTIFICATION_CHANNEL',
        'Push Notification',
        description: 'This channel is used for push notification.',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidNotificationChannel);
    } else if (Platform.isIOS) {
      pushDevice = 'ios';
      await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    pushToken = await firebaseMessaging.getToken();
  } catch (e) {
    logger.e(e);
    pushToken = '';
  }

  try {
    await user_util.setPushDevice(pushDevice);
    await user_util.setPushToken(pushToken ?? '');
  } catch (e) {
    logger.e(e);
  }
}

// void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
//   //! Payload(전송 데이터)를 Stream에 추가합니다.
//   final String payload = notificationResponse.payload ?? "";
//   if (notificationResponse.payload != null ||
//       notificationResponse.payload!.isNotEmpty) {
//     print('FOREGROUND PAYLOAD: $payload');
// //streamController.add(payload);
//   }
// }
//
// void onBackgroundNotificationResponse() async {
//   final NotificationAppLaunchDetails? notificationAppLaunchDetails =
//   await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
//   //! 앱이 Notification을 통해서 열린 경우라면 Payload(전송 데이터)를 Stream에 추가합니다.
//   if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
//     String payload =
//         notificationAppLaunchDetails!.notificationResponse?.payload ?? "";
//     print("BACKGROUND PAYLOAD: $payload");
// //streamController.add(payload);
//   }
// }
