import 'dart:typed_data';

import '../../core/constants.dart';

/// Converts text into a dense vector representation for semantic search.
///
/// In production this runs a lightweight sentence-transformer model on-device
/// (e.g. via TensorFlow Lite). The stub returns a zero-vector so that the
/// rest of the app remains usable before the embedding model is configured.
class EmbeddingService {
  EmbeddingService({
    this.dimension = AppConstants.embeddingDimension,
  });

  /// Number of dimensions in the output embedding vector.
  final int dimension;

  bool _isLoaded = false;

  /// Loads the embedding model from [modelPath].
  Future<void> loadModel(String modelPath) async {
    if (_isLoaded) return;
    // TODO(phase2): Load sentence-transformer TFLite model.
    _isLoaded = true;
  }

  bool get isLoaded => _isLoaded;

  /// Returns an embedding vector for [text].
  ///
  /// The returned [Float32List] has length [dimension].
  Future<Float32List> embed(String text) async {
    if (!_isLoaded) {
      return Float32List(dimension); // zero-vector stub
    }
    // TODO(phase2): Run TFLite inference to produce a real embedding.
    return _stubEmbed(text);
  }

  /// Embeds a list of [texts] in a single batch for efficiency.
  Future<List<Float32List>> embedBatch(List<String> texts) async {
    final results = <Float32List>[];
    for (final text in texts) {
      results.add(await embed(text));
    }
    return results;
  }

  void dispose() {
    _isLoaded = false;
  }

  // ── Stub ───────────────────────────────────────────────────────────────

  /// Produces a deterministic stub embedding based on string hash.
  Float32List _stubEmbed(String text) {
    final vector = Float32List(dimension);
    final hash = text.hashCode;
    for (var i = 0; i < dimension; i++) {
      vector[i] = ((hash ^ (hash >> i)) & 0xFF) / 255.0;
    }
    return vector;
  }
}
