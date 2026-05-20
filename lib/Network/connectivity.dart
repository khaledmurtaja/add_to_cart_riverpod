import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';

enum NetworkStatus { Online, Offline }

class NetworkStatusService extends ChangeNotifier {
  StreamController<NetworkStatus> networkStatusController =
      StreamController<NetworkStatus>();

  Future<bool> isDeviceConnected() async {
    var status = await Connectivity().checkConnectivity();
    // print(status);
    switch (status[0]) {
      case ConnectivityResult.mobile:
        return true;
      case ConnectivityResult.wifi:
        return true;
      case ConnectivityResult.none:
        return false;
      default:
        return false;
    }
  }

  NetworkStatus _networkStatus = NetworkStatus.Offline;

  NetworkStatus get networkStatus => _networkStatus;

  NetworkStatusService() {
    /// Check the network status when the app starts
    Connectivity().checkConnectivity().then((status) {
      _networkStatus = getNetworkStatus(status.first);
      notifyListeners();
    });
    Connectivity().onConnectivityChanged.listen((status) {
      for (var i = 0; i < status.length; i++) {
        print('Network Status: ${status[i]}');
      }
      networkStatusController.add(getNetworkStatus(status.first));
      _networkStatus = getNetworkStatus(status.first);
      notifyListeners();
    });
  }

  NetworkStatus getNetworkStatus(ConnectivityResult status) {
    switch (status) {
      case ConnectivityResult.mobile:
        return NetworkStatus.Online;
      case ConnectivityResult.wifi:
        return NetworkStatus.Online;
      case ConnectivityResult.none:
        return NetworkStatus.Offline;
      default:
        return NetworkStatus.Offline;
    }
  }

  set networkStatus(NetworkStatus value) {
    _networkStatus = value;
    notifyListeners();
  }
}
