# Sharnou IDE Production Roadmap

Status: Proposed canonical implementation roadmap
Target: Windows 10/11 x64 first
Primary role: Exclusive project authoring, compiler orchestration and runtime-control IDE for Sharnou Engine and Honour War
Authority: Sharnou Compiler and Sharnou Engine contracts

This roadmap describes the work required to evolve the current PowerShell-driven IDE tooling into a production Sharnou IDE. It is a plan, not a claim that a native IDE application, debugger or full asset pipeline already exists.

## 1. Product objective

Sharnou IDE is the single authoring and runtime-control environment for the Sharnou stack:

Sharnou IDE -> Sharnou Project Protocol (SPP) -> Sharnou Compiler / Runtime -> Sharnou Engine -> Honour War

The IDE must provide a coherent workflow for source editing, project management, compiler diagnostics, deterministic builds, asset intake and cooking, runtime launch, debugging, profiling and release packaging. It must use versioned Sharnou contracts and must not silently delegate compilation or runtime control to another IDE or compiler.

The first production target is Windows x64. Console support is a separate platform project and must not be implied by a Windows build.

## 2. Current repository baseline

| Capability | Observed repository state | What is not yet proven |
|---|---|---|
| IDE entry point | PowerShell launcher and src/SharnouIDE.ps1 are present | A production native SharnouIDE.exe is not established by this source tree. |
| SPP authoring | JSON project protocol and SPP compilation scripts are present | Full schema evolution, validation diagnostics and incremental project graph guarantees need dedicated tests. |
| Compiler bridge | Opt-in compile-native bridge invokes the pinned Stage 0 bootstrap and independent PE verifier | It does not imply a self-hosted native compiler, C++ compilation or a native IDE executable. |
| Engine bridge | EngineBridge.ps1 validates contracts and launches an already-existing approved runtime | It cannot build the Engine when the required Sharnou compiler executable is absent. |
| Asset automation | Universal intake and automation architecture are documented | Each adapter, converter, job state transition, cache rule and corruption path must be verified individually. |
| CI | Windows policy, path, compiler-bridge and AVIF-policy tests are checked in | These checks do not demonstrate a complete interactive editor, full asset cooker, debugger or production packaging. |

The compiler bridge currently pins an immutable Stage 0 compiler source identity. Its contract correctly records that the bootstrap is not self-hosted. The IDE must keep that distinction visible until the compiler's native bootstrap fixed-point gate passes.

## 3. P0 - Resolve cross-repository contracts before feature expansion

There is a material asset-contract mismatch in the current repositories:

- The Engine integration contract identifies glTF/GLB as runtime 3D scene containers, KTX2 plus KHR_texture_basisu as runtime 3D textures, and AVIF as 2D/UI visuals.
- The current IDE Honour War SPP manifest and some IDE documentation still specify AVIF-only raster output and reject GLB/GLTF as Honour War runtime assets.
- The IDE-to-Engine bridge validates the glTF/GLB + KTX2 + AVIF contract, so the contracts are not yet consistently represented across all IDE files.

The target shared asset contract for the stack is:

| Role | Canonical runtime representation | Rule |
|---|---|---|
| 3D scenes and models | .gltf / .glb (glTF 2.x) | Geometry, nodes, transforms, skins and scene structure. |
| 3D GPU material textures | .ktx2 | Basis Universal path with required glTF extension KHR_texture_basisu where referenced. |
| 2D/UI/raster visuals | .avif | Icons, UI, 2D art and other raster visuals. |
| Authoring/interchange models | .fbx / .obj and registered inputs | Import-only; preserve original source and convert through an explicit adapter before runtime packaging. |

P0 deliverables:
- Define one versioned machine-readable asset contract with an owner and schema version.
- Align IDE SPP, IDE EngineBridge, Engine integration JSON, Engine policy and Honour War manifest with that contract through coordinated PRs.
- Treat acceptance of an input format separately from the formats actually supported by the runtime.
- Require explicit KTX2 transcode/decode capability checks; container recognition alone is not runtime texture support.
- Require AVIF decoder capability checks; do not assume every Windows image stack has an AVIF decoder.
- Preserve imported originals, write outputs atomically, hash all inputs/outputs and reject path traversal or root escape.
- Add positive and negative fixtures for unsupported extensions, malformed containers, missing dependencies, wrong MIME/signatures and corrupted cache entries.

