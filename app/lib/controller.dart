import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';
import "package:redis_client/redis_client.dart";

const Map headers = const {HttpHeaders.CONTENT_TYPE: 'application/json'};

class UrlShortenerController {
  RedisClient redisClient;

  UrlShortenerController(this.redisClient);

  index(_) {
    return new shelf.Response.ok(
        "Use post method to shorten a url. Body must be: {\"url\": <\"url_to_shorten\">}");
  }

  Future<shelf.Response> redirectUrl(shelf.Request request) async {
    String id = getPathParameter(request, 'id');
    String value = await redisClient.get(id);
    if (value != null) {
      return new shelf.Response.movedPermanently(value);
    } else {
      return new shelf.Response.notFound('Not a valid shortened url');
    }
  }

  Future<shelf.Response> createShortUrl(shelf.Request request) async {
    var body = await request.readAsString();

    try {
      var url = JSON.decode(body)['url'];

      String id = new DateTime.now().millisecondsSinceEpoch.toRadixString(36);

      await redisClient.set(id, "${url}");

      return new shelf.Response.ok(
          JSON.encode({'url': url, 'shortened': '$id'}),
          headers: headers);
    } catch (_) {
      throw new shelf.Response(HttpStatus.BAD_REQUEST,
          body: {'error': 'body malformed'});
    }
    return new shelf.Response.ok("nothing to do");
  }
}
