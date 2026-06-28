# Sole Survivor

A 2D platformer built in **Godot 4.6** (project name: **Cry of Crease**).

Play as a stick-figure character with procedural limbs, standing/handstand movement, jump animations, and pixel Jordan-style shoes.

## Requirements

- [Godot 4.6](https://godotengine.org/download) (Forward Plus)

## Run locally

1. Clone the repo:
   ```bash
   git clone https://github.com/ar-bh/sole-survivor.git
   cd sole-survivor
   ```
2. Open the project in Godot (`project.godot`).
3. Press **F5** or click **Run Project**.

Main scene: `game/main.tscn` · Level select UI: `game/level_select/` · Maps: `game/level_select/maps/`

## Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move left | `A` / Left arrow | Left stick / D-pad |
| Move right | `D` / Right arrow | Left stick / D-pad |
| Jump | `Space` / Up arrow | `A` / South button |
| Handstand | `Shift` (hold) | Right trigger |

## Features

- Procedural **arms and legs** (Line2D) synced to movement and air state
- **Standing** and **handstand** modes with separate animations
- Jump variants: vertical, moving, rise/fall body sprites
- **Jordan-style shoe** pixel art on feet (colors editable on the Player node)

## Project layout

```
game/
  Player/           Player scene, sprites, player.gd
  level_select/   Level select UI, maps, font assets
  main.tscn       Entry point (level select + gameplay)
addons/             Editor plugins (e.g. Wakatime)
```

## Player tuning

Most movement values live in `game/Player/player.gd`. Limb and shoe tuning lives in `game/Player/player_limbs.gd` — shoe colors are `@export` vars on the **Limbs** node.

## License

See [LICENSE](LICENSE).
