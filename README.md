# Sharnou IDE

Sharnou IDE is the **authoritative and exclusive development controller** for Sharnou Engine projects, including Honour War.

It provides SPP authoring, validation, compilation to engine-consumable JSON bytecode, and launch/control of the Sharnou Engine runtime. The engine bridge verifies the Honour War project identity, IDE repository identity, engine identity, approved runtime paths, and no-download policy before execution.

## Permanent Honour War stack

**Sharnou IDE → SPP → Sharnou Engine → Honour War runtime**

Honour War does not use Visual Studio, MSBuild, Windows SDK development installations, CMake, vcpkg, Unity, Unreal Engine, or automatic external programming-tool downloads.

The IDE is runtime-first. It does not falsely claim that native C++ can be rebuilt without a compiler and the platform interfaces required by that compiler; it simply never installs, bootstraps, or downloads such tooling as part of the Honour War workflow.

## Engine contract

The canonical engine contract is `engine/sharnou-engine.contract.json`. Honour War is bound to `https://github.com/Sharnou/Sharnou-IDE` and the `SharnouEngine` runtime through its SPP manifest.

## Asset policy

Approved model intake: FBX/OBJ through the existing Visual RAG/reference analysis → Neural4D or Blender processing → Sharnou Engine validation flow. GLB/GLTF remains rejected.
