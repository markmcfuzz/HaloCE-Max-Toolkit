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

## [3.1.0] - 2025-11-14
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