import 'package:flutter/material.dart';

import '../service/banner_image_service.dart';


class BannerProvider extends ChangeNotifier {
  List<String> _banners = [];
  bool _isLoading = false;

  List<String> get banners => _banners;
  bool get isLoading => _isLoading;

  Future<void> loadBanners() async {
    _isLoading = true;
    notifyListeners();

    _banners = await BannerService.fetchBanners();

    _isLoading = false;
    notifyListeners();
  }
}