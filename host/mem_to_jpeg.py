# host/mem_to_jpeg.py
# Convert an 80x60 .mem file back to a viewable image.
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
NUM_PIXELS = WIDTH * HEIGHT


def load_mem(path: Path) -> list[tuple[int, int, int]]:
    """Read .mem -> list of (r, g, b)."""
    #todo: parse hex lines like FFFFFF
    #todo: expect NUM_PIXELS pixels
    raise NotImplementedError


def main() -> int:
    p = argparse.ArgumentParser(description="80x60 .mem -> JPEG/PNG")
    p.add_argument("input", help="input .mem")
    p.add_argument("-o", "--output", default="out.jpg")
    args = p.parse_args()

    #todo: pixels = load_mem(Path(args.input))
    #todo: create Image.new("RGB", (WIDTH, HEIGHT))
    #todo: put pixels in row-major order (same order you sent)
    #todo: save to args.output

    raise NotImplementedError


if __name__ == "__main__":
    sys.exit(main())
