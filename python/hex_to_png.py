import argparse
from pathlib import Path

from PIL import Image


def mem_to_png(
    mem_path: Path,
    output_path: Path,
    width: int,
    height: int,
    scale_width: int = 1920,
    scale_height: int = 1080,
):
    pixels = []

    for original_line in mem_path.read_text().splitlines():
        line = original_line.split("//", 1)[0].split("#", 1)[0].strip() # split the line into parts and take the first part

        if not line or line.startswith("@"):
            continue

        token = line.split()[0]

        if token.lower().startswith("0x"):
            token = token[2:] #remove the 0x because it is not a part of the hex value

        if len(token) != 6:
            raise ValueError(f"Expected RRGGBB, received {token!r}")

        pixel = int(token, 16) #convert the hex value to an integer

        red = (pixel >> 16) & 0xFF
        green = (pixel >> 8) & 0xFF
        blue = pixel & 0xFF #get the red, green, and blue values from the pixel

        pixels.append((red, green, blue)) #append the pixel to the list

    expected_pixels = width * height #calculate the expected number of pixels

    if len(pixels) != expected_pixels: #check if the number of pixels is correct
        raise ValueError(
            f"Expected {expected_pixels} pixels, found {len(pixels)}"
        )

    image = Image.new("RGB", (width, height))
    image.putdata(pixels) #put the pixels into the image
    image = image.resize((scale_width, scale_height), Image.Resampling.NEAREST)
    image.save(output_path) #save the image

    


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", default=Path("processed_image.png"), type=Path)
    parser.add_argument("--width", type=int, default=80)
    parser.add_argument("--height", type=int, default=60)
    parser.add_argument("--scale-width", type=int, default=1920)
    parser.add_argument("--scale-height", type=int, default=1080)
    args = parser.parse_args()

    mem_to_png(
        args.input,
        args.output,
        args.width,
        args.height,
        args.scale_width,
        args.scale_height,
    )


if __name__ == "__main__":
    main()