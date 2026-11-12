# hibit-pixel

Idea: modern hi-bit pixel art. 640x360 viewport stretched x2, nearest filter, ordered-dither gradients, dusk lighting, additive glow.

Pack vs code: only the font (Kenney KenPixel) is a pack. All art (sky, 3 parallax layers, terrain, tanks, smoke, fireball, debris, HUD) is code-generated, no CC0 pixel tank/terrain pack used.

Final art would need: hand-drawn tank sprites with animation frames, tileable terrain strata textures, parallax layers painted by an artist, a pixel-art explosion/smoke sprite sheet.

Palette: ink 1b1030; sky 2a1d54 4a2a7a 7a3a86 b04a82 e0685f ff9a62 ffc578; grass c4f065 62c24a 2f8a48; soil 9a6448 74483c 533340 36213f; char 2a1a2e; player 7fd8f0 2a8fd6 1f4a9a; enemy ff9a62 e0343c 8a1f4a; accent ffd23f; fire d6342f ff7a2a ffd23f fff4c2; smoke 2f2250 5a4577 8a6b9a.

Status: shot.png NOT generated (windowed capture was stopped by the coordinator). Capture: `godot --path mockups/hibit-pixel --resolution 1280x720 --position 3000,3000 -- --capture`.
