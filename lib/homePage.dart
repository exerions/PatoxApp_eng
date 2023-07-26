import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patox/main.dart';
import 'package:patox/models/datas/auth_data.dart';
import 'package:patox/models/datas/user_data.dart';
import 'package:patox/models/datas/verify_receipt_data.dart';
import 'package:patox/utils/common_util.dart' as common_util;
import 'package:patox/utils/logger.dart';
import 'package:patox/utils/preferences_util.dart' as preference_util;
import 'package:patox/utils/user_util.dart' as user_util;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

//const String shopItemSettingTicketId = 'sanjae_setting';
//const String shopItemCommentaryTicketId = 'sanjae_commentary';
// const String shopItemSettingTicketId = 'sanjae_setting_ticket';
// const String shopItemCommentaryTicketId = 'sanjae_commentary_ticket';

//const String shopItemSettingTicketId = 'setting';
//const String shopItemCommentaryTicketId = 'commentary';
const String shopItemSettingTicketId = 'setting_ticket';
const String shopItemCommentaryTicketId = 'commentary_ticket';

const List<String> shopItemIds = <String>[
  shopItemSettingTicketId,
  shopItemCommentaryTicketId,
];

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static const HomePageRouteName = '/HomePage';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static bool isInitRefreshToken = false;

  final GlobalKey webViewKey = GlobalKey();
  final CookieManager cookieManager = CookieManager.instance();
  final TextEditingController urlController = TextEditingController();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Map<String, VerifyReceiptData?> _verifyReceiptValues = {};

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  late PullToRefreshController pullToRefreshController;
  late InAppWebViewController webViewController;

  List<String> _notFoundIds = <String>[];
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];

  bool _loading = true;
  bool _isAvailable = false;
  bool _isDeliverUpdate = false;
  String? _queryProductError;
  int backButtonPressedTime = 0;
  bool isActiveSubmit = true;
  double progress = 0;
  String url = "";
  String cookiesString = "";

  List<Permission> permissionList = [
    Permission.storage,
  ];

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useOnDownloadStart: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  @override
  void initState() {
    try {
      super.initState();

      final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;

      _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(context, purchaseDetailsList);
      }, onDone: () {
        _subscription.cancel();
      }, onError: (error) {
        logger.e(error);
      });
      initStoreInfo();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (user_util.isLogin()) {
            if (!isInitRefreshToken) {
              isInitRefreshToken = true;
              user_util.getRefreshToken(context, (AuthData? authData) {
                setLogin(context, authData);
              });
            }
          }

          Timer(const Duration(seconds: 2), () {
            try {
              String msg = '게시판에서 첨부파일 다운로드를 위하여 파일접근 권한이 필요합니다.';

              if (preference_util.getBool(preference_util.PreferencesKeys.isPermissionMessageOutput)) {
                common_util.requestPermission(context, permissionList, msg);
              } else {
                common_util.checkPermission(context, permissionList, msg);
                preference_util.setBool(preference_util.PreferencesKeys.isPermissionMessageOutput, true);
              }
            } catch (e) {
              logger.e(e);
            }
          });

          // FlutterNativeSplash.remove();
        } catch (e) {
          logger.e(e);
        }
      });

      pullToRefreshController = PullToRefreshController(
        options: PullToRefreshOptions(
          color: Colors.blue,
        ),
        onRefresh: () async {
          try {
            if (Platform.isAndroid) {
              webViewController.reload();
            } else if (Platform.isIOS) {
              webViewController.loadUrl(urlRequest: URLRequest(url: await webViewController.getUrl()));
            }
          } catch (e) {
            logger.e(e);
          }
        },
      );

      FlutterDownloader.registerCallback(downloadCallback as DownloadCallback);
    } catch (e) {
      logger.e(e);
    }
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          try {
            bool canGoBack = await webViewController.canGoBack();
            if (!canGoBack || url == WebViewApp.siteUrl || url == '${WebViewApp.siteUrl}/' || url.startsWith('${WebViewApp.siteUrl}/main') || url.startsWith('${WebViewApp.siteUrl}/login')) {
              int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              bool isNotExit = backButtonPressedTime == 0 || (currentTime - backButtonPressedTime) > 2;
              if (isNotExit) {
                backButtonPressedTime = currentTime;
                Fluttertoast.showToast(
                  msg: "뒤로 버튼을 한번 더 누르면 종료합니다.",
                );
              } else {
                SystemNavigator.pop();
              }
            } else {
              webViewController.goBack();
            }
          } catch (e) {
            logger.e(e);
          }
          return Future.value(false);
        },
        child: SafeArea(
          child: InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(
              url: Uri.parse('${WebViewApp.siteInitialUrl}&device=${Platform.isAndroid ? 'android' : 'ios'}'),
              headers: {
                'Authorization': 'Bearer ${user_util.getToken()}',
              },
            ),
            initialOptions: options,
            pullToRefreshController: pullToRefreshController,
            //SSL 인층 문제
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              //print(challenge);
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
            },
            onWebViewCreated: (controller) {
              try {
                controller.addJavaScriptHandler(
                  handlerName: 'loginData',
                  callback: (args) async {
                    try {
                      Map<String, dynamic> data = args.first;
                      AuthData authData = AuthData.fromJson(data);
                      setLogin(context, authData);
                      return true;
                    } catch (e) {
                      logger.e(e);
                      return false;
                    }
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'setLogout',
                  callback: (args) async {
                    try {
                      if (user_util.isLogin()) {
                        await user_util.setLogout();
                      }

                      return true;
                    } catch (e) {
                      logger.e(e);
                      return false;
                    }
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'urlDownload',
                  callback: (args) async {
                    try {
                      String? url = args.first;
                      setUrlDownload(url);
                      return true;
                    } catch (e) {
                      logger.e(e);
                      return false;
                    }
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'urlOpen',
                  callback: (args) async {
                    try {
                      String? url = args.first;
                      if (url != null && url.isNotEmpty) {
                        Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                          return true;
                        }
                      }
                    } catch (e) {
                      logger.e(e);
                    }
                    return false;
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'showShopItemPayment',
                  callback: (args) async {
                    try {
                      String? productDetailId = args.first;
                      if (productDetailId != null && productDetailId.isNotEmpty) {
                        showShopItemPayment(productDetailId);
                        return true;
                      }
                    } catch (e) {
                      logger.e(e);
                    }
                    return false;
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'showShopPurchasedItem',
                  callback: (args) async {
                    try {
                      showShopPurchasedItem();
                      return true;
                    } catch (e) {
                      logger.e(e);
                      return false;
                    }
                  },
                );

                webViewController = controller;

                FlutterNativeSplash.remove();
              } catch (e) {
                logger.e(e);
              }
            },
            onLoadStart: (controller, uri) {
              try {
                String url = uri.toString();

                if (url.isNotEmpty && user_util.isLogin()) {
                  if (url.startsWith('${WebViewApp.siteUrl}/main') || url.startsWith('${WebViewApp.siteUrl}/login')) {
                    int currentTime = DateTime.now().millisecondsSinceEpoch;

                    if (currentTime > (WebViewApp.lastLoadingTime + 86400000)) {
                      WebViewApp.lastLoadingTime = currentTime;
                      Navigator.pushNamed(
                        context,
                        HomePage.HomePageRouteName,
                      );
                    }
                  }
                }

                setState(() {
                  this.url = url;
                  urlController.text = url;
                });
              } catch (e) {
                logger.e(e);
              }
            },
            onLoadStop: (controller, uri) async {
              try {
                String url = uri.toString();
                pullToRefreshController.endRefreshing();

                cookiesString = "";
                List<Cookie> cookies = await cookieManager.getCookies(url: Uri.parse(WebViewApp.siteUrl));
                for (var cookie in cookies) {
                  cookiesString += '${cookie.name}=${cookie.value};';
                }

                setState(() {
                  this.url = url;
                  urlController.text = url;
                });
              } catch (e) {
                logger.e(e);
              }
            },
            onProgressChanged: (controller, progress) {
              try {
                if (progress == 100) {
                  pullToRefreshController.endRefreshing();
                }

                setState(() {
                  this.progress = progress / 100;
                });
              } catch (e) {
                logger.e(e);
              }
            },
            onUpdateVisitedHistory: (controller, uri, androidIsReload) {
              try {
                String url = uri.toString();

                setState(() {
                  this.url = url;
                  urlController.text = url;
                });
              } catch (e) {
                logger.e(e);
              }
            },
            onLoadError: (controller, uri, code, message) {
              try {
                pullToRefreshController.endRefreshing();
              } catch (e) {
                logger.e(e);
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              try {
                String message = consoleMessage.message;

                switch (message) {
                  case 'JQMIGRATE: Migrate is installed, version 1.4.1':
                  case 'The key "target-densitydpi" is not supported.':
                    // 메시지 출력 차단
                    break;

                  default:
                    logger.w(message);
                }
              } catch (e) {
                logger.e(e);
              }
            },
            androidOnPermissionRequest: (controller, origin, resources) async {
              return PermissionRequestResponse(
                resources: resources,
                action: PermissionRequestResponseAction.GRANT,
              );
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              try {
                var uri = navigationAction.request.url!;
                if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                    return NavigationActionPolicy.CANCEL;
                  }
                }
              } catch (e) {
                logger.e(e);
              }
              return NavigationActionPolicy.ALLOW;
            },
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              setUrlDownload(downloadStartRequest.url.toString());
            },
          ),
        ),
      ),
    );
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  Future<void> setUrlDownload(String? url, [String? fileName]) async {
    try {
      if (url != null && url.isNotEmpty) {
        Directory directory = await getApplicationDocumentsDirectory();
        await FlutterDownloader.enqueue(
          headers: {
            HttpHeaders.cookieHeader: cookiesString,
          },
          url: url.trim(),
          savedDir: directory.path,
          fileName: fileName,
          showNotification: true,
          openFileFromNotification: true,
          saveInPublicStorage: true,
        );

        Fluttertoast.showToast(
          msg: "첨부파일 다운로드를 받습니다.",
        );
      }
    } catch (e) {
      logger.e(e);
    }
  }

  void setSiteMove([String url = '']) {
    try {
      if (url.isEmpty) {
        url = WebViewApp.siteUrl;
      }

      webViewController.loadUrl(
        urlRequest: URLRequest(
          url: Uri.parse(url),
        ),
      );
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> setLogin(BuildContext context, AuthData? authData) async {
    try {
      if (authData == null) {
        return;
      }

      await user_util.setLogin(authData.token, authData.userId);
      await user_util.getUser(context, (UserData? userData) async {
        try {
          if (userData == null) {
            return;
          }

          await user_util.setUser(userData);
        } catch (e) {
          logger.e(e);
        }
      });
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> showShopItemPayment(String productDetailId) async {
    if (_loading) {
      Fluttertoast.showToast(
        msg: '아이템 정보를 가지고 오는 중..',
      );
      return;
    }

    if (!_isAvailable) {
      Fluttertoast.showToast(
        msg: '결제 시스템 연결 실패',
      );
      return;
    }

    if (productDetailId.isNotEmpty && shopItemIds.contains(productDetailId)) {
      for (var productDetails in _products) {
        if (productDetails.id == productDetailId) {
          late PurchaseParam purchaseParam;

          if (Platform.isAndroid) {
            purchaseParam = GooglePlayPurchaseParam(productDetails: productDetails);
          } else {
            final paymentWrapper = SKPaymentQueueWrapper();
            final transactions = await paymentWrapper.transactions();
            await Future.wait(transactions.map((transaction) => paymentWrapper.finishTransaction(transaction)));
            purchaseParam = PurchaseParam(productDetails: productDetails);
          }

          _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
          return;
        }
      }
    }

    Fluttertoast.showToast(
      msg: '잘못된 productDetailId 입니다',
    );
  }

  void showShopPurchasedItem() {
    if (_loading) {
      Fluttertoast.showToast(
        msg: '아이템 정보를 가지고 오는 중..',
      );
      return;
    }

    final List<ListTile> productList = <ListTile>[];

    if (_notFoundIds.isNotEmpty) {
      productList.add(
        ListTile(
          title: Text(
            '아이템 정보를 찾을 수 없습니다. [${_notFoundIds.join(", ")}]',
            style: TextStyle(color: ThemeData.light().colorScheme.error),
          ),
        ),
      );
    }

    for (ProductDetails productDetails in _products) {
      if (productDetails.id == shopItemSettingTicketId) {
        if (!user_util.isSettingTicket()) {
          continue;
        }
      } else if (productDetails.id == shopItemCommentaryTicketId) {
        if (!user_util.isCommentaryTicket()) {
          continue;
        }
      } else {
        continue;
      }

      productList.add(
        ListTile(
          title: Text(
            productDetails.title,
            style: TextStyle(color: ThemeData.light().primaryColor),
          ),
        ),
      );
    }

    if (productList.isEmpty) {
      productList.add(
        ListTile(
          title: Text(
            '이용중인 아이템이 없습니다.',
            style: TextStyle(color: ThemeData.light().disabledColor),
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 270,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  '내 아이템',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  '구독중인 아이템입니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                Column(
                  children: productList,
                ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('닫기'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
        _notFoundIds = <String>[];
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse = await _inAppPurchase.queryProductDetails(shopItemIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _loading = false;
      });

      logger.e(_queryProductError);
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _loading = false;
      });
      return;
    }

    await _inAppPurchase.restorePurchases();

    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _loading = false;
    });
  }

  bool isVerifyReceiptComplete = false;
  int verifyReceiptCount = 0;

  Future<VerifyReceiptData?> _verifyReceiptData(BuildContext context, String device, String? purchaseId, String verificationData, [String signature = '']) async {
    VerifyReceiptData? verifyReceiptData;

    try {
      if (_verifyReceiptValues.containsKey(verificationData)) {
        if (_verifyReceiptValues[verificationData] != null) {
          verifyReceiptData = _verifyReceiptValues[verificationData]!;
        }
      } else {
        logger.d(verificationData);

        isVerifyReceiptComplete = false;
        verifyReceiptCount = 0;

        await user_util.appVerifyReceipt(context, (VerifyReceiptData? data) async {
          try {
            verifyReceiptData = data;
            _verifyReceiptValues[verificationData] = verifyReceiptData;
          } catch (e) {
            logger.e(e);
          }
          isVerifyReceiptComplete = true;
        }, device, purchaseId, verificationData, signature);

        await Future.doWhile(() async {
          if (isVerifyReceiptComplete || verifyReceiptCount > 100) {
            return false;
          } else {
            verifyReceiptCount++;
            await Future.delayed(const Duration(milliseconds: 100));
            return true;
          }
        });
      }
    } catch (e) {
      logger.e(e);
    }

    return verifyReceiptData;
  }

  Future<bool> _verifyReceipt(BuildContext context, String device, String? purchaseId, String verificationData, [String signature = '']) async {
    bool result = false;

    try {
      VerifyReceiptData? verifyReceiptData = await _verifyReceiptData(context, device, purchaseId, verificationData, signature);

      if (verifyReceiptData != null) {
        int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        if (verifyReceiptData.expirationTime > currentTime) {
          result = true;
        }
      }
    } catch (e) {
      logger.e(e);
    }

    return result;
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (purchaseDetails.status == PurchaseStatus.error) {
        return false;
      }

      String? transactionDate = purchaseDetails.transactionDate;

      if (transactionDate == null || transactionDate.isEmpty) {
        throw const FormatException();
      }

      if (Platform.isIOS) {
        return await _verifyReceipt(context, 'ios', purchaseDetails.purchaseID, purchaseDetails.verificationData.localVerificationData);
      } else if (Platform.isAndroid) {
        if (purchaseDetails is GooglePlayPurchaseDetails) {
          return await _verifyReceipt(context, 'android', purchaseDetails.purchaseID, purchaseDetails.verificationData.localVerificationData, purchaseDetails.billingClientPurchase.signature);
        }
      }
    } catch (e) {
      logger.e(e);
    }

    return false;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == shopItemSettingTicketId) {
      if (!user_util.isSettingTicket()) {
        await user_util.setSettingTicket(true);
        _isDeliverUpdate = true;
      }
    } else if (purchaseDetails.productID == shopItemCommentaryTicketId) {
      if (!user_util.isCommentaryTicket()) {
        await user_util.setCommentaryTicket(true);
        _isDeliverUpdate = true;
      }
    }

    setState(() {
      _purchases.add(purchaseDetails);
    });
  }

  Future<void> _listenToPurchaseUpdated(BuildContext context, List<PurchaseDetails> purchaseDetailsList) async {
    try {
      _isDeliverUpdate = false;

      for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.status != PurchaseStatus.pending) {
          if (purchaseDetails.status == PurchaseStatus.error) {
            IAPError? error = purchaseDetails.error;
            logger.e(error);
          } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
            final bool valid = await _verifyPurchase(purchaseDetails);

            if (!valid) {
              logger.d('결제 상품 검증 체크 실패');
              continue;
            }

            await _deliverProduct(purchaseDetails);
          }

          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      }

      if (_isDeliverUpdate && user_util.isLogin()) {
        await user_util.getRefreshToken(context, (AuthData? authData) async {
          if (isInitRefreshToken) {
            await user_util.setRefreshToken(authData);
          } else {
            isInitRefreshToken = true;
            await setLogin(context, authData);
          }
          WebViewApp.lastLoadingTime = 0;
        });
      }
    } catch (e) {
      logger.e(e);
    }
  }
}

/// Example implementation of the
/// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
///
/// The payment queue delegate can be implementated to provide information
/// needed to complete transactions.
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
