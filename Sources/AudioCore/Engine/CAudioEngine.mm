//
//  CAudioEngine.mm
//  AudioCore
//
//  C++ Audio Engine Implementation - AVFoundation Bridge
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#include "CAudioEngine.h"
#include <string>

// Objective-C bridge class for AVFoundation (must be at global scope)
@interface AVAudioEngineBridge : NSObject
@property (nonatomic, strong) AVAudioPlayer* player;
@property (nonatomic, assign) float volume;

- (BOOL)loadFile:(NSString*)filePath;
- (BOOL)play;
- (void)pause;
- (void)stop;
- (BOOL)seekTo:(NSTimeInterval)position;
- (NSTimeInterval)getPosition;
- (NSTimeInterval)getDuration;
- (void)setVolume:(float)volume;
- (float)getVolume;
- (BOOL)isPlaying;
- (BOOL)isPaused;
- (BOOL)isStopped;

@end

@implementation AVAudioEngineBridge

- (instancetype)init {
    self = [super init];
    if (self) {
        _player = nil;
        _volume = 1.0f;
    }
    return self;
}

- (BOOL)loadFile:(NSString*)filePath {
    if (self.player) {
        [self.player stop];
        self.player = nil;
    }
    
    NSURL* url = [NSURL fileURLWithPath:filePath];
    if (!url) {
        return NO;
    }
    
    NSError* error = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (!self.player || error) {
        return NO;
    }
    
    self.player.volume = self.volume;
    self.player.enableRate = YES;
    return YES;
}

- (BOOL)play {
    if (!self.player) {
        return NO;
    }
    return [self.player play];
}

- (void)pause {
    if (self.player && self.player.isPlaying) {
        [self.player pause];
    }
}

- (void)stop {
    if (self.player) {
        [self.player stop];
        self.player.currentTime = 0.0;
    }
}

- (BOOL)seekTo:(NSTimeInterval)position {
    if (!self.player) {
        return NO;
    }
    if (position < 0.0 || position > self.player.duration) {
        return NO;
    }
    self.player.currentTime = position;
    return YES;
}

- (NSTimeInterval)getPosition {
    if (!self.player) {
        return 0.0;
    }
    return self.player.currentTime;
}

- (NSTimeInterval)getDuration {
    if (!self.player) {
        return 0.0;
    }
    return self.player.duration;
}

- (void)setVolume:(float)volume {
    _volume = MAX(0.0f, MIN(1.0f, volume));
    if (self.player) {
        self.player.volume = _volume;
    }
}

- (float)getVolume {
    return _volume;
}

- (BOOL)isPlaying {
    return self.player ? self.player.isPlaying : NO;
}

- (BOOL)isPaused {
    if (!self.player) {
        return NO;
    }
    return !self.player.isPlaying && self.player.currentTime > 0.0;
}

- (BOOL)isStopped {
    return !self.player || (!self.player.isPlaying && self.player.currentTime == 0.0);
}

@end

// C++ Implementation (after Objective-C code)
namespace audientia {
namespace audio {

/// Private implementation using PIMPL idiom
class CAudioEngine::Impl {
public:
    Impl() : bridge([[AVAudioEngineBridge alloc] init]), volume(1.0f) {
    }
    
    ~Impl() {
        // ARC will handle cleanup
        bridge = nil;
    }
    
    AVAudioEngineBridge* __strong bridge;
    float volume;
};

CAudioEngine::CAudioEngine() : pImpl(std::make_unique<Impl>()) {
}

CAudioEngine::~CAudioEngine() = default;

CAudioEngine::CAudioEngine(CAudioEngine&&) noexcept = default;
CAudioEngine& CAudioEngine::operator=(CAudioEngine&&) noexcept = default;

bool CAudioEngine::loadFile(const std::string& filePath) {
    if (!pImpl->bridge) {
        return false;
    }
    NSString* nsPath = [NSString stringWithUTF8String:filePath.c_str()];
    return [pImpl->bridge loadFile:nsPath];
}

bool CAudioEngine::play() {
    if (!pImpl->bridge) {
        return false;
    }
    return [pImpl->bridge play];
}

void CAudioEngine::pause() {
    if (pImpl->bridge) {
        [pImpl->bridge pause];
    }
}

void CAudioEngine::stop() {
    if (pImpl->bridge) {
        [pImpl->bridge stop];
    }
}

bool CAudioEngine::seekTo(double position) {
    if (!pImpl->bridge) {
        return false;
    }
    return [pImpl->bridge seekTo:position];
}

double CAudioEngine::getPosition() const {
    if (!pImpl->bridge) {
        return 0.0;
    }
    return [pImpl->bridge getPosition];
}

double CAudioEngine::getDuration() const {
    if (!pImpl->bridge) {
        return 0.0;
    }
    return [pImpl->bridge getDuration];
}

void CAudioEngine::setVolume(float volume) {
    pImpl->volume = MAX(0.0f, MIN(1.0f, volume));
    if (pImpl->bridge) {
        [pImpl->bridge setVolume:pImpl->volume];
    }
}

float CAudioEngine::getVolume() const {
    return pImpl->volume;
}

bool CAudioEngine::isPlaying() const {
    if (!pImpl->bridge) {
        return false;
    }
    return [pImpl->bridge isPlaying];
}

bool CAudioEngine::isPaused() const {
    if (!pImpl->bridge) {
        return false;
    }
    return [pImpl->bridge isPaused];
}

bool CAudioEngine::isStopped() const {
    if (!pImpl->bridge) {
        return true;
    }
    return [pImpl->bridge isStopped];
}

} // namespace audio
} // namespace audientia
