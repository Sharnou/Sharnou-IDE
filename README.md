# Sharnou IDE

Sharnou IDE is the authoritative and exclusive development controller for SharnouEngine projects, including the canonical Honour War project: honour-war.

## Permanent Honour War stack

Honour War authoring and runtime control remain:

`Sharnou IDE -> SPP -> SharnouEngine -> Honour War runtime`

Canonical repositories:

- Honour War: https://github.com/Sharnou/Honour-War
- Sharnou IDE: https://github.com/Sharnou/Sharnou-IDE
- Sharnou Engine: https://github.com/Sharnou/Sharnou-Engine
- Sharnou Compiler: https://github.com/Sharnou/Sharnou-Compiler

Sharnou IDE owns project identity validation, SPP authoring, SPP compilation to engine-consumable JSON bytecode, runtime selection, self-test, runtime-test and launch control.

## Native Sharnou source compiler integration

The IDE now has an explicit, opt-in bridge for `.sharnou` source files:

`toolchain/Invoke-SharnouCompiler.ps1`

The IDE exposes this bridge through `src/SharnouIDE.ps1 -Command compile-native`. It invokes the locally checked-out Sharnou Compiler Stage 0 bootstrap and then runs the compiler repository's independent PE verifier before publishing an AMD64 PE32+ executable. The compiler source and verifier are pinned by Git blob identity in `toolchain/sharnou-compiler.contract.json`; a changed or mismatched compiler checkout is rejected.

Example (64-bit Windows PowerShell 5.1):

```powershell
.\src\SharnouIDE.ps1 -Command compile-native -NativeSource .\Examples\ControlFlow\IfElse.sharnou -NativeOutput .\Build\IfElse.exe -CompilerRoot ..\Sharnou-Compiler
```

The current compiler is a PowerShell/.NET bootstrap that emits native x64 machine code. Its repository-verified language milestone is 7A: `if`, `else`, `while`, and signed integer comparisons. This is not yet a native self-hosted `SharnouCompiler.exe`; structs, pointers, arrays, function pointers, and a self-hosted compiler remain future work.

This bridge is deliberately separate from SPP. SPP still produces `sharnou-bytecode/1` JSON for SharnouEngine. The bridge compiles `.sharnou` programs to Windows AMD64 PE32+ executables; it does not compile SPP, C++ engine sources, or produce a native `SharnouIDE.exe`.

The compiler checkout must already exist locally. Set `SHARNOU_COMPILER_ROOT` or pass `-CompilerRoot`; the IDE does not download or install a compiler or toolchain.

## Universal format intake

Sharnou IDE is format-agnostic at the input boundary. Honour War and SharnouEngine may send files in any format. The IDE detects, validates, classifies, preserves, converts/imports, and routes each input through the appropriate registered adapter.

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
