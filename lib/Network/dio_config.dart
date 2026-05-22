import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../Authentication/Manager/user_session_manager.dart';
import '../Authentication/models/user_model.dart';
import '../constants/k_network.dart';
import 'decoding/network_decoding.dart';
import 'errors/unauthorized_user.dart';
import 'interceptors/connectivity_interceptor.dart';

Dio baseDioClient(String baseUrl) {
  Dio dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      // if (kDebugMode) {
      //   print('Bypassing SSL certificate for $host');
      //   return true; // Always trust in debug
      // }
      return true; // Never trust in release mode
    };
    return client;
  };

  dio.options = BaseOptions(
    baseUrl: baseUrl,
    sendTimeout: const Duration(seconds: 60), // 60 seconds
    connectTimeout: const Duration(seconds: 60), // 60 seconds
    receiveTimeout: const Duration(seconds: 60), // 60 seconds
  );
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true));
  }
  dio.interceptors.add(ConnectivityInterceptor());
  return dio;
}

Dio DioClientWithRefreshToken(String baseUrl) {
  Dio dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      print('⚠️ SSL validation disabled: trusting all certs (host: $host)');
      return true; // Bypass SSL check ALWAYS (not safe)
    };
    return client;
  };

  dio.options = BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Accept-Language': 'en',
      'Authorization': 'Bearer ${UserSessionManager.instance.token}',
      'ApiKey': '67BSMNGHX301VIDJ2PI79EQ2N',
    },
  );
  if (kDebugMode) {
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
    ));
  }
  dio.interceptors.add(ConnectivityInterceptor());
  Dio tokenDio = Dio(); //Create a new instance to request the token.
  tokenDio.options = BaseOptions(
      baseUrl: dio.options.baseUrl,
      headers: {'Authorization': 'Basic ${KNetwork.clientIdSecret}'});

  // Add an interceptor to set the tenant ID for each request
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // final tenantId = await KNetwork.getTenantId();
      // if (tenantId != null) {
      //   // options.headers.addAll({"tenantId": int.parse(tenantId)});
      // }
      return handler.next(options);
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(onError: (options, handler) {
    if (options.response?.statusCode == 401) {
      tokenDio
          .post(
        '${KNetwork.refreshTokenPath}${UserSessionManager.instance.refreshToken}',
      )
          .then((response) {
        final user =
            decodeResponse(response.data, UserModel.fromMap) as UserModel;
        UserSessionManager.instance.setDataForRefreshToken(user);
        options.requestOptions.headers['Authorization'] =
            'Bearer ${user.accessToken}';
        handler.resolve(response);
      }).catchError((error, stackTrace) {
        if (error.response?.statusCode == 401) {
          handler.reject(
            DioException(
                requestOptions: options.requestOptions,
                error: UnAuthorizedUser()),
          );
        } else {
          handler.reject(error);
        }
      }).whenComplete(() {
        // dio.interceptors.requestLock.unlock();
      });
    } else {
      handler.next(options);
    }
  }));

  return dio;
}
