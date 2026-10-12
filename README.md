# RetroVision

Screen filters for World of Warcraft: Forever. Retro looks: CRT scanlines, phosphor masks, rounded glass, film grain, VHS tracking noise, ordered dithering and low-res point-sampled rendering. Pretty looks: color gradients, edge glow, haze, light leaks, god rays, aurora, underwater caustics, holographic shimmer, bokeh, two layers of ambient particles (fireflies, snow, embers, rain, cherry petals, autumn leaves, stars, sparkles, bubbles, arcane motes, ash, dust), high-end graphics and a cinematic camera. Includes 63 presets.

## Install

1. Close the game.
2. Copy the `RetroVision` folder into the game's AddOns folder. Forever has its own client folder next to Retail and Classic:
   `World of Warcraft\_<forever folder>_\Interface\AddOns\RetroVision`
   (the folder name inside `World of Warcraft` is whatever Battle.net created for Forever).
3. Start the game. On the character screen, open **AddOns** and make sure RetroVision is ticked.
4. If it shows as **Out of date**, tick **Load out of date AddOns**.
   RetroVision targets the Forever beta (client 1.60.1, interface 16001). If a later patch flags it as incompatible, type `/dump (select(4, GetBuildInfo()))` in game and put that number first on the `## Interface:` line of `RetroVision.toc`.

## Use

- `/retro` opens the settings window.
- **Preset strength** (top of the preset list) turns the active preset's key ingredients up or down, from 0% to 200%.
- The same settings are in the game's own menu: **Esc → Options → AddOns → RetroVision** (or `/retro settings`).
- The add-on menu button by the minimap (if your client has one) lists RetroVision: left-click for settings, right-click to toggle effects.
- `/retro vhs`, `/retro arcade`, `/retro film`... jumps straight to a preset (partial names work).
- `/retro next` / `/retro prev` cycle through presets.
- `/retro on` / `/retro off` / `/retro toggle`
- `/retro ui` switches between affecting only the 3D world (UI stays crisp) and the whole screen.
- `/retro restore` undoes every graphics setting RetroVision changed.
- Key bindings for toggle, next, previous and settings are under **Key Bindings → AddOns**.

Hover anything in the settings window for an explanation. Every setting is a fine slider: the mouse wheel moves one step (hold Shift for ten), and you can click any number and type an exact value (for example `37.5` for a 37.5% render scale). **Save...** stores your current mix as a named preset; right-click a saved preset to delete it.

## Presets

| Preset | What it does |
|---|---|
| CRT Monitor | Soft scanlines, aperture grille, rounded glass. No graphics changes. |
| Arcade Cabinet | Chunky lines, slot mask, heavy curvature, 50% point-sampled res, 4:3 |
| VHS Tape | Warm smear, purple shadows, grain, rolling tracking band, flicker |
| 2004 Vanilla | Modern lighting off, classic glow on, older filtering, warm palette |
| Pixel Art | 33% resolution, crisp pixels, light dither |
| Lo-Fi 32-bit | 50% res, heavy dither, 30 FPS, short foggy view distance |
| Pocket Green | Green handheld screen, 25% res, 10:9 window |
| Amber Terminal / Green Phosphor | Monochrome-style phosphor monitors |
| Old Film | Sepia, grain, flicker, cinema bars, 24 FPS |
| Noir | Cold, contrasty, near-monochrome, cinema bars |
| Dreamy Bloom | Glow with lifted pastel shadows |

## Pretty tabs

The settings have two rows of tabs: the top row (orange) is retro, the bottom row (blue) is pretty.

- **Light**: sky-to-ground color gradient (multiply, glow or paint), colored edge glow that can breathe, atmospheric haze, drifting light leaks, swaying god rays from any top corner.
- **Magic**: rainbow color drift, holographic shimmer, breathing light, northern lights, underwater caustics, bokeh and lens dust.
- **Particles**: two independent layers, each with 12 types, color, amount (up to 400), size, speed, opacity, wind and twinkle.
- **Quality**: render scale up to 200% (supersampling), sun shafts, particle/spell density, ground clutter, environment and liquid detail, depth effects, projected textures, weather density, outlines, max zoom-out, field of view and the game's hidden ActionCam (over-the-shoulder, dynamic pitch, head movement).

Every color has a swatch: click it to open the game's color picker.

Pretty presets: Golden Hour, Enchanted Forest, Winter Wonderland, Sakura Spring, Autumn Breeze, Aurora Night, Underwater, Neon Nights, Inferno, Dreamscape, Arcane and Ultra Cinematic. The preset list scrolls with the mouse wheel.

