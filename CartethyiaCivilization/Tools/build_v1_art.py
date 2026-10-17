"""Format/size generated source artwork for Civ5 DDS slots; no artwork synthesis."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Art/Source/V1'
OUTPUT = ROOT / 'Art/Atlases'

def sized(name, size):
    return Image.open(SOURCE / name).convert('RGBA').resize(size, Image.Resampling.LANCZOS)

def write(image, name):
    image.save(OUTPUT / name, format='DDS')

def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for size in (256, 128, 80, 64, 45, 32):
        write(sized('Portrait.png', (size,size)), f'Cartethyia_Leader_{size}.dds')
    write(sized('Dawn.png', (1024,768)), 'Cartethyia_DOM.dds')
    write(sized('Map.png', (360,412)), 'Cartethyia_Map.dds')
    for size in (64,45,32):
        atlas = Image.new('RGBA', (size*3,size), (0,0,0,0))
        for index, name in enumerate(('Switch.png','Wisdom.png','Power.png')):
            atlas.paste(sized(name, (size,size)), (index*size,0))
        write(atlas, f'Cartethyia_Actions_{size}.dds')
    print('Packed v1 portrait, dawn, map and three action atlas sizes into DDS.')

if __name__ == '__main__':
    main()
