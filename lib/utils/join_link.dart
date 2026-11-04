class JoinLink {
  static const _webOrigin = 'https://snap2bill.vercel.app/';

  static String forRoom(String roomId) {
    final query = Uri(queryParameters: {'roomId': roomId}).query;
    return '$_webOrigin#/join?$query';
  }

  static bool isJoinUri(Uri uri) {
    if (uri.scheme == 'snap2bill' && uri.host == 'join') return true;
    final routeUri = _routeUri(uri);
    return routeUri.path == '/join' || _hasJoinQuery(routeUri.queryParameters);
  }

  static String? roomIdFromUri(Uri uri) {
    final routeUri = _routeUri(uri);
    final queryParameters = routeUri.queryParameters;
    final queryId =
        queryParameters['roomId'] ??
        queryParameters['billId'] ??
        queryParameters['roomCode'] ??
        queryParameters['room_code'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final routeSegments = routeUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (uri.scheme == 'snap2bill' && uri.host == 'join') {
      return routeSegments.isEmpty ? null : routeSegments.last;
    }
    if (routeUri.path == '/join' && routeSegments.length > 1) {
      return routeSegments.last;
    }
    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host == 'join' &&
        routeSegments.isNotEmpty) {
      return routeSegments.last;
    }
    return null;
  }

  static Uri _routeUri(Uri uri) {
    final fragmentUri = Uri.tryParse(uri.fragment);
    if (fragmentUri != null &&
        (fragmentUri.path == '/join' ||
            _hasJoinQuery(fragmentUri.queryParameters))) {
      return fragmentUri;
    }
    return uri;
  }

  static bool _hasJoinQuery(Map<String, String> queryParameters) =>
      queryParameters.containsKey('roomId') ||
      queryParameters.containsKey('billId') ||
      queryParameters.containsKey('roomCode') ||
      queryParameters.containsKey('room_code');
}
