//
//  CAudioEngineBridge.cpp
//  AudioCore
//
//  C++ to Swift Bridge Implementation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#include "CAudioEngineBridge.h"
#include "CAudioEngine.h"
#include <memory>

extern "C" {

CAudioEngineRef CAudioEngineCreate(void) {
  auto *engine = new audientia::audio::CAudioEngine();
  return reinterpret_cast<CAudioEngineRef>(engine);
}

void CAudioEngineDestroy(CAudioEngineRef engine) {
  if (engine) {
    delete reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  }
}

int CAudioEngineLoadFile(CAudioEngineRef engine, const char *filePath) {
  if (!engine || !filePath) {
    return 0;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->loadFile(std::string(filePath)) ? 1 : 0;
}

int CAudioEnginePlay(CAudioEngineRef engine) {
  if (!engine) {
    return 0;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->play() ? 1 : 0;
}

void CAudioEnginePause(CAudioEngineRef engine) {
  if (engine) {
    auto *cppEngine =
        reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
    cppEngine->pause();
  }
}

void CAudioEngineStop(CAudioEngineRef engine) {
  if (engine) {
    auto *cppEngine =
        reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
    cppEngine->stop();
  }
}

int CAudioEngineSeekTo(CAudioEngineRef engine, double position) {
  if (!engine) {
    return 0;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->seekTo(position) ? 1 : 0;
}

double CAudioEngineGetPosition(CAudioEngineRef engine) {
  if (!engine) {
    return 0.0;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->getPosition();
}

double CAudioEngineGetDuration(CAudioEngineRef engine) {
  if (!engine) {
    return 0.0;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->getDuration();
}

void CAudioEngineSetVolume(CAudioEngineRef engine, float volume) {
  if (engine) {
    auto *cppEngine =
        reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
    cppEngine->setVolume(volume);
  }
}

float CAudioEngineGetVolume(CAudioEngineRef engine) {
  if (!engine) {
    return 1.0f;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->getVolume();
}

void CAudioEngineSetRate(CAudioEngineRef engine, float rate) {
  if (engine) {
    auto *cppEngine =
        reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
    cppEngine->setRate(rate);
  }
}

float CAudioEngineGetRate(CAudioEngineRef engine) {
  if (!engine) {
    return 1.0f;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->getRate();
}

int CAudioEngineIsPlaying(CAudioEngineRef engine) {
  if (!engine) {
    return 0;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->isPlaying() ? 1 : 0;
}

int CAudioEngineIsPaused(CAudioEngineRef engine) {
  if (!engine) {
    return 0;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->isPaused() ? 1 : 0;
}

int CAudioEngineIsStopped(CAudioEngineRef engine) {
  if (!engine) {
    return 1;
  }
  auto *cppEngine = reinterpret_cast<audientia::audio::CAudioEngine *>(engine);
  return cppEngine->isStopped() ? 1 : 0;
}

} // extern "C"
