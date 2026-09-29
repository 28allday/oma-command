# OMA-COMMAND

A vector missile-defence arcade game built with Love2D for [Omarchy](https://omarchy.org/) Linux.

Vector-rendered cities and trails with bloom, flashing explosion palettes, and Omarchy theme integration — the game adopts your desktop colours.

[![OMA-COMMAND gameplay](https://img.youtube.com/vi/pnwiKlbC574/maxresdefault.jpg)](https://youtu.be/pnwiKlbC574)

## Install

```bash
curl -sL https://raw.githubusercontent.com/28allday/oma-command/master/install.sh | bash
```

This will:
- Install Love2D if not present
- Clone the game to `~/.local/share/oma-command/`
- Add an icon and launcher entry to your app menu
- Refresh the app launcher

Search **OMA-COMMAND** in your app launcher to play.

## Uninstall

```bash
oma-command-uninstall
```

## Controls

| Input | Action |
|-------|--------|
| **Mouse** | Move crosshair |
| **Left click** | Fire from nearest battery with ammo |
| **A** / **1** | Fire from Bravo (left) battery |
| **S** / **2** | Fire from Kilo (centre, fast) battery |
| **D** / **3** | Fire from Sierra (right) battery |
| **Enter** | Start game / dismiss screens |
| **Escape** | Pause / quit |
| **F1** | Toggle CRT effect |
| **F11** | Toggle fullscreen |

## Gameplay

- Three missile batteries defend six cities against incoming ICBMs
- Kilo (centre) ABMs fly fast; Bravo and Sierra are slower but still precise
- Missiles split into MIRVs mid-flight; smart bombs dodge your explosions
- Bombers appear from wave 2, satellites from wave 4, killer satellites from wave 8
- Chain explosions by detonating ABMs near incoming warheads
- Maximum 3 cities can be lost per wave
- Bonus city every 10,000 points
- Persistent high scores with 3-letter initials

## Scoring

| Target | Base Points |
|--------|-------------|
| ICBM | 25 |
| Smart bomb | 125 |
| Bomber | 100 |
| Satellite | 100 |
| Killer satellite | 150 |
| Unused ABM (end of wave) | 5 × multiplier |
| Surviving city (end of wave) | 100 × multiplier |

Wave score multiplier: ×1 (waves 1–2), ×2 (3–4), ×3 (5–6), ×4 (7–8), ×5 (9–10), ×6 (11+).

## Omarchy Integration

- **Theme colours** auto-detected from your active Omarchy theme
- **System font** detected from your Waybar config
- **Full-screen** via SUPER+F (Hyprland compositor)
- Switch themes with `omarchy-theme-set` and relaunch — the game adapts

## Requirements

- [Omarchy](https://omarchy.org/) Linux (or any Arch with Love2D)
- Love2D (`sudo pacman -S love`)

## Run from source

```bash
git clone https://github.com/28allday/oma-command.git
cd oma-command
love .
```

## Originality

This is a missile-defence game, and it is not the first one. What it owes to the
genre are its rules — defend cities, three batteries, warheads that split,
explosions that chain — and rules are not anyone's property.

Everything you can see or hear is this project's own. The city outlines and the
launchers were drawn by hand in the game's own coordinate space, the palette is
derived from your active theme at runtime, and every sound is synthesised by
`audio/sounds.lua` rather than sampled. No code, art, audio or text has been
taken from any commercial game, and there is no affiliation with, or
endorsement by, any game publisher.

## License

MIT
