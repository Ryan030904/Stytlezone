import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _service = FeedbackService();

  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FeedbackModel> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFeedbacks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _feedbacks = await _service.fetchAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reply(String id, String text) => _run(() => _service.reply(id, text));
  Future<bool> close(String id) => _run(() => _service.close(id));
  Future<bool> reopen(String id) => _run(() => _service.reopen(id));
  Future<bool> deleteFeedback(String id) => _run(() => _service.deleteFeedback(id));

  Future<bool> _run(Future<void> Function() cb) async {
    _errorMessage = null;
    try {
      await cb();
      await loadFeedbacks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
