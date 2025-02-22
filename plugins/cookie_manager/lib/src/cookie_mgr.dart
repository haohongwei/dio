import 'dart:async';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

/// Don't use this class in Browser environment
class CookieManager extends Interceptor {
  /// Cookie manager for http requests。Learn more details about
  /// CookieJar please refer to [cookie_jar](https://github.com/flutterchina/cookie_jar)
  final CookieJar cookieJar;

  List<Cookie> golableCookie = [] ;

  CookieManager(this.cookieJar);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // cookieJar.loadForRequest(options.uri).then((cookies) {
      var cookie = getCookies(golableCookie);
      // var cookie = getCookies(cookies);
      if (cookie.isNotEmpty) {
        options.headers[HttpHeaders.cookieHeader] = cookie;
      }
      handler.next(options);
    // }).catchError((e, stackTrace) {
    //   var err = DioError(requestOptions: options, error: e);
    //   err.stackTrace = stackTrace;
    //   handler.reject(err, true);
    // });
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _saveCookies(response)
        .then((_) => handler.next(response))
        .catchError((e, stackTrace) {
      var err = DioError(requestOptions: response.requestOptions, error: e);
      err.stackTrace = stackTrace;
      handler.reject(err, true);
    });
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _saveCookies(err.response!)
          .then((_) => handler.next(err))
          .catchError((e, stackTrace) {
        var _err = DioError(
          requestOptions: err.response!.requestOptions,
          error: e,
        );
        _err.stackTrace = stackTrace;
        handler.next(_err);
      });
    } else {
      handler.next(err);
    }
  }

  Future<void> _saveCookies(Response response) async {
    var cookies = response.headers[HttpHeaders.setCookieHeader];
    var requestCookies = response.requestOptions.headers[HttpHeaders
        .cookieHeader];

    if (cookies != null) {
      var cookiesList = cookies.map((str) => Cookie.fromSetCookieValue(str))
          .toList();
      var requestCookiesList = cookies.map((str) =>
          requestCookies.fromSetCookieValue(str)).toList();
      for (var cookie in cookiesList) {
        if (cookie.domain == null) {
          cookie.domain = response.requestOptions.uri.host;
        }
      }
      for (var cookie in cookiesList) {
        bool cookieItemUpdated = false;
        for (var current in requestCookiesList) {
          if (cookie.name == current.name) {
            current.value = cookie.value;
            cookieItemUpdated = true;
            break;
          }
          if(cookieItemUpdated == false){
            golableCookie.add(cookie);
          }
        }
        await cookieJar.saveFromResponse(
          response.requestOptions.uri,
          cookies.map((str) => Cookie.fromSetCookieValue(str)).toList(),
        );
      }
    }
  }

  static String getCookies(List<Cookie> cookies) {
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }
}
