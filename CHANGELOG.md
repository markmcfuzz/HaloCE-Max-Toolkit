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
    - **Update Prefix** button for easy renaming. (e.g., `marker_01` > `#marker_01`, `masspoint_01` > `+masspoint_01`)
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
### Fixed
- **Physics Importer:** Update collect nodes in the scene from a global function in utils that add more prefix node names.
- **GBX/Model Importer:** Global function in utils to check prefix node names and converting to bones.
- **JMS Exporter:** Validation for exclude markers that are physics/pathfinding (`+`) and must be parent in a node with a geometry on it.
### Changed
- **Utils:** 
  - Moved common file writing functions for reuse across exporters.
  - Check if an object is a marker (names starting with `#` or `+`).
  - Check if an object is a physics marker (names starting with `+` just for an exclusion).