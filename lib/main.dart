import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:logger/logger.dart';
import 'package:patox/homePage.dart';
import 'package:patox/introPage.dart';
import 'package:patox/services/chopper/service_interface.dart';
import 'package:provider/provider.dart';

/**
 * iOS 권한을 요청하는 함수
 */
Future reqIOSPermission(FirebaseMessaging fbMsg) async {
  NotificationSettings settings = await fbMsg.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
}

/**
 * Firebase Background Messaging 핸들러
 */
Future<void> fbMsgBackgroundHandler(RemoteMessage message) async {
  print("[FCM - Background] MESSAGE : ${message.messageId}");
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

/**
 * Firebase Foreground Messaging 핸들러
 */
Future<void> fbMsgForegroundHandler(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    AndroidNotificationChannel? channel) async {
  print('[FCM - Foreground] MESSAGE : ${message.data}');

  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
    flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
            android: AndroidNotificationDetails(
              channel!.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
            //iOS: const DarwinNotificationDetails(
            iOS: IOSNotificationDetails(
              badgeNumber: 1,
              subtitle: 'the subtitle',
              sound: 'slow_spring_board.aiff',
            ),
        ));
  }
}

/**
 * FCM 메시지 클릭 이벤트 정의
 */
Future<void> setupInteractedMessage(FirebaseMessaging fbMsg) async {
  RemoteMessage? initialMessage = await fbMsg.getInitialMessage();
  // 종료상태에서 클릭한 푸시 알림 메세지 핸들링
  if (initialMessage != null) clickMessageEvent(initialMessage);
  // 앱이 백그라운드 상태에서 푸시 알림 클릭 하여 열릴 경우 메세지 스트림을 통해 처리
  FirebaseMessaging.onMessageOpenedApp.listen(clickMessageEvent);
}
void clickMessageEvent(RemoteMessage message) {
  print('message : ${message.notification!.title}');
  //Get.toNamed('/');
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  //다운로더
  await FlutterDownloader.initialize(
    debug: true,
  );

  //Https 우회
  HttpOverrides.global = MyHttpOverrides();

  //FCM 로직
  await Firebase.initializeApp();
  FirebaseMessaging fbMsg = FirebaseMessaging.instance;
  //String? fcmToken = await fbMsg.getToken(vapidKey: "BGRA_GV..........keyvalue");

  //TODO : 서버에 해당 토큰을 저장하는 로직 구현
  //FCM 토큰은 사용자가 앱을 삭제, 재설치 및 데이터제거를 하게되면 기존의 토큰은 효력이 없고 새로운 토큰이 발금된다.
  fbMsg.onTokenRefresh.listen((nToken) {
    //TODO : 서버에 해당 토큰을 저장하는 로직 구현
  });

  NotificationSettings settings = await fbMsg.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  runApp(const WebViewApp());

  // 플랫폼 확인후 권한요청 및 Flutter Local Notification Plugin 설정
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? androidNotificationChannel;
  if (Platform.isIOS) {
    await reqIOSPermission(fbMsg);
  } else if (Platform.isAndroid) {
    //Android 8 (API 26) 이상부터는 채널설정이 필수.
    androidNotificationChannel = const AndroidNotificationChannel(
      'important_channel', // id
      'Important_Notifications', // name
      description: '중요도가 높은 알림을 위한 채널.',
      // description
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  //Background Handling 백그라운드 메세지 핸들링
  FirebaseMessaging.onBackgroundMessage(fbMsgBackgroundHandler);

  //Foreground Handling 포어그라운드 메세지 핸들링
  FirebaseMessaging.onMessage.listen((message) {
    fbMsgForegroundHandler(message, flutterLocalNotificationsPlugin, androidNotificationChannel);
  });

  //Message Click Event Implement
  await setupInteractedMessage(fbMsg);

}

//SSL 인증 문제용
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

class WebViewApp extends StatelessWidget {
  const WebViewApp({Key? key}) : super(key: key);

  static const String siteTitle = '공무원 영어 OX';
  //static const String siteUrl = 'https://www.patox.co.kr';
  static const String siteUrl = 'https://patox.softwow.co.kr';
  static const String siteIsAppUrlParameter = 'is_app=y&version=17';
  static const String siteInitialUrl = '$siteUrl/?$siteIsAppUrlParameter';
  static const Level loggerLevel = Level.nothing;

  static int lastLoadingTime = DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GeneralRowService>(
          create: (_) => GeneralRowService.create(),
          dispose: (_, GeneralRowService service) => service.client.dispose(),
        ),
        Provider<GeneralListService>(
          create: (_) => GeneralListService.create(),
          dispose: (_, GeneralListService service) => service.client.dispose(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: siteTitle,
        home: const IntroPage(),
        routes: {
          HomePage.HomePageRouteName: (context) => const HomePage(),
        },
      ),
    );
  }

}

