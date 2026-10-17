"""Check native UI slot bounds and transparent portrait/action texture contracts."""
import unittest
from pathlib import Path
from PIL import Image

ART = Path(__file__).resolve().parents[1] / 'Art/Atlases'

class V1ArtTests(unittest.TestCase):
    def test_portraits_fit_round_slots_without_opaque_square_corners(self):
        for size in (256,128,80,64,45,32):
            with Image.open(ART/f'Cartethyia_Leader_{size}.dds') as image:
                rgba=image.convert('RGBA')
                self.assertEqual(rgba.size,(size,size))
                for x,y in ((0,0),(size-1,0),(0,size-1),(size-1,size-1)):
                    self.assertLess(rgba.getpixel((x,y))[3],8)
                self.assertGreater(rgba.getpixel((size//2,size//2))[3],240)

    def test_map_matches_native_360_by_410_viewport_with_block_padding(self):
        with Image.open(ART/'Cartethyia_Map.dds') as image:
            self.assertEqual(image.size,(360,412))

    def test_action_atlas_has_three_distinct_transparent_cells(self):
        for size in (64,45,32):
            with Image.open(ART/f'Cartethyia_Actions_{size}.dds') as image:
                rgba=image.convert('RGBA')
                self.assertEqual(rgba.size,(size*3,size))
                cells=[rgba.crop((i*size,0,(i+1)*size,size)) for i in range(3)]
                self.assertEqual(len({c.tobytes() for c in cells}),3)
                for cell in cells:
                    self.assertLess(cell.getpixel((0,0))[3],8)
                    self.assertGreater(cell.getpixel((size//2,size//2))[3],240)

if __name__=='__main__':unittest.main()
