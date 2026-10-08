import 'package:flutter/material.dart';

/// Global observer so feed players can pause while another route covers them.
final RouteObserver<ModalRoute<dynamic>> appRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();
