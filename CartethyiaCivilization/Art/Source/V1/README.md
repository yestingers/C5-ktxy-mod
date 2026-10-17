# v1.0 artwork sources

Created with the built-in image_gen tool on 2026-10-17. Character identity reference: ../Cartethyia_Official_Portrait.png. Images are project-bound and copied here; no runtime references point outside the workspace. Existing civilization emblem is retained.

Prompt set (production directions):

- Portrait.png: exact existing anime Cartethyia identity/costume, close head-and-shoulders within a centered thin antique-gold circular medallion, dark teal interior, transparent exterior/corners, readable at 45 and 256 pixels; no crest/text.
- Dawn.png: 4:3 hand-painted loading illustration, recognizable Cartethyia at far left with face around22%/28%, white stone coastal sanctuary at dawn, turquoise ocean and warm gold light, subdued right55% for original game overlay; no UI or text.
- Map.png: 360:412 portrait imaginary Nation of Enlightenment geography, believable central island/mountains/river/bay/cathedral, ivory parchment and muted teal sea, compass rose, safe margins; no heraldic logo or text; illustrative rather than canonical geography.
- Switch.png: transparent circular teal/gold game button; two bold curved gold/cyan arrows forming cycle around a star; clean at45px.
- Wisdom.png: same button family; open ivory/gold book with four-point star and rays; no letters on pages.
- Power.png: same button family; ivory sword crossing sweeping cyan wind slashes; no text.

Technical production: Tools/build_v1_art.py converts/resizes sources to existing Civ5 DDS slots and assembles three action cells; it does not synthesize or repaint artwork. Portraits use256/128/80/64/45/32, actions64/45/32, Dawn1024×768, Map360×412.
