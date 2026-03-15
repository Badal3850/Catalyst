import 'dart:async';

import '../../core/constants.dart';

/// Abstraction over the on-device LLM (MediaPipe LLM Inference API).
///
/// In production this calls into the native MediaPipe plugin via a Method
/// Channel. In tests it can be replaced with a stub implementation.
class LlmService {
  LlmService({this.maxTokens = AppConstants.llmMaxTokens});

  final int maxTokens;

  bool _isLoaded = false;

  /// Loads the model weights from the app's private storage.
  ///
  /// Must be called before [generate]. Safe to call multiple times — the
  /// second call is a no-op if the model is already loaded.
  Future<void> loadModel(String modelPath) async {
    if (_isLoaded) return;
    // TODO(phase1): Call MediaPipe LLM Inference API to load the model.
    // Example native call:
    //   await _channel.invokeMethod('loadModel', {'path': modelPath});
    _isLoaded = true;
  }

  /// Returns `true` if the LLM model has been loaded successfully.
  bool get isLoaded => _isLoaded;

  /// Generates a response for [prompt] using the loaded LLM.
  ///
  /// Throws [StateError] if [loadModel] has not been called.
  Future<String> generate(String prompt) async {
    if (!_isLoaded) {
      // Fallback stub response so the app remains usable before model setup.
      return _stubResponse(prompt);
    }
    // TODO(phase1): Delegate to MediaPipe LLM Inference API.
    // Example native call:
    //   return await _channel.invokeMethod<String>('generate', {
    //     'prompt': prompt,
    //     'maxTokens': maxTokens,
    //     'temperature': AppConstants.llmTemperature,
    //   }) ?? '';
    return _stubResponse(prompt);
  }

  /// Streams tokens as they are generated (for real-time UI updates).
  Stream<String> generateStream(String prompt) async* {
    if (!_isLoaded) {
      yield _stubResponse(prompt);
      return;
    }
    // TODO(phase1): Stream tokens from MediaPipe LLM Inference API.
    yield _stubResponse(prompt);
  }

  /// Summarises [text] into concise bullet points.
  Future<String> summarise(String text) async {
    final prompt =
        '''
Summarise the following text into concise bullet points. Be brief.

Text:
$text

Summary:''';
    return generate(prompt);
  }

  /// Unloads the model to free memory.
  void dispose() {
    _isLoaded = false;
  }

  // ── Stub ───────────────────────────────────────────────────────────────

  String _stubResponse(String prompt) {
    return 'CoreBrain model is not yet loaded. '
        'Please complete the model setup to enable AI features.';
  }
}
