// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';
import "package:redis_client/redis_client.dart";

import '../lib/controller.dart';

const Map headers = const {HttpHeaders.CONTENT_TYPE: 'application/json'};

RedisClient redisClient;

main(List<String> args) async {
  var parser = new ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8080');

  var result = parser.parse(args);

  var port = int.parse(result['port'], onError: (val) {
    stdout.writeln('Could not parse port value "$val" into a number.');
    exit(1);
  });

  Map<String, String> envVars = Platform.environment;
  var dockerHost = envVars['REDIS_PORT_6379_TCP_ADDR'] ?? '192.168.59.103';

  var connectionString = "$dockerHost:6379";
  redisClient = await RedisClient.connect(connectionString);

  var ctrl = new UrlShortenerController(redisClient);

  Router routes = router()
    ..get('/', ctrl.index)
    ..get('/{id}', ctrl.redirectUrl)
    ..post('/', ctrl.createShortUrl);

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(routes.handler);

  io.serve(handler, InternetAddress.ANY_IP_V4, port).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}
