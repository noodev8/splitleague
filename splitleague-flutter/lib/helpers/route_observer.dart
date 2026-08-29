/*
One shared RouteObserver, so a screen can be told when it comes back into view.

Why this exists rather than just awaiting Navigator.push:

  The screens inside a league (players, fixtures, standings, details) are siblings. Moving
  between them is a `pushReplacement` - a sideways move, not a deeper one - which keeps the
  stack two deep and lets Back mean "leave this league".

  But `pushReplacement` completes the replaced route's popped-future immediately. So the
  dashboard's `await Navigator.push(...)` returned the instant the user tapped a tab inside
  the league, not when they came back out. The dashboard would refresh far too early and
  then show a stale card - a league reset back to setup still reading "In play", say.

  `didPopNext` fires when the route above is actually popped, whatever that route has been
  replaced with in the meantime, which is the question the dashboard is really asking.

Registered on MaterialApp in main.dart. Mix RouteAware into a screen's State, subscribe in
didChangeDependencies, unsubscribe in dispose.
*/

import 'package:flutter/material.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();
