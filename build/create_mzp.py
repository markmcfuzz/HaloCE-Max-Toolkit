import json
import os
import zipfile
from pathlib import Path

def main():
    print("HaloCE Max Toolkit - Python MZP Creator")
    print("======================================")

    script_dir = Path(__file__).resolve().parent
    root_dir = script_dir.parent

    # Paths
    manifest_path = script_dir / "manifest.json"

    if not manifest_path.exists():
        raise FileNotFoundError(f"manifest.json not found at: {manifest_path}")

    # Read manifest.json
    print("Reading manifest.json...")
    manifest = json.loads(manifest_path.read_text())

    package_version = manifest.get("packageVersion")
    package_name = manifest.get("fileName")
    source_folder = manifest.get("filesAndFoldersToCompress")

    if not (package_version and package_name and source_folder):
        raise ValueError("manifest.json missing required fields")

    source_dir = root_dir / source_folder
    if not source_dir.exists():
        raise FileNotFoundError(f"Source folder not found: {source_dir}")

    output_name = f"{package_name}{package_version}"
    zip_path = root_dir / f"{output_name}.zip"
    mzp_path = root_dir / f"{output_name}.mzp"

    print(f"Package version: {package_version}")
    print(f"Source directory: {source_dir}")
    print(f"Output file: {output_name}.mzp\n")

    # Remove existing files
    for f in (zip_path, mzp_path):
        if f.exists():
            f.unlink()
            print(f"Removed existing file: {f.name}")

    # Create ZIP
    print("Creating ZIP...")

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(source_dir):
            for file in files:
                file_path = Path(root) / file
                rel_path = file_path.relative_to(source_dir)
                zipf.write(file_path, rel_path)

    print(f"ZIP created: {zip_path}")

    # Rename ZIP → MZP
    print("Renaming to .mzp...")
    zip_path.rename(mzp_path)

    print(f"Successfully created: {mzp_path}")

    size_kb = mzp_path.stat().st_size / 1024
    print(f"Size: {size_kb:.2f} KB")
    print("\nDone! Ready for 3ds Max.")

if __name__ == "__main__":
    main()
