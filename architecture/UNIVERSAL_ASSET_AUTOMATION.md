# Sharnou IDE Universal Asset Automation

## Purpose

Sharnou IDE is the format-agnostic intake and automation controller for SharnouEngine projects.

The IDE accepts source material in any file format supplied by Honour War or SharnouEngine. Acceptance at the IDE boundary does not mean every format is rendered natively. The IDE identifies the source format, validates it, selects an internal or approved adapter, converts or imports it when required, validates the result, and hands the canonical runtime representation to SharnouEngine.

## Canonical relationship

Honour War -> Sharnou IDE -> SharnouEngine -> Honour War runtime

The IDE must identify Honour War by its canonical project id: honour-war.

## Automatic job router

For every new, changed, or requested asset/project file:

1. Detect format from content and extension.
2. Classify it as source, intermediate, runtime, document, script, shader, model, texture, audio, video, archive, data, or unknown.
3. Validate the file before processing.
4. Select the registered Sharnou IDE adapter.
5. Preserve the original source file.
6. Generate the required intermediate representation.
7. Apply Honour War output policy when the destination is the Honour War runtime.
8. Validate the generated representation with SharnouEngine.
9. Record provenance, source hash, generated hash, adapter, and validation result.
10. Notify the IDE workspace and Honour War project graph.
11. Never download an external programming tool to complete the job.

## Format policy

### IDE intake

The IDE boundary is intentionally unrestricted.

Images: PNG, JPEG, JPG, BMP, TIFF, TGA, GIF, WebP, AVIF, HEIF/HEIC, and other registered image formats.

Models: OBJ, FBX, GLTF, GLB, DAE, STL, PLY, and other registered model formats.

Audio: WAV, OGG, MP3, FLAC, AAC, and other registered audio formats.

Video: MP4, WebM, MKV, AVI, MOV, and other registered video formats.

Data: JSON, YAML, TOML, XML, CSV, binary packs, and registered Honour War data formats.

Source/scripts: any registered language or plain-text source format.

Archives: ZIP and other registered package formats.

Unknown files: preserve and route to inspection rather than discard.

### Honour War runtime output

The existing Honour War runtime policy remains authoritative. Runtime conversion occurs in the IDE pipeline before SharnouEngine validation.

For Honour War raster textures, the canonical runtime texture output remains .AVIF.

For model intake, FBX/OBJ remain approved source formats for the existing Visual RAG/reference analysis -> Neural4D/Blender processing -> SharnouEngine validation path. GLB/GLTF are not accepted as Honour War runtime assets.

This distinction is deliberate: Sharnou IDE accepts any source format; Honour War runtime still has a canonical output contract.

## Automatic project jobs

The IDE automatically creates or updates jobs for:

- asset import and format inspection
- asset conversion
- texture canonicalization
- model validation
- material dependency resolution
- shader/source validation
- SPP generation and compilation
- project graph synchronization
- SharnouEngine runtime discovery
- engine compatibility validation
- dependency/provenance indexing
- incremental rebuild of affected assets
- stale-output detection
- runtime smoke validation
- real-runtime evidence capture
- failure diagnostics and repair suggestions

Jobs are dependency-aware and incremental. Unchanged inputs are not regenerated.

## Safety and independence

The automation layer must not:

- download Visual Studio
- download MSBuild
- download Windows SDK development packages
- download Unity
- download Unreal Engine
- bootstrap CMake/vcpkg
- silently invoke an unrelated IDE
- replace Honour War with another project
- delete the original source asset during conversion

The IDE may use only capabilities already implemented in Sharnou IDE/SharnouEngine or explicitly registered local adapters.

## Job record

Each automatic operation should be representable as:

job_id
project_id
source_path
source_format
source_sha256
job_type
adapter_id
target_format
target_path
target_sha256
engine_contract
status
diagnostics
created_at
completed_at

This makes conversions reproducible and allows Honour War and SharnouEngine to request work from Sharnou IDE without manual format-specific intervention.
