# Sharnou IDE

Sharnou IDE is the **authoritative and exclusive development controller** for SharnouEngine projects, including the canonical Honour War project `honour-war`.

## Permanent Honour War stack

**Sharnou IDE → SPP → SharnouEngine → Honour War runtime**

Canonical repositories:

- Honour War: `https://github.com/Sharnou/Honour-War`
- Sharnou IDE: `https://github.com/Sharnou/Sharnou-IDE`
- Sharnou Engine: `https://github.com/Sharnou/Sharnou-Engine`

Sharnou IDE owns project identity validation, SPP authoring, SPP compilation to engine-consumable JSON bytecode, runtime selection, self-test, runtime-test and launch control.

## Rejected development dependencies

Honour War does not use, invoke, install, bootstrap or download Visual Studio, MSBuild, Windows SDK development installations, CMake, vcpkg, Unity, Unreal Engine or other external programming tools.

Legacy IDE/project metadata is migration input only. The IDE conversion target is Sharnou-IDE SPP; legacy IDEs are not runtime controllers.

## AVIF-only visual output

All newly generated or converted raster textures/visuals for Honour War use `.avif` only. The SPP compiler validates `texture_avif` operations and rejects non-AVIF raster paths.

Approved model intake remains FBX/OBJ through Visual RAG/reference analysis → Neural4D or Blender processing → SharnouEngine validation. GLB/GLTF remains rejected.

## Runtime-first rule

The IDE may launch only an already-existing approved SharnouEngine runtime. It never downloads or installs a compiler, SDK, IDE, build system or runtime dependency.

A gameplay PASS requires actual executable runtime evidence; static policy validation is not gameplay evidence.
