from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Art" / "Source"
OUTPUT = ROOT / "Art" / "Atlases"

PORTRAIT = SOURCE / "Cartethyia_Official_Portrait.png"
EMBLEM = SOURCE / "Cartethyia_Emblem_Transparent.png"

ICON_SIZES = (256, 128, 80, 64, 45, 32)
ALPHA_SIZES = (256, 128, 80, 64, 48, 32, 24, 16)


def cover(image: Image.Image, size: tuple[int, int], focus_y: float = 0.42) -> Image.Image:
    source_ratio = image.width / image.height
    target_ratio = size[0] / size[1]

    if source_ratio > target_ratio:
        height = image.height
        width = round(height * target_ratio)
        left = (image.width - width) // 2
        box = (left, 0, left + width, height)
    else:
        width = image.width
        height = round(width / target_ratio)
        top = round((image.height - height) * focus_y)
        top = max(0, min(top, image.height - height))
        box = (0, top, width, top + height)

    return image.crop(box).resize(size, Image.Resampling.LANCZOS)


def fit_with_padding(image: Image.Image, size: int, fraction: float) -> Image.Image:
    target = max(1, round(size * fraction))
    fitted = ImageOps.contain(image, (target, target), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(fitted, ((size - fitted.width) // 2, (size - fitted.height) // 2))
    return canvas


def portrait_background(size: tuple[int, int]) -> Image.Image:
    width, height = size
    canvas = Image.new("RGBA", size, (10, 57, 75, 255))
    pixels = canvas.load()

    for y in range(height):
        for x in range(width):
            nx = (x - width * 0.55) / max(width, 1)
            ny = (y - height * 0.35) / max(height, 1)
            glow = max(0.0, 1.0 - (nx * nx + ny * ny) * 4.2)
            horizon = y / max(height - 1, 1)
            pixels[x, y] = (
                round(8 + 38 * glow + 7 * horizon),
                round(48 + 82 * glow + 20 * horizon),
                round(68 + 100 * glow + 28 * horizon),
                255,
            )

    draw = ImageDraw.Draw(canvas)
    for inset, alpha in ((0.08, 30), (0.16, 22), (0.25, 16)):
        box = (
            round(width * inset),
            round(height * inset),
            round(width * (1 - inset)),
            round(height * (1 - inset)),
        )
        draw.ellipse(box, outline=(105, 226, 237, alpha), width=max(1, width // 180))
    return canvas


def compose_portrait(portrait: Image.Image, size: tuple[int, int], scale: float) -> Image.Image:
    background = portrait_background(size)
    subject = ImageOps.contain(
        portrait,
        (round(size[0] * scale), round(size[1] * scale)),
        Image.Resampling.LANCZOS,
    )
    x = (size[0] - subject.width) // 2
    y = size[1] - subject.height
    background.alpha_composite(subject, (x, y))
    return background


def make_leader_icon(portrait: Image.Image, size: int) -> Image.Image:
    # The official source is a full-body transparent render. This crop keeps
    # the face and crown readable even in Civ5's 32 and 45 pixel icon slots.
    head_and_shoulders = portrait.crop((250, 70, 825, 645))
    background = portrait_background((size, size))
    subject = head_and_shoulders.resize((size, size), Image.Resampling.LANCZOS)
    background.alpha_composite(subject)
    return background


def radial_background(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = canvas.load()
    center = (size - 1) / 2
    radius = size * 0.49

    for y in range(size):
        for x in range(size):
            distance = ((x - center) ** 2 + (y - center) ** 2) ** 0.5
            if distance > radius:
                continue
            amount = min(1.0, distance / radius)
            pixels[x, y] = (
                round(10 + 5 * amount),
                round(88 - 44 * amount),
                round(102 - 50 * amount),
                255,
            )

    draw = ImageDraw.Draw(canvas)
    inset = max(1, round(size * 0.025))
    width = max(1, round(size * 0.035))
    draw.ellipse(
        (inset, inset, size - inset - 1, size - inset - 1),
        outline=(238, 205, 125, 255),
        width=width,
    )
    return canvas


def make_color_icon(emblem: Image.Image, size: int) -> Image.Image:
    background = radial_background(size)
    background.alpha_composite(fit_with_padding(emblem, size, 0.80))
    return background


def make_alpha_icon(emblem: Image.Image, size: int, fraction: float = 0.82) -> Image.Image:
    symbol = fit_with_padding(emblem, size, fraction)
    alpha = ImageEnhance.Contrast(symbol.getchannel("A")).enhance(1.35)
    white = Image.new("RGBA", symbol.size, (255, 255, 255, 0))
    white.putalpha(alpha)
    return white


def make_dom_image(portrait: Image.Image) -> Image.Image:
    image = compose_portrait(portrait, (1024, 768), 0.98)
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for y in range(image.height):
        edge = abs(y - image.height / 2) / (image.height / 2)
        draw.line((0, y, image.width, y), fill=(2, 26, 36, round(52 * edge)))
    return Image.alpha_composite(image, overlay)


def save_dds(image: Image.Image, filename: str) -> None:
    image.convert("RGBA").save(OUTPUT / filename, format="DDS")


def main() -> None:
    if (SOURCE / "V1" / "Portrait.png").is_file():
        from build_v1_art import main as build_v1
        build_v1()
        return
    OUTPUT.mkdir(parents=True, exist_ok=True)
    portrait = Image.open(PORTRAIT).convert("RGBA")
    emblem = Image.open(EMBLEM).convert("RGBA")

    for size in ICON_SIZES:
        save_dds(make_leader_icon(portrait, size), f"Cartethyia_Leader_{size}.dds")
        save_dds(make_color_icon(emblem, size), f"Cartethyia_Icon_{size}.dds")

    for size in ALPHA_SIZES:
        save_dds(make_alpha_icon(emblem, size), f"Cartethyia_Alpha_{size}.dds")

    save_dds(make_alpha_icon(emblem, 32, fraction=0.88), "Cartethyia_UnitFlag_32.dds")
    save_dds(make_dom_image(portrait), "Cartethyia_DOM.dds")
    save_dds(make_color_icon(emblem, 512), "Cartethyia_Map.dds")

    preview = Image.new("RGB", (1000, 560), (18, 33, 39))
    preview.paste(make_leader_icon(portrait, 480).convert("RGB"), (40, 40))
    preview.paste(make_color_icon(emblem, 320).convert("RGB"), (600, 40))
    alpha_preview = Image.new("RGBA", (160, 160), (37, 70, 78, 255))
    alpha_preview.alpha_composite(make_alpha_icon(emblem, 160))
    preview.paste(alpha_preview.convert("RGB"), (680, 380))
    preview.save(OUTPUT / "Cartethyia_Art_Preview.png")

    print(f"Generated {len(list(OUTPUT.glob('*.dds')))} DDS files in {OUTPUT}")


if __name__ == "__main__":
    main()
