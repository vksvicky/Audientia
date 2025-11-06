# ML & AI Features

## Overview

Audientia integrates machine learning and AI features to enhance music discovery, organization, and metadata management. All ML processing is performed locally by default, with opt-in cloud enhancements for privacy-conscious users.

## Phase 1: Classical + Fingerprinting (Foundation)

### Acoustic Fingerprinting

- **Chromaprint Integration**: Generate acoustic fingerprints for tracks
- **AcoustID Lookup**: Match fingerprints against AcoustID database
- **Metadata Completion**: Auto-fill missing metadata from matched tracks
- **Implementation**:
  - Rust crate: `chromaprint` or Swift wrapper
  - Async processing for batch operations
  - Cache fingerprints in SQLite

### Audio Analysis

- **ReplayGain Calculation**: Analyze loudness for volume normalization
- **Tempo Detection**: BPM analysis for smart playlists
- **Key Detection**: Musical key identification
- **Implementation**:
  - C++ audio analysis library
  - Background processing with progress tracking

### Use Cases

- Identify unknown tracks
- Complete missing album/artist information
- Normalize playback volume
- Create tempo-based playlists

## Phase 2: Local ML Models (Core ML)

### Genre Classification

- **Model**: Core ML model trained on audio features
- **Input**: Audio spectrogram or extracted features
- **Output**: Genre probabilities (Rock, Jazz, Classical, etc.)
- **Implementation**:
  - Pre-trained model or user-trained
  - Batch processing for library analysis
  - Confidence scores for recommendations

### Mood Detection

- **Model**: Core ML model for emotional classification
- **Categories**: Happy, Sad, Energetic, Calm, etc.
- **Use Cases**:
  - Mood-based playlists
  - Time-of-day recommendations
  - Activity-based queues

### Instrument Detection

- **Model**: Multi-label classification for instruments
- **Instruments**: Guitar, Piano, Drums, Vocals, etc.
- **Use Cases**:
  - Instrument-based search
  - Similarity matching
  - Playlist generation

### Embedding Generation

- **Model**: Audio embedding model (e.g., MusicCNN)
- **Output**: High-dimensional feature vectors
- **Use Cases**:
  - Similarity search ("more like this")
  - Clustering similar tracks
  - Recommendation engine

### Implementation Details

```swift
import CoreML

class MLClassifier {
    private let genreModel: MLModel
    private let moodModel: MLModel
    
    func classifyGenre(for audioURL: URL) async throws -> GenreClassification {
        let features = try await extractFeatures(from: audioURL)
        let input = GenreClassifierInput(features: features)
        let prediction = try await genreModel.prediction(from: input)
        return GenreClassification(from: prediction)
    }
    
    func generateEmbedding(for audioURL: URL) async throws -> [Float] {
        let features = try await extractFeatures(from: audioURL)
        let input = EmbeddingModelInput(features: features)
        let prediction = try await embeddingModel.prediction(from: input)
        return prediction.embedding
    }
}
```

### Model Training (Optional)

- User can train custom models on their library
- Transfer learning from pre-trained models
- Fine-tuning for personal preferences

## Phase 3: Recommendation Engine

### Similarity-Based Recommendations

- **Algorithm**: Cosine similarity on audio embeddings
- **Features**:
  - "More like this" for any track
  - Similar album discovery
  - Artist similarity graph

### Collaborative Filtering (Local)

- **Algorithm**: User listening history analysis
- **Features**:
  - Play count weighting
  - Skip rate analysis
  - Time-of-day patterns
  - Day-of-week patterns

### Context-Aware Recommendations

- **Factors**:
  - Time of day
  - Day of week
  - Recent listening history
  - Current activity (if available)
- **Implementation**:
  - Rule-based + ML hybrid
  - Real-time playlist generation

### Smart Playlist Enhancement

- **ML-Enhanced Rules**:
  - "Similar to [track]" rule
  - "Mood: [mood]" rule
  - "Genre: [genre]" with confidence threshold
- **Dynamic Updates**: Playlists update as library grows

## Phase 4: Advanced Features (Future)

### Lyric Alignment

- **Technology**: Forced alignment algorithms
- **Use Cases**:
  - Synchronized lyrics display
  - Word-level search in lyrics
  - Karaoke mode

### Advanced Duplicate Detection

- **Technology**: Spectral similarity + fingerprinting
- **Features**:
  - Detect remixes and covers
  - Find different versions of same track
  - Identify quality differences

### Federated Learning (Opt-in)

- **Privacy-Preserving**: No data leaves device
- **Model Updates**: Aggregate improvements without sharing data
- **Benefits**: Improved models over time

### Cloud Enhancement (Opt-in)

- **Services**:
  - Enhanced metadata from cloud APIs
  - Community tagging
  - Social features (with privacy controls)
- **Privacy**: User controls what data is shared

## Privacy & Safety

### Local-First Architecture

- **Default**: All processing on-device
- **No Network**: ML features work offline
- **User Data**: Never leaves device without explicit consent

