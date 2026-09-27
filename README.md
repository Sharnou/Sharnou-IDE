# Sharnou IDE

Sharnou IDE is the authoritative and exclusive development controller for SharnouEngine projects, including the canonical Honour War project: honour-war.

## Permanent Honour War stack

Sharnou IDE -> SPP -> SharnouEngine -> Honour War runtime

Canonical repositories:

- Honour War: https://github.com/Sharnou/Honour-War
- Sharnou IDE: https://github.com/Sharnou/Sharnou-IDE
- Sharnou Engine: https://github.com/Sharnou/Sharnou-Engine

Sharnou IDE owns project identity validation, SPP authoring, SPP compilation to engine-consumable JSON bytecode, runtime selection, self-test, runtime-test and launch control.

## Universal format intake

Sharnou IDE is format-agnostic at the input boundary. Honour War and SharnouEngine may send files in any format. The IDE detects, validates, classifies, preserves, converts/imports, and routes each input through the appropriate registered adapter.

The IDE accepts common image, model, audio, video, data, source, archive and binary formats, plus future registered formats and unknown files for inspection.

Input acceptance is not the same as native runtime support. If SharnouEngine requires another representation, Sharnou IDE performs the required transformation before handing the result to the engine.

See architecture/UNIVERSAL_ASSET_AUTOMATION.md for the automation contract.

## Automatic Honour War / SharnouEngine jobs

The IDE automatically handles requested work originating from either Honour War or SharnouEngine:

- import and format inspection
- conversion and canonicalization
- model/material validation
- texture processing
- dependency resolution
- SPP generation/compilation
- project graph synchronization
- SharnouEngine compatibility checks
- incremental rebuilds
- stale-output detection
- runtime smoke tests
- real-runtime evidence capture
- diagnostics and repair suggestions
- provenance and source/output hashing

Original source assets are preserved.

## Honour War runtime output policy

The IDE input boundary accepts any format, while the canonical Honour War runtime contract remains enforced.

For Honour War raster textures, canonical runtime output remains .AVIF.

Approved model intake remains FBX/OBJ through Visual RAG/reference analysis -> Neural4D or Blender processing -> SharnouEngine validation. GLB/GLTF remains rejected as a Honour War runtime asset.

This separation allows Sharnou IDE to be universal without weakening the existing Honour War runtime contract.

## Rejected development dependencies

Honour War does not use, invoke, install, bootstrap or download Visual Studio, MSBuild, Windows SDK development installations, CMake, vcpkg, Unity, Unreal Engine or other external programming tools.

Legacy IDE/project metadata is migration input only. Legacy IDEs are not runtime controllers.

The IDE must not silently download or install a compiler, SDK, IDE, build system or runtime dependency.

## Runtime-first rule

The IDE may launch only an already-existing approved SharnouEngine runtime.

A gameplay PASS requires actual executable runtime evidence; static policy validation is not gameplay evidence.
