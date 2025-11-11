#!/usr/bin/env python3
"""
Ultimate Collision Importer - CLI Runner
Converts .model_collision_geometry files to .gbxmodel format for import into 3ds Max

This is a cleaned-up version of the original run_coll_to_gbx.py
focused only on essential functionality.
"""

import sys
import os
from pathlib import Path

# Add the current directory to the path so we can import the converter modules
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

# Dependencies are now directly in the modules folder
for dep_subdir in ["reclaimer", "supyr_struct"]:
    dep_path = script_dir / dep_subdir
    if dep_path.exists():
        sys.path.insert(0, str(dep_path))

# Now try to import the collision converter
try:
    from collision_converter import coll_to_mod2
except ImportError as e:
    print(f"Error importing collision_converter: {e}")
    print("Available options:")
    print("1. Install required dependencies (reclaimer, supyr_struct)")
    print("2. Use the basic MaxScript collision importer instead")
    sys.exit(1)

def convert_collision_to_gbx(collision_file_path, output_path=None, raw_geometry=False):
    """
    Convert a .model_collision_geometry file to .gbxmodel format
    
    Args:
        collision_file_path: Path to the .model_collision_geometry file
        output_path: Optional output path for the .gbxmodel file
        raw_geometry: If True, imports as raw geometry without skeleton hierarchy
        
    Returns:
        Path to the created .gbxmodel file, or None if conversion failed
    """
    try:
        collision_path = Path(collision_file_path)
        
        if not collision_path.exists():
            print(f"Error: Input file not found: {collision_path}")
            return None
            
        if not collision_path.suffix.lower() == '.model_collision_geometry':
            print(f"Error: Input file must be a .model_collision_geometry file")
            return None
            
        # Determine output path
        if output_path is None:
            # Create output path with _COLL suffix to distinguish from original model
            base_name = collision_path.stem
            output_path = collision_path.parent / f"{base_name}_COLL.gbxmodel"
        else:
            output_path = Path(output_path)
            
        # Remove existing output file if it exists (to avoid file locking issues)
        if output_path.exists():
            try:
                print(f"Removing existing output file: {output_path}")
                output_path.unlink()
            except PermissionError as e:
                print(f"Warning: Could not remove existing file (may be locked): {e}")
                # Try with a different name
                counter = 1
                while True:
                    base_name = collision_path.stem
                    new_output_path = collision_path.parent / f"{base_name}_COLL_{counter}.gbxmodel"
                    if not new_output_path.exists():
                        output_path = new_output_path
                        print(f"Using alternative output path: {output_path}")
                        break
                    counter += 1
                    if counter > 10:  # Safety limit
                        print("Error: Could not find available output filename")
                        return None
            
        print(f"Converting collision geometry...")
        print(f"  Input:  {collision_path}")
        print(f"  Output: {output_path}")
        print(f"  Mode:   {'Raw geometry (no skeleton)' if raw_geometry else 'Full hierarchy (with skeleton)'}")
        
        # Perform the conversion
        if raw_geometry:
            # Force raw geometry mode by not looking for a template gbxmodel
            mod2_tag = coll_to_mod2(
                str(collision_path),
                model_in_path=None,  # No template - forces raw geometry mode
                guess_mod2=False,    # Don't auto-find template
                use_mats=True        # Still use collision materials as shaders
            )
        else:
            # Normal mode - try to find template for skeleton
            try:
                mod2_tag = coll_to_mod2(
                    str(collision_path),
                    model_in_path=None,  # Let it auto-find a template
                    guess_mod2=True,     # Auto-find template .gbxmodel
                    use_mats=True        # Use collision materials as shaders
                )
            except (IndexError, KeyError) as e:
                print(f"✗ Skeleton mismatch detected: {e}")
                print("The collision geometry references nodes that don't exist in the skeleton model.")
                print("This usually happens when:")
                print("  - Using collision from a different model")
                print("  - The skeleton has been modified")
                print("  - The files don't match")
                print("")
                print("💡 Suggestion: Try using 'raw geometry mode' instead:")
                print("   python run_collision_converter.py \"collision_file\" raw")
                return None
            except Exception as e:
                print(f"✗ Conversion error: {e}")
                return None
        
        if mod2_tag:
            # Save the converted file with error handling for file locks
            try:
                mod2_tag.filepath = str(output_path)
                mod2_tag.serialize(temp=False, backup=False, int_test=False)
            except PermissionError as e:
                print(f"✗ File access error: {e}")
                print("This usually means the output file is locked by another process.")
                print("Try closing 3ds Max or any other programs that might have the file open.")
                return None
            except Exception as e:
                print(f"✗ Serialization error: {e}")
                return None
            
            if output_path.exists():
                print(f"✓ Conversion completed successfully!")
                print(f"✓ Created: {output_path}")
                print(f"✓ Ready to import in 3ds Max using GBX importer")
                return str(output_path)
            else:
                print(f"✗ Error: Output file was not created")
                return None
        else:
            print(f"✗ Conversion failed - no output generated")
            return None
            
    except Exception as e:
        print(f"✗ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        return None

def main():
    """Main CLI entry point"""
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Ultimate Collision Importer - CLI Converter")
        print("Usage: python run_collision_converter.py <collision_file.model_collision_geometry> [raw]")
        print("")
        print("Converts .model_collision_geometry files to .gbxmodel format")
        print("for import into 3ds Max with full bone hierarchy support.")
        print("")
        print("Options:")
        print("  raw    - Import as raw geometry without requiring skeleton hierarchy")
        print("           (useful when .gbxmodel file is not available)")
        sys.exit(1)
        
    collision_file = sys.argv[1]
    raw_mode = len(sys.argv) == 3 and sys.argv[2].lower() == "raw"
    
    result = convert_collision_to_gbx(collision_file, raw_geometry=raw_mode)
    
    if result:
        sys.exit(0)  # Success
    else:
        sys.exit(1)  # Failure

if __name__ == "__main__":
    main()