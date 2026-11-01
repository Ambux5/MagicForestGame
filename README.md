# Magical Forest RPG

A stylized low-poly 3D fantasy RPG built with **Godot Engine 4.x**.  
Optimised for **Raspberry Pi 4 (8 GB RAM)** with the GL Compatibility renderer.

---

## Opening the Project

1. Install **Godot 4.x** (4.2 or later recommended).
2. Launch Godot → click **"Import"** → navigate to this folder → select `project.godot`.
3. Click **"Import & Edit"**.
4. Press **F5** (or the ▶ button) to run.

---

## Controls

| Key / Button | Action |
|---|---|
| WASD | Move |
| Mouse | Rotate camera |
| Space | Jump |
| Shift | Sprint |
| LMB | Cast selected spell |
| 1–4 | Select spell slot |
| ESC | Pause / release mouse |
| E | Interact (reserved) |

---

## Spells

| Slot | Spell | Effect |
|---|---|---|
| 1 | Nature Bolt | Fast green projectile, single target |
| 2 | Fireball | Slower projectile, AoE explosion |
| 3 | Healing | Instant heal, no projectile |
| 4 | Nature Shield | 8 s damage-reduction shield |

---

## Project Structure

```
MagicalForest/
├── project.godot          ← Godot 4 project config
├── scenes/
│   ├── menus/             ← main_menu.tscn
│   ├── player/            ← player.tscn (CharacterBody3D + SpringArm3D)
│   ├── enemies/           ← forest_slime / mushroom_monster / forest_goblin
│   ├── spells/            ← nature_bolt / fireball / healing_spell / nature_shield
│   ├── environment/       ← world.tscn (procedural world)
│   ├── ui/                ← hud / pause_menu / settings_menu
│   └── items/             ← collectible.tscn
└── scripts/
    ├── systems/           ← GameManager / AudioManager / SaveSystem (autoloads)
    ├── player/            ← player.gd / wizard_mesh_builder.gd
    ├── enemies/           ← base_enemy.gd + 3 enemy types
    ├── spells/            ← base_spell.gd + 4 spells
    ├── ui/                ← hud / menus / settings
    ├── items/             ← collectible.gd
    └── environment/       ← world.gd / tree_builder.gd
```

---

## Adding Audio

Place `.ogg` or `.wav` files in `assets/audio/` and register them in  
`scripts/systems/audio_manager.gd` inside `_register_streams()`:

```gdscript
_audio_streams["forest_ambience"] = load("res://assets/audio/forest_ambience.ogg")
_audio_streams["ui_click"]        = load("res://assets/audio/ui_click.ogg")
_audio_streams["fireball_impact"] = load("res://assets/audio/fireball.ogg")
```

Expected keys used by the game:
`forest_ambience`, `ui_click`, `ui_hover`, `player_hurt`, `enemy_hurt`,
`enemy_die`, `fireball_impact`, `healing`, `shield_activate`,
`collect_herb`, `collect_crystal`

---

## Performance Notes (Raspberry Pi 4)

- Renderer is set to **GL Compatibility** (best GPU support on RPi4).
- Shadows are **disabled by default** – enable in Settings → Shadow Quality.
- Enemy count capped at **12 active** (configurable in `world.gd`).
- All 3D objects use **low-poly procedural meshes** (no external 3D models needed).
- Target: **30 FPS** at 1280×720 on Raspberry Pi 4.

---

## Save Files

Saves are stored in Godot's `user://` folder:
- **Linux / Raspberry Pi:** `~/.local/share/godot/app_userdata/Magical Forest/`
- Files: `save_game.cfg`, `settings.cfg`