### Opt-in Cloud Features

- **Explicit Consent**: User must enable cloud features
- **Granular Control**: Choose what data to share
- **Transparency**: Clear indication of what's processed locally vs. cloud

### Data Export

- **Feature Store**: Exportable embeddings and classifications
- **Model Cards**: Documentation of model behavior
- **Dataset Provenance**: Track data sources

### Security

- **Sandboxed Execution**: ML models run in isolated environment
- **Input Validation**: Sanitize all inputs to models
- **Output Validation**: Verify model outputs are reasonable

## Performance Considerations

### Model Optimization

- **Quantization**: Reduce model size and improve speed
- **Core ML Optimization**: Use Apple's optimization tools
- **Batch Processing**: Process multiple tracks efficiently

### Caching

- **Embeddings Cache**: Store computed embeddings
- **Classification Cache**: Cache genre/mood classifications
- **Fingerprint Cache**: Store acoustic fingerprints

### Background Processing

- **Async Processing**: Don't block UI during analysis
- **Progress Tracking**: Show progress for batch operations
- **Priority Queue**: Process user-requested items first

## Testing Strategy

### Model Accuracy

- **Test Set**: Hold-out test set from diverse music library
- **Metrics**: Accuracy, precision, recall, F1-score
- **Baseline**: Compare against manual classifications

### Performance Tests

- **Latency**: Classification time < 500ms per track
- **Throughput**: Batch processing rate
- **Memory**: Memory usage during processing

### Integration Tests

- **End-to-End**: Full classification pipeline
- **Cache Behavior**: Verify caching works correctly
- **Error Handling**: Invalid inputs, corrupted models

## Roadmap

### v1.0 (Phase 1)

- ✅ Acoustic fingerprinting
- ✅ ReplayGain calculation
- ✅ Basic tempo/key detection

### v1.1 (Phase 2)

- ✅ Genre classification
- ✅ Mood detection
- ✅ Embedding generation

### v1.2 (Phase 3)

- ✅ Similarity recommendations
- ✅ Context-aware playlists
- ✅ ML-enhanced smart playlists

### v2.0 (Phase 4)

- ⏳ Lyric alignment
- ⏳ Advanced duplicate detection
- ⏳ Federated learning (opt-in)

## Implementation Examples

### Acoustic Fingerprinting Example

```swift
import Foundation

class FingerprintService {
    private let chromaprint: ChromaprintWrapper
    
    func generateFingerprint(for audioURL: URL) async throws -> String {
        return try await chromaprint.generate(audioURL: audioURL)
    }
    
    func lookupAcoustID(fingerprint: String) async throws -> AcoustIDResult? {
        let client = AcoustIDClient()
        return try await client.lookup(fingerprint: fingerprint)
    }
}
```

### Genre Classification Example

```swift
import CoreML

class GenreClassifier {
    private let model: MLModel
    
    func classify(_ audioURL: URL) async throws -> GenrePrediction {
        let features = try await extractAudioFeatures(from: audioURL)
        let input = try GenreClassifierInput(features: features)
        let prediction = try await model.prediction(from: input)
        return GenrePrediction(from: prediction)
    }
    
    private func extractAudioFeatures(from url: URL) async throws -> [Float] {
        // Extract spectrogram or other features
        // Return feature vector
    }
}
```

### Similarity Search Example

```swift
class SimilarityEngine {
    private let embeddingStore: EmbeddingStore
    
    func findSimilar(to track: Track, limit: Int = 10) async throws -> [Track] {
        guard let queryEmbedding = try await embeddingStore.getEmbedding(for: track) else {
            throw SimilarityError.noEmbedding
        }
        
        let allEmbeddings = try await embeddingStore.getAllEmbeddings()
        let similarities = allEmbeddings.map { (track, embedding) in
            (track, cosineSimilarity(queryEmbedding, embedding))
        }
        
        return similarities
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        // Calculate cosine similarity
    }
}
```

## Model Sources

### Pre-trained Models

- **Core ML Model Zoo**: Community-contributed models
- **Academic Models**: Research models converted to Core ML
- **Custom Training**: User-trained models on their library

### Model Formats

- **Core ML**: Native Apple format (.mlmodel)
- **ONNX**: Convert to Core ML if needed
- **TensorFlow Lite**: Convert to Core ML if needed

## Future Enhancements

### Real-time Analysis

- **Live Classification**: Classify tracks as they play
- **Dynamic Recommendations**: Update recommendations in real-time
- **Adaptive Playlists**: Playlists that adapt to listening patterns

### Advanced ML Features

- **Style Transfer**: Apply audio effects based on ML
- **Remix Detection**: Identify remixes and covers
- **Quality Assessment**: ML-based audio quality scoring

### Community Features

- **Shared Models**: Users can share trained models
- **Model Marketplace**: Community-contributed models
- **Collaborative Filtering**: Opt-in sharing of listening patterns
