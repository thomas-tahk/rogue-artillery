# cartoon-packs (look mockup, direction "real CC0 art + code lighting")

Same battle moment as the other mockups, built from downloaded CC0 packs and unified in code. Capture: `tools/capture/capture.sh <this dir>` writes `shot.png` (full moment) and `shot2.png` (player tank close-up).

## Palette (golden-hour: teal-purple shadows, warm lights)
- Sky: #2b2a7a, #7a3f9e, #e0618f, #ff9a5c, #ffd27a
- Far layers (gradient-mapped): #6a3a8c to #f59ab0 (mountains), #523078 to #a04c8f, #33205c to #6d3a86 (forests), #1f1048 to #4a2a78 (mid trees)
- Terrain: dirt texture tinted warm top to #522a5c bottom; grass #c4f060 to #2f9a52; foreground #160a2e
- FX: #fff4a0, #ff8a2a, #f0402e; UI: Kenney blue/red/yellow/grey, ink #1c1038, aim gold #ffe35a

## Idea / pack vs code / what final art needs
- Idea: bright cartoon like B but with a lit sunset, layered depth and shaded sprites, so flat clip-art reads as a lit world.
- Packs: tank parts, clouds/trees/bushes, particle textures, UI 9-patches, font, 3 parallax layers, dirt and grass textures. Code: sky gradient, sun glow, gradient-map recolour shader, tank shader (shading + warm rim light), terrain shader (strata, scorch, depth), grass blades, shadows, point light, all particles, HUD gauge and bars, vignette.
- Final art would need: tanks with real shading, outlines and animation (barrel recoil, tread motion, damage states), a hand-painted parallax set in the final palette, bespoke terrain edge art, and a coherent UI kit. Kenney's flat tanks are the weakest link for "personality".
