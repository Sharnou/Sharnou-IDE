# Sharnou IDE

Sharnou IDE is the authoritative authoring environment for Sharnou Engine projects.

It provides SPP authoring, validation, compilation to engine-consumable JSON bytecode, and launch/control of an existing Sharnou Engine runtime.

Policy: no Visual Studio, no MSBuild, no Windows SDK installation, no CMake/vcpkg bootstrap, no Unity/Unreal dependency, and no automatic external programming-tool downloads.

Native-build boundary: rebuilding native C/C++ source intrinsically requires a compiler and platform interfaces. Sharnou IDE does not falsely claim otherwise. Runtime-first authoring and validation can operate without downloading another programming environment.

The IDE shell uses the Windows-provided PowerShell/WPF runtime and delegates gameplay execution to Sharnou Engine.