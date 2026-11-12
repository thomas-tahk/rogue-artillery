# atmospheric-silhouette

Idea: sunset sky + 5 hazy ridge layers; foreground terrain and tanks are near-black silhouettes with a thin amber (player) / coral (enemy) rim light; shell trail and explosion are the only pure-white/saturated-orange things, drawn additively.

Palette: sky #1d1b4a #6a2a73 #e0527a #ff9a4d #ffd27a; ridges #c4547a #a2457c #7e3a7c #5a2f78 #3d2468; silhouette #160d22; rim #ffb347; enemy rim #ff5d73; hot #fff1b8; HUD cream at 30-85% alpha.

- Pack vs code: no packs. Sky, ridges, terrain, tanks (polygons), shell, explosion, debris, smoke, HUD all in code.
- Final art would need: real tank silhouettes with animated tracks/recoil, GPUParticles for blast/smoke/embers, parallax ridges + drifting clouds, a proper thin display font, crater as a real destructible-terrain mask.

Capture: godot --path mockups/atmospheric-silhouette --resolution 1280x720 --position 3000,3000 -- --capture
