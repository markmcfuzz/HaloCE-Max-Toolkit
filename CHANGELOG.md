# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-09-24
### Added
- Initial release

## [2.0.0] - 2025-11-11
### Added
- Colision Geometry Importer
- Physics Importer
### Fixed
- Warnings and errors on JMS / JMA exporters

## [2.1.0] - 2025-11-11
### Fixed
- **Collision Importer:** Function loading timing issue causing "undefined" errors on fresh 3ds Max sessions.
- **Collision Importer:** False error reporting where successful imports incorrectly triggered fallback methods.
- **Collision Importer:** Temporary file cleanup now works in both success and failure scenarios.
- **Collision Importer:** Enhanced error logging and status messages for better troubleshooting.
- **Collision Importer:** Added mechanism for MaxScript function loading (5 attempts with delays)

## [2.2.0] - 2025-11-12
### Added
- **Physics Importer:** Automatic Node Linking - Links mass points to `frame`, `b_`, and `bip01` nodes if existing in the scene.
- **Physics Importer:** Orientation - Uses forward/up vectors from physics data for proper mass points rotation.
- **Physics Importer:** Custom Attributes Panel - Complete mass point data display in Modify panel including name, node index, linked node, powered mass point reference, mass/density values, and friction properties.
- **Physics Importer:** Color-Coded Spheres - Visual distinction by friction type (Orange=Point, Cyan=Forward, Magenta=Left, Green=Up, Yellow=Unknown).
- **JMS Exporter:** Converts Editable Poly objects to Editable Mesh for export and restores them afterward with it's modifiers (only skin info supported).

### Fixed
- **Physics Importer:** Binary Reading - Enhanced physics tag parsing with proper mass point structure handling.

## [3.0.0] - 2025-11-13
### Added
- **GBX/Model Importer:** New implemented importer for Halo CE GBX/Model files.
- **Model Collision Geometry Importer:** New implemented importer for Halo CE Model Collision Geometry.
- Utility module for general functions and tag metadata.

### Changed
- Phyton modules were removed and all functionality was ported to MaxScript.
- Modularized MaxScript codebase for better organization and maintainability.
- **Physics Importer:** Various improvements and refactoring for better performance and maintainability.

## [3.1.0] - 2025-11-16
### Added
- **Physics Importer:** Clears the MaxScript listener before and after import for better visibility of messages.
- **Physics Importer:** Garbage Collection before loading modules to clear old structs from memory.
- New config.ms module for globals settings.
- Implemented logger instead "format" for better message handling.
- **Model Collision Geometry Importer:** Named selections for objects based on their region names.

### Fixed
- **GBX/Model Importer:** Optimized file reading for increased import speed.
- **GBX/Model Importer:** Duplicated geometries with models containing one LOD only.
- **GBX/Model Importer:** Asign the objects to the correct layers based on their type. (e.g., "Physics", "Geometry Model", "Nodes").
- **GBX/Model Importer:** Multi-region models missing triangles due to incorrect vertex `index 0` handling during triangle strip conversion.

### Changed
- **global_functions:** Renamed read_utils.ms to utils.ms and tag_classes.ms to tag_metadata.ms
- **Utils:** Move general utilities in a global struct for better organization.

## [3.5.0] - 2025-11-25

### Added
- New implemented tag reader for **Shader Model** tags.
- **GBX/Model Importer:** Added support for automatic texture application to materials on imported geometries.
- Decompress functions to utils.ms for handling compressed vertex data.
- **Physics Importer:** Assigned mass point spheres to a `Physics` layer.
- **Model Collision Geometry Importer:** Assigned geometries to a `Collision Model` layer.

### Fixed
- **Utils:** Fixed issue where the reflexiveData struct was not being properly instantiated, leading to errors when reading reflexive data.
- **Model Collision Geometry Importer:** Lost permutation names on imported collision geometries.
- Increased speed of various file reading and build operations across gbx,collision and physics importers.

### Changed
- GBX/Model, Model Collision Geometry and Physics Importer code refactor bases on structs for better readability and maintainability.
- Silence import success/failure message boxes in physics/collision importer to reduce interruptions.

## [3.5.1] - 2025-12-02

