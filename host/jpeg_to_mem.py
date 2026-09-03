# host/jpeg_to_mem.py
# Convert an image to an 80x60 RGB .mem file.
# Fill in the #todo sections.

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow not installed. Run:  pip install pillow")
    sys.exit(1)


WIDTH = 80
HEIGHT = 60


def main() -> int:
    p = argparse.ArgumentParser(description="JPEG/PNG -> 80x60 .mem")
    p.add_argument("input")
    p.add_argument("-o", "--output", default="image.mem")
    args = p.parse_args()

    #todo: open image, convert to RGB
    #todo: resize to WIDTHxHEIGHT
    #todo: write each pixel as RRGGBB hex line to args.output

    raise NotImplementedError


if __name__ == "__main__":
    sys.exit(main())