Exit gate: all three repositories parse and validate the same contract version, with tests proving the same format decisions. Until then, the shared asset policy is Blocked for production use.

## 4. I1 - Reliable project model and build orchestration

Deliverables:
- A versioned SPP schema for project identity, source roots, target platform, compiler version, engine version, asset roots, build profiles and startup scene.
- Schema validation with stable error codes and file/line/path diagnostics.
- Dependency graph for source files, modules, generated assets and build outputs.
- Incremental build planner based on content hashes and explicit dependency edges.
- Atomic output publication: build into a temporary directory, validate outputs, then replace the prior build.
- Build manifest recording source commit, toolchain contracts, input hashes, compiler arguments, output hashes and test status.
- Cancellation, progress, retry policy and safe cleanup of stale temporary files.
- A command-line/headless mode that runs the same validation and build pipeline as the graphical IDE.

Acceptance:
- Clean checkout opens and validates a sample project.
- Repeated unchanged builds do not regenerate unchanged outputs.
- A changed dependency rebuilds only its transitive dependants.
- Interrupted or failed builds never replace the last known-good output.
- Malformed SPP and invalid paths fail closed with actionable diagnostics.

## 5. I2 - Native IDE application shell and editing workflow

Deliverables:
- Native Windows application executable produced through the Sharnou toolchain; no PowerShell window is the final product UI.
- Project browser, source editor, tabs, split views, file search and navigation.
- Syntax highlighting driven by a versioned Sharnou grammar.
- Dockable diagnostics, build output, asset browser, runtime console and task panels.
- Keyboard navigation, scalable DPI layout, high-contrast themes and configurable input.
- Session restore that never overwrites source files or reopens unsafe external paths.
- Crash-safe settings and workspace persistence.

Acceptance:
- The native IDE starts from a clean installation and opens a project without another IDE installed.
- Large workspaces remain responsive through virtualization and background indexing.
- All editing features support undo/redo, unsaved-change indicators and atomic saves.
- Accessibility settings are available without a project-specific workaround.

Do not mark this milestone complete while the only editor surface is a PowerShell launcher.

## 6. I3 - Compiler-aware language services

Deliverables:
- A stable compiler service contract for compile, check, diagnostics, cancellation and version queries.
- Structured diagnostics with severity, stable code, source span, related locations and optional fix-it data.
- Syntax tree or semantic index API from the Sharnou compiler.
- Symbol outline, go-to-definition, find references, rename and import navigation.
- Completion and signature help based on compiler semantic information, not string guessing.
- Formatting and refactoring only after grammar and formatting rules are versioned.
- Project-level language configuration and source encoding checks.

Acceptance:
- The editor and command-line compiler report the same diagnostics for the same source revision.
- Every language service is tested against valid, invalid, incomplete and large source fixtures.
- Compiler version mismatch is explicit; the IDE must not silently use an unpinned compiler.

## 7. I4 - Dependency-aware asset automation

The asset pipeline is a job graph rather than a collection of opaque batch conversions.

Required job model:
- job_id, project_id, adapter_id, job_type and schema version;
- source path, source SHA-256, detected format and metadata;
- target format, output path and output SHA-256;
- tool/adapter version and input parameters;
- dependency job IDs, engine contract identity and cache key;
- queued/running/succeeded/failed/cancelled state;
- diagnostics, timestamps and provenance.

Required adapters and pipeline stages:
1. Intake, safe file identification, metadata and source preservation.
2. Model/scene import and glTF/GLB validation.
3. KTX2 container validation and supported Basis Universal transcode path.
4. AVIF validation and supported decode/encode path for 2D/UI assets.
5. Material and dependency resolution, including KHR_texture_basisu references.
6. Mesh/texture optimization, compression and LOD generation where the format contract supports it.
7. Asset manifest generation, SHA-256 validation, content-addressed cache and package assembly.
8. Incremental rebuild, stale-output detection and cache corruption recovery.

