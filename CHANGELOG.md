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