### Fixed
- **Physics Importer:** Attributes panel wasn't displaying the mass and density values correctly.
- **Model Collision Geometry Importer:** Crash when importing collision geometry with empty BSP data.
- **GBX/Model Importer:** 
  - Enhanced vertex format support with automatic validation for Halo Custom Edition and MCC files. Intelligently compares formats to select the most reliable data for optimal performance and accuracy.
  - Implemented local node indices remapping for correct vertex skinning with part-specific bone assignments.
  - Fixed UV coordinate format error preventing texture mapping (Point2 to Point3 conversion).

### Changed
- **Model Collision Geometry Importer:** Collision geometry now can be imported without requiring a pre-existing node hierarchy.
  - When no hierarchy is found, a new node named `frame root` is automatically created, and all imported geometry is attached to it.
  - This workflow is primarily intended for single-node collision setups or missing gbxmodel.
- **GBX/Model Importer:** Create bones for all nodes, spheres are disabled for now.

## [3.6.0] - 2025-12-06

### Added
- **JMS Exporter:** Complete rewrite from scratch with significant performance and stability improvements.
  - **8× faster** on typical models (e.g., cyborg model with all LODs: **1.1 s** vs **8.92 s**).
  - **3.3× faster** on large models (e.g., 60K-polygon models: **~15 s** vs **50 s**).
  - Optimized file writing with batched output.
  - Improved memory management for complex scenes.
  - More accurate normal calculation using smoothing groups.
  - Skin weight data is now pre-cached for faster processing and more reliable bone assignments.
  - **New regions workflow:**
    - Supports `Named Selection Sets` for region assignment.
    - Face-based region selection remains fully compatible.
  - Exporting directly from `Editable Poly` is now supported. No need to convert to `Editable Mesh`, even for collision geometry and structure bsp open-edge errors will no longer appear.
- **GBX/Model Importer:** Support for Named Selection Sets based on region names for automatized region when importing models.

### Fixed
- **GBX/Model Importer:** Bone orientation by applying quaternion directly in node hierarchy linking.

## [3.6.1] - 2025-12-07

### Fixed
- **JMS Exporter:**
  - Incorrect rotation when exporting skinned editable mesh/poly.
  - Incorrect position when exporting editable mesh linked to a root node.
- **GBX/Model | Collision Importer:**
  - Prevents `Named Selection Sets` from being overwritten when importing multiple models with the same region names.
    - Now when you import a model, it checks if a selection set with that region name already exists, and if it does, it adds the new objects to it instead of replacing the entire set and losing the previously imported objects.

## [3.6.2] - 2025-12-08

### Fixed
- **JMS Exporter:** Region `__unnamed` was created even when all objects were assigned to a selection set (`region`).

## [3.6.3] - 2025-12-08

### Fixed
- **JMS Exporter:** Support for biped object.

### Changed
- **GBX/Model Importer:** Smoothing groups set to 1 for all faces. There is no reliable solution to restore the smoothing groups in an accurate way.

## [3.7.0] - 2025-12-12

### Added
- **Animation Exporter:** New implemented exporter for Halo CE Animation files.
  - Support for node keyinfo:
    - **Geomobject:**
      - `Standard Primitives`
      - `Extended Primitives`
    - **Helpers:** 
      - `Bone`
      - `CAT Object`
      - `Biped Object`
- **Object Builder (global functions):**
  - Introduced a **helper-based marker system**
    - Startup script to add the helpers in the create panel.
    - Find it under `Create` > `Helpers` > `Halo CE` > [`HCE Marker` | `HCE Physics`]
    - Customizable **radius** (1:1 with Halo CE), and **color**.
    - **Name text box:** write the marker name and press enter to add the prefix. (e.g., `marker_01 + enter key` > `#marker_01`, `masspoint_01 + enter key` > `+masspoint_01`)
- **JMS Exporter:** 
  - Support export for: 
    - `CAT Object`
    - `Marker Helper-based`
      - _Markers based on spheres are still supported._
- **GBX/Model Importer | Collision Importer:**
  - Support creation for:
    - `Marker Helper-based`
      - _Markers based on spheres are deprecated._