Acceptance:
- Every adapter has positive/negative fixtures, limits, fuzzable parser boundaries and deterministic output rules.
- Source files are never deleted by conversion.
- Jobs are restartable and idempotent.
- Cache reuse requires matching input hash, adapter version, parameters and target contract.
- Unsupported or unavailable decoders return an explicit blocked state, never a fabricated success.

## 8. I5 - Engine launch, runtime testing and evidence

Deliverables:
- Pinned Engine contract and verified compiler/Engine versions.
- Runtime discovery limited to approved Sharnou build locations.
- Separate validate, self-test, runtime-test, run and package commands.
- Structured capture of stdout, stderr, exit code, crash status and runtime log path.
- Test scene registry and repeatable smoke tests.
- Evidence capture from the actual running executable only.
- Real frame/image capture with metadata identifying executable hash, scene, settings, resolution, GPU and driver.
- Runtime test duration must be a validated positive parameter; no hidden fixed timeout.

Acceptance:
- Missing runtime or compiler fails closed and offers the exact missing dependency.
- IDE does not download an unapproved toolchain or launch a foreign Engine.
- A gameplay or rendering PASS requires the real executable to run the relevant test scene.
- Static screenshots, generated mock images and policy scans are never accepted as runtime evidence.

## 9. I6 - Debugging and profiling

Deliverables:
- Documented debug-information format emitted by the Sharnou compiler.
- Breakpoints, continue, step-in/over/out, call stack, locals and exception/crash details.
- Register and memory inspection only where the target and debug metadata safely support it.
- CPU frame, task, allocation and asset-streaming profiler.
- D3D11 GPU timing, pass timing, resource lifetime and render-target inspection.
- Trace export with source revision and build-manifest identity.
- Remote debugging protocol only after authentication, transport security and version negotiation are specified.

Acceptance:
- Debugger source locations match the compiled binary and immutable source revision.
- Tests cover breakpoint mapping, stepping through nested calls, optimized code limitations and crash recovery.
- Profiling numbers include hardware, driver, scene, resolution and measurement method.

## 10. I7 - Packaging, updates and operational reliability

Deliverables:
- Signed or otherwise verifiable package manifest, compiler/IDE/Engine version pins and SHA-256 checks.
- Small bootstrap installer with large optional content fetched only when explicitly required by the approved update design.
- Content-addressed cache, interrupted-download recovery and offline launch when required assets are already cached.
- Rollback to the last known-good IDE/compiler/Engine tuple.
- Logs and crash reports with secret/path scrubbing.
- Project migration tooling with dry-run and backup.
- Windows 10 x64 baseline validation; later Windows versions tested separately.

Acceptance:
- Clean machine install, update, rollback and offline launch tests pass.
- Corrupt or mismatched packages are rejected before execution.
- No project or source asset is silently deleted or rewritten during update/migration.
- The bootstrap and installed runtime sizes are measured from actual packages, not estimates.

## 11. CI and evidence gates

Every IDE PR:
- PowerShell syntax and policy checks for remaining bootstrap scripts.
- SPP schema/contract validation.
- Compiler bridge positive and negative tests using the pinned compiler source.
- Engine contract and path-resolution tests.
- Asset-format policy tests with representative fixtures.
- Clean-workspace and deterministic project-build tests as those capabilities are implemented.

Scheduled/nightly lanes:
- Full adapter regression corpus.
- Incremental build correctness and cache corruption recovery.
- Clean installation and upgrade/rollback.
- Runtime self-test and real render capture on a suitable Windows runner.
- GPU tests must report unavailable when no D3D11-capable interactive runner is available; they must not pass as skipped.

## 12. Definition of done

Sharnou IDE is production-capable when it is a native, independently launchable application; validates and edits real Sharnou projects; builds through a pinned self-hosted Sharnou compiler; manages deterministic project and asset dependency graphs; launches and tests the actual Sharnou Engine; supports debugging and profiling; packages reproducible outputs; and can recover from failed builds, corrupted assets and interrupted updates.

The complete IDE-to-Engine workflow must be demonstrated in a clean Windows x64 environment with repository commits, workflow run IDs, test totals and artifact hashes. A working PowerShell bridge alone is an integration milestone, not the finished IDE.