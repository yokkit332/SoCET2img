# uart_image_transfer.py
# One-wire host tool for the SoCET2img UART stream protocol.
#
# Always sends:
#   A0, mode, A1, threshold, A2, then R,G,B,... pixels from a .mem file
#
# By default also receives the processed frame on the same COM port
# (FPGA serial_tx -> PC RX), writes a .mem, and makes a PNG.
# Use --send-only to skip receive (old send_uart.py behavior).

from __future__ import annotations

import argparse
import threading
import time
from pathlib import Path

import serial

from hex_to_png import mem_to_png


CMD_MODE = 0xA0
CMD_THRESHOLD = 0xA1
CMD_FRAME_START = 0xA2


def read_mem_file(path: Path, expected_pixels: int) -> bytes:
    payload = bytearray()

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

        payload.extend(
            (
                (pixel >> 16) & 0xFF,
                (pixel >> 8) & 0xFF,
                pixel & 0xFF,
            )
        )

    actual_pixels = len(payload) // 3
    if actual_pixels != expected_pixels:
        raise ValueError(
            f"Expected {expected_pixels} pixels, found {actual_pixels}"
        )

    return bytes(payload)


def write_mem_file(path: Path, data: bytes) -> None:
    if len(data) % 3 != 0:
        raise ValueError("Received byte count is not divisible by three")

    lines = [
        f"{data[i]:02X}{data[i + 1]:02X}{data[i + 2]:02X}"
        for i in range(0, len(data), 3)
    ]
    path.write_text("\n".join(lines) + "\n")


def receive_exact(
    uart: serial.Serial,
    byte_count: int,
    timeout_seconds: float,
) -> bytes:
    received = bytearray()
    deadline = time.monotonic() + timeout_seconds

    while len(received) < byte_count:
        remaining = byte_count - len(received)
        chunk = uart.read(min(4096, remaining))

        if chunk:
            received.extend(chunk)
            deadline = time.monotonic() + timeout_seconds
        elif time.monotonic() >= deadline:
            raise TimeoutError(
                f"Received {len(received)} of {byte_count} bytes before timeout"
            )

    return bytes(received)


def build_header(mode: int, threshold: int) -> bytes:
    return bytes(
        (
            CMD_MODE,
            mode & 0xFF,
            CMD_THRESHOLD,
            threshold & 0xFF,
            CMD_FRAME_START,
        )
    )


def transfer_image(args: argparse.Namespace) -> None:
    if not 0 <= args.mode <= 7:
        raise ValueError("Mode must be between 0 and 7")
    if not 0 <= args.threshold <= 31:
        raise ValueError("Threshold must be between 0 and 31")
    if args.width <= 0 or args.height <= 0:
        raise ValueError("Width and height must be positive")

    expected_pixels = args.width * args.height
    expected_output_bytes = expected_pixels * 3
    payload = read_mem_file(args.input, expected_pixels)
    header = build_header(args.mode, args.threshold)

    receive_result: dict[str, bytes] = {}
    receive_error: dict[str, BaseException] = {}

    with serial.Serial(
        port=args.port,
        baudrate=args.baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=0.1,
        write_timeout=args.timeout,
    ) as uart:
        time.sleep(args.startup_delay)
        uart.reset_input_buffer()
        uart.reset_output_buffer()

        receive_thread = None
        if not args.send_only:
            def reader() -> None:
                try:
                    receive_result["data"] = receive_exact(
                        uart=uart,
                        byte_count=expected_output_bytes,
                        timeout_seconds=args.timeout,
                    )
                except BaseException as error:
                    receive_error["error"] = error

            receive_thread = threading.Thread(target=reader, daemon=True)
            receive_thread.start()

        uart.write(header)
        for start in range(0, len(payload), args.chunk_size):
            uart.write(payload[start:start + args.chunk_size])
        uart.flush()

        print(f"Sent mode={args.mode} threshold={args.threshold}")
        print(f"Sent {expected_pixels} pixels ({len(payload)} RGB bytes) from {args.input}")

        if args.send_only:
            return

        assert receive_thread is not None
        receive_thread.join(args.timeout + 5.0)

        if receive_thread.is_alive():
            raise TimeoutError("Receiver thread did not finish")
        if "error" in receive_error:
            raise receive_error["error"]
        if "data" not in receive_result:
            raise RuntimeError("No processed image was received")

        output_data = receive_result["data"]
        write_mem_file(args.output, output_data)

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


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Send (and optionally receive) an image over 1-wire UART"
    )
    parser.add_argument("--port", required=True)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("processed_image.mem"))
    parser.add_argument("--png-output", type=Path, default=None)
    parser.add_argument("--mode", type=int, required=True)
    parser.add_argument("--threshold", type=int, required=True)
    parser.add_argument("--width", type=int, default=80)
    parser.add_argument("--height", type=int, default=60)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--startup-delay", type=float, default=0.25)
    parser.add_argument("--chunk-size", type=int, default=1024)
    parser.add_argument(
        "--send-only",
        action="store_true",
        help="only send to the chip (no TX capture / .mem / PNG)",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    transfer_image(args)


if __name__ == "__main__":
    main()
