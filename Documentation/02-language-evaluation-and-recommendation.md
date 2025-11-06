# Language Evaluation and Recommendation

## Candidates Considered
- Go (backend): mature, fast, simple concurrency, great for servers. Existing project: Navidrome (Go), Subsonic-compatible.
- Rust (desktop shell via Tauri, native modules): safe, fast, small binaries.
- TypeScript + React (UI): rich ecosystem, rapid development, component model.
- Alternatives (not chosen as primary): C#/.NET (excellent desktop on Windows but weaker cross-platform UX without extra work), Electron-only (heavier runtime, larger footprint), Python (excellent scripting but slower for core backend).

## Comparison (high level)
- Performance: Rust ≈ Go > C# ≈ TS/Electron > Python
- Cross-platform UX: Tauri (Rust+TS) > Electron (TS) > WinForms/WPF (Windows-centric)
- Concurrency/networking: Go > Rust (steeper learning) > C# > TS
- Ecosystem fit: Go for streaming/media server (Navidrome); TS/React for UI; Rust for native desktop shell (Tauri) and DSP.

## Recommendation
- Backend: Go, reusing/integrating `navidrome/navidrome` where possible (Subsonic API, indexing, streaming). Extend via plugins/services.
- Desktop: Tauri (Rust) shell + React/TypeScript UI for a lightweight native app.
- Optional: Rust crates for audio analysis (fingerprinting, replaygain) and performant tagging helpers.
- Rationale: Best mix of performance, reuse, and developer productivity.
