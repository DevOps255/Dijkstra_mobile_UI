import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

enum MobileMoneyPermissionStatus { granted, denied, permanentlyDenied }

@lazySingleton
class MobileMoneyPermissionService {
  Future<MobileMoneyPermissionStatus> requestAll() async {
    final statuses = await [
      Permission.sms,
      Permission.phone,
    ].request();

    final smsStatus = statuses[Permission.sms];
    final phoneStatus = statuses[Permission.phone];

    if (smsStatus == null || phoneStatus == null) {
      return MobileMoneyPermissionStatus.denied;
    }

    if (smsStatus.isPermanentlyDenied || phoneStatus.isPermanentlyDenied) {
      return MobileMoneyPermissionStatus.permanentlyDenied;
    }

    if (smsStatus.isGranted && phoneStatus.isGranted) {
      return MobileMoneyPermissionStatus.granted;
    }

    return MobileMoneyPermissionStatus.denied;
  }

  Future<bool> hasAllPermissions() async {
    final sms = await Permission.sms.status;
    final phone = await Permission.phone.status;
    return sms.isGranted && phone.isGranted;
  }

  Future<void> openSystemSettings() => openAppSettings();
}
