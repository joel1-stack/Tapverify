"""Derives the brand mark the Flutter app actually paints.

Inputs (read only):
    assets/images/logo_transparent.png   full square lock up, real alpha

Output:
    assets/images/logo_horizontal.png    cropped to the artwork, dashes erased,
                                         downscaled, alpha preserved

Why this exists:
  * logo_full.png had no alpha channel and a near white background, so
    Image.asset(color: Colors.white) painted a solid white square instead of
    the shield.
  * The source art sits in a large transparent square, so painting it at 34px
    would have rendered the wordmark at about 8px.
  * The tagline was flanked by two orange dashes. TapVerify copy avoids dashes,
    so the mark should not carry them either.

The dashes are found by colour rather than by hardcoded offsets: within the
tagline band the only orange runs that are not letters are the two outermost
clusters, so they are erased and the wordmark is left untouched.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "images" / "logo_transparent.png"
OUT = ROOT / "assets" / "images" / "logo_horizontal.png"

TARGET_WIDTH = 640
ALPHA_FLOOR = 40

# The tagline occupies rows 249..279 of the 312px crop; the shield's own orange
# arc ends at row 231, so 0.78 sits in the blank gap between the two.
TAGLINE_BAND_FRACTION = 0.78

ORANGE = dict(r_min=150, g_min=60, g_max=205, b_max=150)


def _is_orange(px) -> bool:
    r, g, b, a = px
    return (
        a > ALPHA_FLOOR
        and r > ORANGE["r_min"]
        and ORANGE["g_min"] < g < ORANGE["g_max"]
        and b < ORANGE["b_max"]
    )


def _column_runs(columns) -> list[tuple[int, int]]:
    runs, current = [], [columns[0]]
    for x in columns[1:]:
        if x == current[-1] + 1:
            current.append(x)
        else:
            runs.append((current[0], current[-1]))
            current = [x]
    runs.append((current[0], current[-1]))
    return runs


def main() -> None:
    src = Image.open(SRC).convert("RGBA")

    bbox = src.getchannel("A").point(
        lambda a: 255 if a > ALPHA_FLOOR else 0
    ).getbbox()
    if bbox is None:
        raise SystemExit(f"no visible pixels in {SRC}")

    cropped = src.crop(bbox)
    width, height = cropped.size
    band_top = int(height * TAGLINE_BAND_FRACTION)

    # Columns carrying orange inside the tagline band.
    orange_columns = sorted({
        x
        for y in range(band_top, height)
        for x in range(width)
        if _is_orange(cropped.getpixel((x, y)))
    })
    if not orange_columns:
        raise SystemExit("no tagline orange found; nothing to erase")

    runs = _column_runs(orange_columns)

    # The dashes are the outermost runs; the wordmark is everything between.
    left_dash, right_dash = runs[0], runs[-1]
    if len(runs) < 3:
        raise SystemExit(f"expected dashes around the tagline, found runs {runs}")

    erased = 0
    for x0, x1 in (left_dash, right_dash):
        for x in range(x0, x1 + 1):
            for y in range(band_top, height):
                if _is_orange(cropped.getpixel((x, y))):
                    cropped.putpixel((x, y), (0, 0, 0, 0))
                    erased += 1

    scale = TARGET_WIDTH / cropped.width
    resized = cropped.resize(
        (TARGET_WIDTH, max(1, round(cropped.height * scale))),
        Image.LANCZOS,
    )
    resized.save(OUT, optimize=True)

    print(f"source        : {src.size[0]}x{src.size[1]}")
    print(f"crop box      : {bbox}")
    print(f"left dash     : x {left_dash[0]}..{left_dash[1]}")
    print(f"right dash    : x {right_dash[0]}..{right_dash[1]}")
    print(f"dash px erased: {erased}")
    print(f"written       : {OUT.name} {resized.size[0]}x{resized.size[1]}")
    print(f"bytes         : {OUT.stat().st_size:,}")


if __name__ == "__main__":
    main()
