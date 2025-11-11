#!/usr/bin/env python3
#
# This file is part of Mozzarilla.
#
# For authors and copyright check AUTHORS.TXT
#
# Mozzarilla is free software under the GNU General Public License v3.0.
# See LICENSE for more information.
#
# Modified for Ultimate Collision Importer - simplified base converter

from pathlib import Path
from threading import Thread
from time import time
from traceback import format_exc
import os

curr_dir = Path.cwd()

class ConverterBase:
    """Simplified base converter class for command-line usage"""
    src_ext = "*"
    dst_ext = "*"
    
    @property
    def src_exts(self): 
        return (self.src_ext, )

    def __init__(self, *args, **kwargs):
        pass

    def convert(self, tag_path):
        raise NotImplementedError("Override this method.")

    def do_convert_tag(self, tag_path, *args, **kwargs):
        start = time()

        if not os.path.isfile(tag_path):
            print(f"Error: File not found: {tag_path}")
            return None

        print(f"Converting: {tag_path}")

        try:
            result = self.convert(tag_path)
            print(f"    Conversion completed in {round(time() - start, 1)} seconds")
            return result
        except Exception as e:
            print(f"Error during conversion: {e}")
            print(format_exc())
            return None