# cartoon-lit (look direction, round 2)

Idea: bold outlined cartoon shapes (round-1 B) lit like a golden-hour diorama. Low sun top-right, warm lit sides, teal/violet shadow sides, rim light, cast shadows, hazy layered mesas, glowing relics buried in plum-orange dirt.

Pack vs code: only the HUD font (Kenney KenVector Future, CC0) is a pack. All art is drawn in code: cel-shading via polygon clipping (shadow and rim crescents), layered depth (sky, far mesas, mid mesas, hills, terrain, foreground silhouettes), real CPUParticles2D for explosion/smoke/sparks/debris/shell trail/dust/pollen/leaves.

Final art in this style would need: hand-drawn tank sheets with animation (eye look, recoil, damage states), tileable terrain textures with painted edge lighting, a painted parallax set, a real particle sprite set, HUD frames as 9-slice art.

## Palette
- Ink outline `#2a1838`, cream `#fff0d0`
- Sky: `#241f5e` `#5a3590` `#c2508f` `#ff7f6e` `#ffb56e` `#ffdc98`
- Mesas/hills: `#c0689a` `#7e4390` `#3a7a78`, haze `#ffb78a`
- Dirt: `#ffb040` `#ee8040` `#c0504a` `#6a2e66` `#26143f`
- Grass: shadow `#2c8a72`, lit `#bfe04a`
- Player (Biscuit): teal `#30d3c1`, goggle/accents `#ff9d2e` `#ffc23a`
- Enemy (Brute): crimson `#d92f52`, eye `#ffe23a`, bone `#f0dcc0`
- Glow crystals `#52f2dc`

## Capture
`tools/capture/capture.sh mockups/cartoon-lit` writes shot.png; pass `"--capture --closeup"` for shot2.png.