- **Style**: comic ink border, halftone dots, crosshatching (both can fade toward the edges), anime speed lines, graffiti paint splatters in two colors, and the game's own color-remap filter. The **Color** tab also has paper texture and misregistered color fringes.

Stylized presets (inspired by): Comic Multiverse (Spider-Verse), Phantom Thief (Persona 5), Celestial Brush (Okami), Pandora Ink (Borderlands), Rubber Hose '30s (Cuphead), Neon Hotline (Hotline Miami), Silhouette (Limbo/Inside), Watercolor Dream (Gris), High-Key Runner (Mirror's Edge), Samurai Cinema (Ghost of Tsushima), Desert Pilgrim (Journey), Toon Seas (The Wind Waker).

- **Filter** (pink row): Instagram-style color grading on every pixel: 20 looks (Vivid Pop, Golden, Cool Matte, Rose Film, Teal & Orange, Faded Polaroid, Lomo, Bleach Bypass, Cross Process, Kodachrome, Cyanotype, Infrared Pink, Moonlight, Sunset Pop, Mint, Lavender Haze, Sepia, Neon Pop, Toxic, Blood Moon), then intensity, warmth, tint, fade, contrast, brightness, highlight and shadow colors, vignette, auto exposure, and the game's own hue-remap filter.
- **Trippy**: wobbling colors, rainbow bands sweeping over the world, beat strobe, cycling hue remap, breathing brightness, swaying camera and breathing field of view.

Add-ons can only multiply or add light to the picture, so a true color *invert* isn't possible; the hue remap (the game's colorblind filter) is the one effect that genuinely moves colors between channels.

Retro and pretty effects stack. For example, VHS Tape plus snow particles works fine; the retro filters draw on top.

## Shader techniques used

The retro filters re-implement ideas from well-known shader projects (no code copied; WoW add-ons can't run shaders):

- **CRT-Lottes / CRT-Royale / Guest-Advanced**: Gaussian electron-beam scanlines set by line count (224-1080) with 5 beam hardness levels; sub-pixel phosphor masks (2px magenta/green, 3px RGB grille, 4px aperture grille, slot mask, dot triad); brightness compensation that gives back the light masks and scanlines take away; glass glare; rolling refresh bar.
- **Film grain models**: zero-mean Gaussian grain that both darkens and brightens, four animated frames, optional color grain; dust and scratches.
- **VHS / NTSC simulators (ntsc-rs etc.)**: tracking band, head-switching noise at the bottom of the picture, snow, tape dropouts, camcorder on-screen display.
- **Dithering**: Bayer 4x4, Bayer 8x8 and blue noise. **LCD**: handheld pixel grid that lines up with the render scale. **Vignette**: natural cos^4 lens falloff, dithered so it never bands.

## How it works (and its limits)

Blizzard's addon API does not allow real pixel shaders. RetroVision works in two ways instead:

- **Overlays.** Textures are drawn over the screen with multiply, additive and alpha blending. They are tiled to land exactly on your monitor's pixels. This covers scanlines, masks, grain, dither, VHS, vignette, corners, tint, shadow lift and bars.
- **The game's own graphics settings.** These handle the pixelation (render scale with point upscaling), texture filtering, full-screen glow, view distance, FPS cap, shadows/SSAO/AA, gamma, contrast and brightness.

Because an addon can't read the rendered image, these looks are **not possible**: true grayscale, palette reduction (a real 4-color handheld palette), screen curvature/warping, chromatic aberration and blur. Strong tints plus dithering get close to grayscale and palette looks.

**Your graphics settings are safe.** RetroVision backs up every setting before it changes one. The original comes back when you turn that option off, switch effects off, or use `/retro restore`. It is also put back every time you log out, so removing the addon never leaves your game at 25% resolution.

Some graphics options are named differently depending on the client build. Any setting the client doesn't recognise is skipped silently.

## Tips

- The phosphor masks and scanlines darken the picture. Turn on **Override brightness** or **Override gamma** on the Graphics tab to compensate.
- On 1440p or 4K screens, set the scanline and mask size to 2x or 3x.
- Match **Dither size** to your pixelation: 50% → 2x, 33% → 3x, 25% → 4x.
- Typing `off` into Pixelate, View distance, FPS cap or Picture shape sets it back to "Leave alone".
- **Cover interface** off keeps your action bars and chat readable; turn it on for screenshots and videos.
