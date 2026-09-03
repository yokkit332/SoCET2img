# uart_image_transfer.py
# 3-wire RGB (+ config) host tool for SoCET2img.
#
# Send path:
#   1) config UART: mode byte, then threshold byte
#   2) for each pixel: write R, G, B on the three RGB UARTs
#
# Optional receive on tx-r / tx-g / tx-b -> .mem + PNG
# Use --send-only to skip receive.

from __future__ import annotations

import argparse
import threading
import time
from pathlib import Path

import serial

from hex_to_png import mem_to_png


def read_mem_pixels(path: Path, expected_pixels: int) -> list[tuple[int, int, int]]:
    pixels: list[tuple[int, int, int]] = []

    for line_number, original_line in enumerate(
        path.read_text().splitlines(),
        start=1,
    ):
        line = original_line.split("//", 1)[0].split("#", 1)[0].strip()
        if not line or line.startswith("@"):
            continue

        token = line.split()[0]
        if token.lower().startswith("0x"):
            token = token[2:]

        if len(token) != 6:
            raise ValueError(
                f"Line {line_number}: expected RRGGBB, received {token!r}"
            )

        try:
            pixel = int(token, 16)
        except ValueError as error:
            raise ValueError(
                f"Line {line_number}: invalid hexadecimal pixel {token!r}"
            ) from error

        pixels.append(
            (
                (pixel >> 16) & 0xFF,
                (pixel >> 8) & 0xFF,
                pixel & 0xFF,
            )
        )

    if len(pixels) != expected_pixels:
        raise ValueError(
            f"Expected {expected_pixels} pixels, found {len(pixels)}"
        )

    return pixels


def write_mem_file(path: Path, pixels: list[tuple[int, int, int]]) -> None:
    lines = [f"{r:02X}{g:02X}{b:02X}" for r, g, b in pixels]
    path.write_text("\n".join(lines) + "\n")


def open_port(name: str, baud: int, timeout: float) -> serial.Serial:
    return serial.Serial(
        port=name,
        baudrate=baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=timeout,
        write_timeout=timeout,
    )


def receive_pixels(
    tx_r: serial.Serial,
    tx_g: serial.Serial,
    tx_b: serial.Serial,
    n: int,
    timeout_seconds: float,
) -> list[tuple[int, int, int]]:
    out: list[tuple[int, int, int]] = []
    deadline = time.monotonic() + timeout_seconds

    while len(out) < n:
        if time.monotonic() >= deadline:
            raise TimeoutError(
                f"Received {len(out)} of {n} pixels before timeout"
            )

        if tx_r.in_waiting and tx_g.in_waiting and tx_b.in_waiting:
            r = tx_r.read(1)
            g = tx_g.read(1)
            b = tx_b.read(1)
            if len(r) and len(g) and len(b):
                out.append((r[0], g[0], b[0]))
                deadline = time.monotonic() + timeout_seconds
        else:
            time.sleep(0.0005)

    return out


