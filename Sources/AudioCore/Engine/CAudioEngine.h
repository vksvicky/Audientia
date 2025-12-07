//
//  CAudioEngine.h
//  AudioCore
//
//  C++ Audio Engine Header - Bridge to AVFoundation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#ifndef CAudioEngine_h
#define CAudioEngine_h

#include <memory>
#include <string>

namespace audientia {
namespace audio {

/// C++ Audio Engine class
/// Provides low-level audio playback using AVFoundation via Objective-C++
/// bridge
class CAudioEngine {
public:
  CAudioEngine();
  ~CAudioEngine();

  // Delete copy constructor and assignment operator
  CAudioEngine(const CAudioEngine &) = delete;
  CAudioEngine &operator=(const CAudioEngine &) = delete;

  // Move constructor and assignment operator
  CAudioEngine(CAudioEngine &&) noexcept;
  CAudioEngine &operator=(CAudioEngine &&) noexcept;

  /// Load an audio file for playback
  /// @param filePath Path to the audio file
  /// @return true if file loaded successfully, false otherwise
  bool loadFile(const std::string &filePath);

  /// Start playback
  /// @return true if playback started successfully, false otherwise
  bool play();

  /// Pause playback
  void pause();

  /// Stop playback and reset position
  void stop();

  /// Seek to a specific position
  /// @param position Position in seconds
  /// @return true if seek successful, false otherwise
  bool seekTo(double position);

  /// Get current playback position in seconds
  /// @return Current position
  double getPosition() const;

  /// Get total duration in seconds
  /// @return Duration, or 0.0 if no file loaded
  double getDuration() const;

  /// Set playback volume (0.0 to 1.0)
  /// @param volume Volume level
  void setVolume(float volume);

  /// Get current volume (0.0 to 1.0)
  /// @return Current volume
  float getVolume() const;

  /// Set playback rate (0.5 to 2.0 for AVAudioPlayer, higher rates may be
  /// clamped)
  /// @param rate Playback rate multiplier
  void setRate(float rate);

  /// Get current playback rate
  /// @return Current playback rate
  float getRate() const;

  /// Check if engine is currently playing
  /// @return true if playing, false otherwise
  bool isPlaying() const;

  /// Check if engine is paused
  /// @return true if paused, false otherwise
  bool isPaused() const;

  /// Check if engine is stopped
  /// @return true if stopped, false otherwise
  bool isStopped() const;

private:
  class Impl;
  std::unique_ptr<Impl> pImpl;
};

} // namespace audio
} // namespace audientia

#endif /* CAudioEngine_h */
