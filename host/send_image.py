# host/send_image.py
# Host-side UART sender for SoCET2img (pyserial).
# Fill in the #todo sections.

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


def load_mem(path: Path) -> list[tuple[int, int, int]]:
    """Read .mem file -> list of (r, g, b) bytes."""
    #todo: parse hex lines like FFFFFF into (R, G, B) tuples
    #todo: make sure we got exactly NUM_PIXELS
    raise NotImplementedError


def open_port(name: str) -> serial.Serial:
    """Open one COM port at BAUD."""
    #todo: return serial.Serial(...) with the right settings
    raise NotImplementedError


def send_config(port_cfg: serial.Serial, mode: int, threshold: int) -> None:
    """Send mode then threshold on the config UART."""
    #todo: write mode byte (low 3 bits)
    #todo: wait a bit
    #todo: write threshold byte (low 5 bits)
    raise NotImplementedError


def send_pixels(
    port_r: serial.Serial,
    port_g: serial.Serial,
    port_b: serial.Serial,
    pixels: list[tuple[int, int, int]],
) -> None:
    """Stream all pixels over the 3 RGB UART ports."""
    #todo: for each pixel, write R/G/B bytes (ideally close together)
    #todo: delay between pixels so the FPGA can keep up
    raise NotImplementedError


def recv_pixels(
    tx_r: serial.Serial,
    tx_g: serial.Serial,
    tx_b: serial.Serial,
    n: int,
) -> list[tuple[int, int, int]]:
    """Optional: read processed pixels back from TX ports."""
    #todo: read n pixels (one byte from each TX port per pixel)
    raise NotImplementedError


def write_mem(path: Path, pixels: list[tuple[int, int, int]]) -> None:
    """Write pixels back out as a .mem file."""
    #todo: write each pixel as 6 hex chars + newline
    raise NotImplementedError


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Send .mem image to FPGA over UART")
    p.add_argument("--mem", required=True)
    p.add_argument("--mode", type=int, default=0)
    p.add_argument("--threshold", type=int, default=0)
    p.add_argument("--port-r", required=True)
    p.add_argument("--port-g", required=True)
    p.add_argument("--port-b", required=True)
    p.add_argument("--port-cfg", required=True)
    p.add_argument("--tx-r")
    p.add_argument("--tx-g")
    p.add_argument("--tx-b")
    p.add_argument("--out-mem")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    #todo: load_mem(args.mem)
    #todo: open the R/G/B/config ports
    #todo: send_config(...)
    #todo: send_pixels(...)
    #todo: optionally recv_pixels + write_mem if TX ports given
    #todo: close ports

    raise NotImplementedError


if __name__ == "__main__":
    sys.exit(main())