def transfer_image(args: argparse.Namespace) -> None:
    if not 0 <= args.mode <= 7:
        raise ValueError("Mode must be between 0 and 7")
    if not 0 <= args.threshold <= 31:
        raise ValueError("Threshold must be between 0 and 31")

    expected_pixels = args.width * args.height
    pixels = read_mem_pixels(args.input, expected_pixels)

    ports: list[serial.Serial] = []
    try:
        port_r = open_port(args.port_r, args.baud, args.timeout)
        port_g = open_port(args.port_g, args.baud, args.timeout)
        port_b = open_port(args.port_b, args.baud, args.timeout)
        port_cfg = open_port(args.port_cfg, args.baud, args.timeout)
        ports.extend([port_r, port_g, port_b, port_cfg])

        tx_ports = None
        if not args.send_only:
            if not (args.tx_r and args.tx_g and args.tx_b):
                raise ValueError(
                    "Provide --tx-r/--tx-g/--tx-b, or pass --send-only"
                )
            tx_r = open_port(args.tx_r, args.baud, 0.1)
            tx_g = open_port(args.tx_g, args.baud, 0.1)
            tx_b = open_port(args.tx_b, args.baud, 0.1)
            ports.extend([tx_r, tx_g, tx_b])
            tx_r.reset_input_buffer()
            tx_g.reset_input_buffer()
            tx_b.reset_input_buffer()
            tx_ports = (tx_r, tx_g, tx_b)

        time.sleep(args.startup_delay)
        for p in (port_r, port_g, port_b, port_cfg):
            p.reset_input_buffer()
            p.reset_output_buffer()

        receive_result: dict[str, list[tuple[int, int, int]]] = {}
        receive_error: dict[str, BaseException] = {}
        receive_thread = None

        if tx_ports is not None:
            def reader() -> None:
                try:
                    receive_result["pixels"] = receive_pixels(
                        *tx_ports,
                        expected_pixels,
                        args.timeout,
                    )
                except BaseException as error:
                    receive_error["error"] = error

            receive_thread = threading.Thread(target=reader, daemon=True)
            receive_thread.start()

        # config: mode, then threshold (pixel_controller sequence)
        port_cfg.write(bytes([args.mode & 0x07]))
        port_cfg.flush()
        time.sleep(args.byte_gap)

        port_cfg.write(bytes([args.threshold & 0x1F]))
        port_cfg.flush()
        time.sleep(args.byte_gap)

        # RGB pixels in parallel on 3 UARTs
        for r, g, b in pixels:
            port_r.write(bytes([r]))
            port_g.write(bytes([g]))
            port_b.write(bytes([b]))
            time.sleep(args.pixel_gap)

        port_r.flush()
        port_g.flush()
        port_b.flush()

        print(f"Sent mode={args.mode} threshold={args.threshold}")
        print(f"Sent {expected_pixels} pixels from {args.input}")

        if args.send_only:
            return

        assert receive_thread is not None
        receive_thread.join(args.timeout + 5.0)
        if receive_thread.is_alive():
            raise TimeoutError("Receiver thread did not finish")
        if "error" in receive_error:
            raise receive_error["error"]
        if "pixels" not in receive_result:
            raise RuntimeError("No processed image was received")

        out_pixels = receive_result["pixels"]
        write_mem_file(args.output, out_pixels)

        png_output = (
            args.png_output
            if args.png_output is not None
            else args.output.with_suffix(".png")
        )
        mem_to_png(
            mem_path=args.output,
            output_path=png_output,
            width=args.width,
            height=args.height,
        )

        print(f"Received {expected_pixels} processed pixels")
        print(f"Wrote {args.output}")
        print(f"Wrote {png_output}")

    finally:
        for p in ports:
            try:
                p.close()
            except Exception:
                pass


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Send/receive image over 3 RGB UARTs + config UART"
    )
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("processed_image.mem"))
    parser.add_argument("--png-output", type=Path, default=None)

    parser.add_argument("--port-r", required=True, help="COM port -> rx_r")
    parser.add_argument("--port-g", required=True, help="COM port -> rx_g")
    parser.add_argument("--port-b", required=True, help="COM port -> rx_b")
    parser.add_argument("--port-cfg", required=True, help="COM port -> rx_config")

    parser.add_argument("--tx-r", help="COM port <- tx_r")
    parser.add_argument("--tx-g", help="COM port <- tx_g")
    parser.add_argument("--tx-b", help="COM port <- tx_b")

    parser.add_argument("--mode", type=int, required=True)
    parser.add_argument("--threshold", type=int, required=True)
    parser.add_argument("--width", type=int, default=80)
    parser.add_argument("--height", type=int, default=60)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--startup-delay", type=float, default=0.25)
    parser.add_argument(
        "--byte-gap",
        type=float,
        default=0.002,
        help="delay after each config byte",
    )
    parser.add_argument(
        "--pixel-gap",
        type=float,
        default=0.001,
        help="delay after each RGB pixel write",
    )
    parser.add_argument(
        "--send-only",
        action="store_true",
        help="only send (no TX capture)",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    transfer_image(args)


if __name__ == "__main__":
    main()