- **Sphere to Helper Conversion Tool:** 
  - New utility to convert existing sphere marker objects to marker helpers.
    - Found under `Halo CE Toolkit` > `Tools` > `Sphere to Helper Converter`
    - Preserves position, scale, and custom properties.
    - Assign the helpers in a `Markers` layer
### Fixed
- **Physics Importer:** Update collect nodes in the scene from a global function in utils that add more prefix node names.
- **GBX/Model Importer:** Global function in utils to check prefix node names and converting to bones.
- **JMS Exporter:** Validation for exclude markers that are physics/pathfinding (`+`) and must be parent in a node with a geometry on it.
### Changed
- **Utils:** 
  - Moved common file writing functions for reuse across exporters.
  - Check if an object is a marker (names starting with `#` or `+`).
  - Check if an object is a physics marker (names starting with `+` just for an exclusion).

## [4.0.0] - 2025-12-15
### Changed
- Major Refactor:
  - Complete migration of the distribution system:
  - The **`.mzp`** format used in previous versions has been abandoned.
  - The project is now distributed as an **Application Package** with an `.exe` installer.
  - Files are automatically installed in `AppData\Roaming\Autodesk\ApplicationPlugins`.
- Users with earlier versions (≤3.7.0) must manually uninstall the `.mzp` file before installing the new version.
  - Starting with this version, all updates will be made via the **plugin package** system.

### Fixed
- Max version detection to maintain support in 2023–2026.
  - Previous versions to 2023 may not work, depending on the MaxScript API changes. Reporting issues is appreciated.

## [4.0.1] - 2026-01-25
### Fixed
- **Shader Model:**
  - Reading shader model empty paths. (This fix some cases with the gbxmodel importer where the `shader_model` tag has empty texture paths that caused the textures `tif/png` never import correctly even if the files exist in the correct path in data folder).
### Added
- **Gbx/Model Importer:**
  - Support for containers/helpers in the node hierarchy for organize several objects. This was a petition from a user.
    - Usage: Create a container with the symbol `/` as prefix name (e.g., `/my_container`) and link objects to it, (geometrys, markers etc).

## [4.1.0] - 2026-01-29
### Added
- **GBX/Model Importer:**
  - Support for read more shader types.
    - > _(before only `shader_model` were supported)._
    - New supported shaders:
      - `shader_transparent_chicago`
      - `shader_transparent_chicago_extended`
      - `shader_transparent_generic`
      - `shader_transparent_glass`
      - `shader_transparent_meter`
      - `shader_transparent_water`
  - Basic material configuration in 3ds Max for transparent shaders. 
    - > _(In the future, I plan to recreate the Halo CE shaders in 3ds Max as much as possible.)_
  - Support for `.bmp`, `.tga` and `.dds` texture formats in addition to existing `.tif` and `.png` support.

