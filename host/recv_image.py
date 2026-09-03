# host/recv_image.py
# Host-side UART receiver for processed pixels from FPGA TX.
# Fill in the #todo sections.
#
# FPGA drives tx_r / tx_g / tx_b (one UART byte per color per pixel).
# After a full frame you should have 4800 RGB pixels -> .mem (and optionally a JPEG).

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import serial
except ImportError:
    print("pyserial not installed. Run:  pip install pyserial")
    sys.exit(1)


BAUD = 115200
NUM_PIXELS = 80 * 60  # 4800


def open_port(name: str) -> serial.Serial:
    """Open one COM port at BAUD (for reading TX)."""
    #todo: return serial.Serial(...)
    raise NotImplementedError


def recv_pixels(
    tx_r: serial.Serial,
    tx_g: serial.Serial,
    tx_b: serial.Serial,
    n: int = NUM_PIXELS,
) -> list[tuple[int, int, int]]:
    """Read n processed pixels from the 3 TX UART ports."""
    #todo: wait until a byte is available on each port (or read with timeout)
    serial.Serial.read(tx_r, 1)
    serial.Serial.read(tx_g, 1)
    serial.Serial.read(tx_b, 1)
    #todo: for each pixel, read 1 byte from R, G, B -> (r, g, b)
    #todo: stop after n pixels (or error on timeout)
    if not r or not g or not b:
        raise TimeoutError
    return [(r, g, b) for _ in range(n)]


def write_mem(path: Path, pixels: list[tuple[int, int, int]]) -> None:
    """Write pixels as .mem (one RRGGBB hex line each)."""
    #todo
    with open(path, "w") as f:
        for r, g, b in pixels:
            f.write(f"{r:02x}{g:02x}{b:02x}\n")
    raise NotImplementedError


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Receive processed image from FPGA TX UARTs")
    p.add_argument("--tx-r", required=True, help="COM port wired to FPGA tx_r")
    p.add_argument("--tx-g", required=True, help="COM port wired to FPGA tx_g")
    p.add_argument("--tx-b", required=True, help="COM port wired to FPGA tx_b")
    p.add_argument("--out-mem", default="out.mem")
    p.add_argument("--n", type=int, default=NUM_PIXELS, help="pixels to read")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    #todo: open tx-r / tx-g / tx-b
    tx_r = open_port(args.tx_r)
    tx_g = open_port(args.tx_g)
    tx_b = open_port(args.tx_b)
    #todo: clear input buffers if you want a clean start
    tx_r.reset_input_buffer()
    tx_g.reset_input_buffer()
    tx_b.reset_input_buffer()
    #todo: pixels = recv_pixels(...)
    pixels = recv_pixels(tx_r, tx_g, tx_b, args.n)
    #todo: write_mem(Path(args.out_mem), pixels)
    write_mem(Path(args.out_mem), pixels)
    #todo: close ports
    tx_r.close()
    tx_g.close()
    tx_b.close()
    raise NotImplementedError


if __name__ == "__main__":
    sys.exit(main())
