// PERMISSIONS: https://pub.dev/packages/permission_handler
// flutter pub add permission_handler

import 'package:permission_handler/permission_handler.dart';

class Perm {
  //<uses-permission android:name="android.permission.CAMERA" />
  //<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  //<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  //<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  //<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  //<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  //<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  //<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
  //<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

  static Future<bool> request(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  static Future<bool> requestAll(List<Permission> permissions) async {
    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  static Future<bool> isActive(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  //<uses-permission android:name="android.permission.CAMERA" />
  static Future<bool> getCamera() async {
    return await request(Permission.camera);
  }

  //<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  //<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  static Future<bool> getStorage() async {
    return await request(Permission.storage);
  }

  //<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  //<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  static Future<bool> getLocation() async {
    return await request(Permission.location);
  }

  //<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  static Future<bool> getNotification() async {
    return await request(Permission.notification);
  }

  //<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  static Future<bool> getPhotos() async {
    return await request(Permission.photos);
  }

  //<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  static Future<bool> getMediaLibrary() async {
    return await request(Permission.mediaLibrary);
  }

  //<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
  // Android 11+
  // Permission to access all files on the device
  static Future<bool> getManageExternalStorage() async {
    return await request(Permission.manageExternalStorage);
  }
}
