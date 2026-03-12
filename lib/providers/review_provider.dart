import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _reviews = await _service.fetchAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> hide(String id) => _run(() => _service.hide(id));
  Future<bool> unhide(String id) => _run(() => _service.unhide(id));
  Future<bool> reply(String id, String text) => _run(() => _service.reply(id, text));
  Future<bool> deleteReview(String id) => _run(() => _service.deleteReview(id));

  Future<bool> _run(Future<void> Function() cb) async {
    _errorMessage = null;
    try {
      await cb();
      await loadReviews();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
