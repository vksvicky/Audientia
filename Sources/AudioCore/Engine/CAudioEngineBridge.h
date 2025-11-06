//
//  CAudioEngineBridge.h
//  AudioCore
//
//  C++ to Swift Bridge Header
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#ifndef CAudioEngineBridge_h
#define CAudioEngineBridge_h

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointer type for C++ engine
typedef void *CAudioEngineRef;

// C interface for Swift interop
CAudioEngineRef CAudioEngineCreate(void);
void CAudioEngineDestroy(CAudioEngineRef engine);

int CAudioEngineLoadFile(CAudioEngineRef engine, const char *filePath);
int CAudioEnginePlay(CAudioEngineRef engine);
void CAudioEnginePause(CAudioEngineRef engine);
void CAudioEngineStop(CAudioEngineRef engine);
int CAudioEngineSeekTo(CAudioEngineRef engine, double position);

double CAudioEngineGetPosition(CAudioEngineRef engine);
double CAudioEngineGetDuration(CAudioEngineRef engine);

void CAudioEngineSetVolume(CAudioEngineRef engine, float volume);
float CAudioEngineGetVolume(CAudioEngineRef engine);

int CAudioEngineIsPlaying(CAudioEngineRef engine);
int CAudioEngineIsPaused(CAudioEngineRef engine);
int CAudioEngineIsStopped(CAudioEngineRef engine);

#ifdef __cplusplus
}
#endif

#endif /* CAudioEngineBridge_h */
