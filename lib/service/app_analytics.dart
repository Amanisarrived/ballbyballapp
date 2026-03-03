import 'package:firebase_analytics/firebase_analytics.dart';

// ════════════════════════════════════════════════════════════
//  BALLBYBALL ANALYTICS SERVICE
//  Single place for all tracking — easy to manage & extend
//
//  Usage:
//    AppAnalytics.screenView('home');
//    AppAnalytics.tapButton('shop_banner');
//    AppAnalytics.predictorVote('India', 'poll_123');
// ════════════════════════════════════════════════════════════
class AppAnalytics {
  static final _fa = FirebaseAnalytics.instance;

  // ══════════════════════════════════════════════════════════
  //  SCREEN VIEWS
  //  Call these in each screen's initState
  // ══════════════════════════════════════════════════════════
  static Future<void> screenView(String screenName) async {
    await _fa.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // Predefined screen names — avoids typos
  static Future<void> screenHome()       => screenView('home');
  static Future<void> screenNews()       => screenView('news');
  static Future<void> screenHighlights() => screenView('highlights');
  static Future<void> screenShop()       => screenView('shop');
  static Future<void> screenFixtures()   => screenView('fixtures');
  static Future<void> screenFixtureDetail(String matchName) =>
      screenView('fixture_detail_$matchName');
  static Future<void> screenLiveScore()  => screenView('live_score');

  // ══════════════════════════════════════════════════════════
  //  APP OPENS  (auto-tracked by Firebase, but log custom too)
  // ══════════════════════════════════════════════════════════
  static Future<void> appOpen() async {
    await _fa.logAppOpen();
  }

  // ══════════════════════════════════════════════════════════
  //  BUTTON TAPS
  // ══════════════════════════════════════════════════════════
  static Future<void> tapButton(String buttonName,
      {String? screen, String? extra}) async {
    await _fa.logEvent(
      name: 'button_tap',
      parameters: {
        'button_name': buttonName,
        if (screen != null) 'screen': screen,
        if (extra != null) 'extra': extra,
      },
    );
  }

  // Common button taps — call directly
  static Future<void> tapShopItem(String itemName) =>
      tapButton('shop_item', extra: itemName);

  static Future<void> tapShopBanner() =>
      tapButton('shop_banner', screen: 'home');

  static Future<void> tapNewsBanner() =>
      tapButton('news_banner', screen: 'home');

  static Future<void> tapFestivalBanner() =>
      tapButton('festival_banner', screen: 'home');

  static Future<void> tapNewsArticle(String title) =>
      tapButton('news_article', extra: title);

  static Future<void> tapHighlight(String title) =>
      tapButton('highlight', extra: title);

  static Future<void> tapFixtureCard(String matchName) =>
      tapButton('fixture_card', extra: matchName);

  static Future<void> tapShareApp() =>
      tapButton('share_app');

  static Future<void> tapNotificationBell() =>
      tapButton('notification_bell', screen: 'home');

  // ══════════════════════════════════════════════════════════
  //  NOTIFICATION CLICKS
  // ══════════════════════════════════════════════════════════
  static Future<void> notificationReceived(String type) async {
    await _fa.logEvent(
      name: 'notification_received',
      parameters: {'notification_type': type},
    );
  }

  static Future<void> notificationOpened({
    required String type,
    String? title,
  }) async {
    await _fa.logEvent(
      name: 'notification_opened',
      parameters: {
        'notification_type': type,
        if (title != null) 'title': title,
      },
    );
  }

  // Notification types
  static Future<void> notificationMatchStart(String match) =>
      notificationOpened(type: 'match_start', title: match);

  static Future<void> notificationBreakingNews(String title) =>
      notificationOpened(type: 'breaking_news', title: title);

  static Future<void> notificationSale() =>
      notificationOpened(type: 'sale');

  static Future<void> notificationFestival(String name) =>
      notificationOpened(type: 'festival', title: name);

  // ══════════════════════════════════════════════════════════
  //  WIN PREDICTOR
  // ══════════════════════════════════════════════════════════
  static Future<void> predictorShown(String pollId) async {
    await _fa.logEvent(
      name: 'predictor_shown',
      parameters: {'poll_id': pollId},
    );
  }

  static Future<void> predictorVote({
    required String teamVoted,
    required String pollId,
    required String opponent,
  }) async {
    await _fa.logEvent(
      name: 'predictor_vote',
      parameters: {
        'team_voted':  teamVoted,
        'poll_id':     pollId,
        'opponent':    opponent,
      },
    );
  }

  static Future<void> predictorSkipped(String pollId) async {
    await _fa.logEvent(
      name: 'predictor_skipped',
      parameters: {'poll_id': pollId},
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SHOP ENGAGEMENT
  // ══════════════════════════════════════════════════════════
  static Future<void> shopItemClicked({
    required String itemName,
    required String category,
    required String platform, // 'amazon' | 'flipkart'
  }) async {
    await _fa.logSelectItem(
      itemListName: category,
      items: [
        AnalyticsEventItem(
          itemName: itemName,
          itemCategory: category,
        ),
      ],
    );
    // Also log platform
    await _fa.logEvent(
      name: 'shop_item_click',
      parameters: {
        'item_name': itemName,
        'category':  category,
        'platform':  platform,
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SEARCH
  // ══════════════════════════════════════════════════════════
  static Future<void> search(String query) async {
    await _fa.logSearch(searchTerm: query);
  }

  // ══════════════════════════════════════════════════════════
  //  USER PROPERTIES  (set once, persists across sessions)
  //  Call after login or on first open
  // ══════════════════════════════════════════════════════════
  static Future<void> setUserProperties({
    String? favouriteTeam,
    String? appVersion,
  }) async {
    if (favouriteTeam != null) {
      await _fa.setUserProperty(
          name: 'favourite_team', value: favouriteTeam);
    }
    if (appVersion != null) {
      await _fa.setUserProperty(
          name: 'app_version', value: appVersion);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  OBSERVER  — for automatic screen tracking via Navigator
  //  Add to MaterialApp navigatorObservers
  // ══════════════════════════════════════════════════════════
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _fa);
}