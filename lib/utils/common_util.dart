import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patox/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';

bool isPermanentlyDenied = false;

Future<bool> isPermission(List<Permission> permissionList) async {
  try {
    isPermanentlyDenied = false;

    for (var permission in permissionList) {
      PermissionStatus status = await permission.status;

      if (!status.isGranted && !status.isLimited) {
        isPermanentlyDenied = status.isPermanentlyDenied;
        return false;
      }
    }

    return isPermanentlyDenied;
  } catch (e) {
    logger.e(e);
    return false;
  }
}

Future<bool> setPermission(List<Permission> permissionList) async {
  try {
    isPermanentlyDenied = false;
    Map<Permission, PermissionStatus> statuses = await permissionList.request();

    for (var permission in permissionList) {
      PermissionStatus? status = statuses[permission];

      if (status == null) {
        continue;
      }

      if (!status.isGranted && !status.isLimited) {
        isPermanentlyDenied = status.isPermanentlyDenied;
        return false;
      }
    }

    return true;
  } catch (e) {
    logger.e(e);
    return false;
  }
}

Future<void> checkPermission(BuildContext context, List<Permission> permissionList, [String msg = '']) async {
  try {
    if (!(await isPermission(permissionList)) && !isPermanentlyDenied) {
      if (msg.isEmpty) {
        msg = '권한이 필요합니다.';
      }

      displayMessageDialog(context, '확인', msg, '', () {
        requestPermission(context, permissionList, msg);
      });
    }
  } catch (e) {
    logger.e(e);
  }
}

Future<void> requestPermission(BuildContext context, List<Permission> permissionList, [String msg = '']) async {
  try {
    if (!(await setPermission(permissionList)) && !isPermanentlyDenied) {
      if (msg.isEmpty) {
        msg = '권한이 필요합니다.';
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('$msg\n설정을 확인 하세요.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('설정하기'),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    logger.e(e);
  }
}

displayDialog(BuildContext context, String title, String content, List<Widget> actions) {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      ),
    );
  } catch (e) {
    logger.e(e);
  }
}

displayMessageDialog(BuildContext context, String title, String content, [String buttonLabel = '', Function? callback]) {
  try {
    displayDialog(
      context,
      title,
      content,
      [
        TextButton(
          child: Text(buttonLabel.isEmpty ? MaterialLocalizations.of(context).okButtonLabel : buttonLabel),
          onPressed: () {
            try {
              Navigator.pop(context);

              if (callback != null) {
                callback();
              }
            } catch (e) {
              logger.e(e);
            }
          },
        ),
      ],
    );
  } catch (e) {
    logger.e(e);
  }
}