## [4.2.0] - 2026-01-31
### Added
- **JMS Importer**
  - Add new tool to import JMS files.
  - Check all the features [**Here**](https://github.com/markmcfuzz/HaloCE-Max-Toolkit/wiki/Import-Tools#jms-importer)
- **JMS Exporter:**
  - Support extended metadata check details [**Here**](https://github.com/markmcfuzz/HaloCE-Max-Toolkit/wiki/Export-Tools#6-export-extended-metadata)
- **Utils:**
  - New general functions for read and write extended metadata in jms files.
### Fixed
- **GBX/Model Importer**
  - Issues with reading shader modules:
    - `shader_model`
    - `shader_transparent_glass`

## [4.2.1] - 2026-02-02
### Changed
- **JMS Importer:**
  - Added smoothing group import: 
    - Reads smoothing groups from extended metadata section
  - Removed Shader/bitmap paths section in extended metadata no longer read (obsolete format) and now uses the field below shader name to write the bitmap path.
  - Support for modern JMS format:
    - JMS files exported from fbx-to-jms tool and Blender toolset.
      - Skeleton hierarchy now builds correctly.
    - > _Too old JMS files are not supported anymore. Use the `JMS Format Converter` utility to update them._
### Fixed
- Support for 3ds Max 2024.
- **JMS Exporter:**
  - Performance Issues: Improved vertex welding performance by 70%
    - Exporter was significantly slower on large models due to inefficient string handling and redundant hash computations.
    - Export time reduced from 26+ seconds to ~10 seconds for large models (82K vertices, 59K triangles).
- **Model Collision Geometry Importer:**
  - Add symbols to material names if the geometry has flags such as  `% = two-side` `* = two-side/invisible` `^ = climbable` `- = breakable`
  - Prevent import duplicated geometry on surfaces with the `two_side` flag.
- **JMS Importer:**
  - Fixed the smoothing group mapping to correctly apply to each region's faces, regardless of how the geometry is organized in the file.
    - Smoothing groups now import correctly and are properly preserved across all regions.
### Added
- **JMS Exporter:**
  - Vertex welding: 
    - Vertices are now properly deduplicated, reducing vertex count by ~57% (e.g., 2589 vs 6048 vertices with `cyborg` model).
  - Added smoothing group export: 
    - Smoothing groups now written after triangle data in extended metadata section.
  - Improved normal handling: 
    - Auto-detects smoothing groups and falls back to face normals when absent.
  - File size: ~57% smaller with proper vertex sharing.
- **JMS Format Converter:**
  - New tool to convert old JMS format (single-line) to new JMS format (multi-line) for compatibility.
## [4.2.2] - 2026-02-11
### Fixed
- **Utils:**
  - Fixed normal vector decompression.
    - > Previous decompression method produced incorrect normal vectors, leading to visual artifacts in imported models.
- **GBX/Model Importer:**
  - Imported GBX models now load cleanly without auto-generated smoothing groups, preserving the original explicit normals from the file. This ensures the geometry appears exactly as intended.
  - Fixed issues with reading shader modules:
    - `shader_transparent_generic`
- **JMS Importer:**
  - Fixed explicit normal import.
    - Models containing explicit normals (without smoothing groups in extended metadata) now import cleanly, with no smoothing group data interfering with the normals.
- **Animation Importer:**
  - Add EOF check when reading the file to prevent read data that doesn't exist.
- **JMS Exporter:**
  - Fixed skin/vertex weights being lost on high-poly models when exporting with explicit normals (no smoothing groups).
  - Restructured geometry extraction to pre-cache skin data before `Edit_Normals` modifier access, preventing panel context corruption .
  - Fixed incorrect shading caused by improper smoothing group processing.
    - Exported models now match the original 3ds Max shading more accurately.
### Added
- **JMS Exporter:**
  - Support for exporting explicit normals.
    - Exporting with explicit normals takes approximately two-thirds longer compared to using smoothing groups.
    - Skips writing **extended metadata** when no smoothing groups are present.
- **JMS Importer:**
  - Support for models that combine smoothing groups and explicit normals (one method per region).
    - The importer automatically detects which method is used in each region and applies the appropriate normal/SG data, ensuring optimal visual fidelity.
    - As a best practice, use only one method per region in your workflow.
      - > If both methods are combined within the same region, **explicit normals will be discarded**.
- **GBX/Model Importer:**
  - Reuses existing skeleton nodes in the scene when importing multiple gbxmodels that share the same skeleton. A dialog prompts you to confirm whether to reuse them.
  - Skips marker creation if markers with the same name already exist in the scene.
## [4.3.0] - 2026-02-15
### Added
- **JMA Importer:**
 - Add new tool to import source animation files. (Halo CE to Halo 4)
- **JMS Importer:**
  - Reuses existing skeleton nodes in the scene when importing multiple gbxmodels that share the same skeleton. A dialog prompts you to confirm whether to reuse them.
  - Skips marker creation if markers with the same name already exist in the scene.
- **Camera Track Importer:**
  - New rewrite tool for importing camera track tag files.
    - Creates a pyramid object for each control point with the correct position and orientation.
      - Assigns the pyramid objects to a `Camera Control Points` layer.
    - Creates a target camera with a distance of 70 and an FOV of 70, along with a dummy helper called `camera_track_dummy`. Assigns both to a `Camera Control Points Animation` layer.
      - Links the target camera to the dummy helper and creates an animation that matches the position and rotation of each pyramid object, with keyframes every 5 frames (starting at frame 0).
    - Viewport configuration: Sets the viewport to display the imported target camera in Viewport 3 (bottom-left) with default shading.