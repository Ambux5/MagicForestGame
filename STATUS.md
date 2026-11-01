# MAGICAL FOREST RPG – DEVELOPMENT STATUS
# Vytvořeno: 2026-10-31 | Aktualizováno: 2026-10-31

================================================================================
  STAV PROJEKTU: FÁZE 1-2 DOKONČENA + UI FIX + LAN MULTIPLAYER PŘIDÁN
================================================================================

PROJEKT:        C:\Project\game\Magic\
GODOT:          4.7.2 stable
ARCHITEKTURA:   Všechny .gd a .tscn soubory – čisté, validováno headless
HEADLESS TEST:  14/14 scén OK, 0 runtime chyb, běželo 10 s bez pádu

Pro pokračování na výkonnějším PC:
  → Stáhnout Godot 4.7.2 pro svou platformu z https://godotengine.org/download
  → Otevřít složku MagicalForest/ jako projekt v Godot Editoru
  → Pokračovat dle REMAINING_WORK sekce níže

================================================================================
  CO JE HOTOVO (fáze 1-2)
================================================================================

HOTOVÉ SYSTÉMY:
  ✅ project.godot          – autoloady, input mapa, GL Compatibility renderer
  ✅ GameManager            – globální stav hráče, XP, levely, zdraví, mana, pauza
  ✅ AudioManager           – audio bus systém, pool SFX hráčů, načítání nastavení
  ✅ SaveSystem             – uložení/načtení hry (ConfigFile), settings persistence
  ✅ Hráč (CharacterBody3D) – WASD pohyb, SpringArm3D kamera, sprint, skok, gravitace
  ✅ Wizard mesh builder    – procedurální čaroděj (roucho, klobouk, hůl s krystalem)
  ✅ Animace hráče          – idle/walk/run/jump/fall/cast/hurt/death (keyframe)
  ✅ Systém kouzel          – 4 kouzla: Nature Bolt, Fireball, Healing, Nature Shield
  ✅ base_enemy.gd          – AI stavový automat: IDLE→PATROL→CHASE→ATTACK→HURT→DEAD
  ✅ Forest Slime           – poskakující zelený sliz, procedurální mesh
  ✅ Mushroom Monster       – chodící houba s výtrusy, procedurální mesh
  ✅ Forest Goblin          – hbitý goblin s kyjem, procedurální mesh
  ✅ HUD                    – HP/MP/XP bary, 4 sloty kouzel s cooldown overlay (OPRAVENO)
  ✅ Enemy health bar       – zobrazuje se při zacílení na nepřítele (raycasting)
  ✅ Pause menu             – Resume/Save/Settings/MainMenu/Exit
  ✅ Settings menu          – zvuk, citlivost kamery, fullscreen, grafika, stíny
  ✅ Main menu              – animované pozadí, New/Continue/Multiplayer/Settings/Credits/Exit
  ✅ Collectibles           – 4 typy: Healing Herb, Mana Crystal, Magic Mushroom, XP Crystal
  ✅ World scéna            – terén, procedurální les, ruiny, jezírka, magické kameny
  ✅ Procedurální stromy    – 4 variace (kulatý, vysoký, široký, starý)
  ✅ Atmosféra              – ProceduralSky, fog, ambient light, OmniLight na magických kamenech
  ✅ RPG progrese           – levely 1-10+, XP tabulka, bonusy při levelupu
  ✅ Enemy respawn          – po 20 sekundách, max 12 aktivních nepřátel
  ✅ LAN Multiplayer        – ENet, lobby host/join, jméno hráče, pozice sync (nové)
  ✅ Game Over Try Again    – tlačítko "Try Again" na obrazovce porážky (nové)

ARCHITEKTURA SOUBORŮ:
  scenes/
    menus/main_menu.tscn
    menus/lobby_menu.tscn      ← NOVÉ
    player/player.tscn
    enemies/forest_slime.tscn
    enemies/mushroom_monster.tscn
    enemies/forest_goblin.tscn
    spells/nature_bolt.tscn
    spells/fireball.tscn
    spells/healing_spell.tscn
    spells/nature_shield.tscn
    environment/world.tscn
    ui/hud.tscn
    ui/pause_menu.tscn
    ui/settings_menu.tscn
    items/collectible.tscn

  scripts/
    systems/game_manager.gd       ← autoload
    systems/audio_manager.gd      ← autoload
    systems/save_system.gd        ← autoload
    player/player.gd
    player/wizard_mesh_builder.gd
    enemies/base_enemy.gd
    enemies/forest_slime.gd
    enemies/mushroom_monster.gd
    enemies/forest_goblin.gd
    spells/base_spell.gd
    spells/nature_bolt.gd
    spells/fireball.gd
    spells/healing_spell.gd
    spells/nature_shield.gd
    ui/hud.gd
    ui/main_menu.gd
    ui/pause_menu.gd
    ui/settings_menu.gd
    items/collectible.gd
    environment/world.gd
    environment/tree_builder.gd

================================================================================
  CO ZBÝVÁ – PRIORITNÍ POŘADÍ (fáze 3-7)
================================================================================

PRIORITA 1 – NUTNÉ PRO HRATELNOST
───────────────────────────────────
[ ] AUDIO – přidat skutečné zvukové soubory do assets/audio/
    Soubory musí být .ogg nebo .wav, registrovat v audio_manager.gd → _register_streams()
    Potřebné klíče:
      forest_ambience, ui_click, ui_hover, player_hurt, enemy_hurt, enemy_die,
      fireball_impact, healing, shield_activate, collect_herb, collect_crystal
    Doporučený zdroj (CC0): https://freesound.org  nebo  https://opengameart.org

[ ] KAMERA KOLIZE – otestovat a doladit SpringArm3D
    Soubor: scenes/player/player.tscn → SpringArm3D.collision_mask
    Problém: kamera může projít zdí, pokud collision_mask není správně nastavena
    Fix: nastavit spring_arm.collision_mask = 1 (jen vrstva 1 = terén)

[ ] TERRAIN KOLIZE – přidat MeshLibrary nebo NavigationRegion3D
    Aktuální stav: terén má BoxShape3D, ale jen rovnou plochu
    Doporučeno: přidat NavigationRegion3D pro lepší AI pathfinding

[ ] GAME OVER SCREEN – přidat tlačítko "Retry"
    Soubor: scripts/ui/hud.gd → _build_game_over()
    Přidat: btn "Try Again" → GameManager.start_new_game()

PRIORITA 2 – VIZUÁLNÍ VYLEPŠENÍ
─────────────────────────────────
[ ] 3D MODELY – nahradit procedurální meshe importovanými .glb modely
    Doporučeno: Kenney's FREE assets nebo Quaternius (CC0 GLTF)
      https://kenney.nl/assets/nature-kit
      https://quaternius.com/packs/ultimatenature.html
    Postup: importovat .glb, nahradit MeshInstance3D v tscn souborech

[ ] TEXTURY – přidat albedo textury k materiálům
    Aktuální: čisté barvy (StandardMaterial3D bez textur)
    Doporučeno: jednoduché 64x64 nebo 128x128 stylizované textury (grass, stone, wood)

[ ] POST-PROCESSING – volitelné pro výkonnější PC
    Přidat: WorldEnvironment → SSAO (nízká intenzita), Glow (subtle)
    POZOR: vypnout na Raspberry Pi (Settings → Graphics Quality Low)

[ ] VODA SHADER – animovaná voda v jezerech
    Aktuální: statická průhledná plocha
    Přidat: ShaderMaterial s vertex displacement + UV scroll

[ ] MAGICKÉ ČÁSTICE – rozšířit particle systémy na stromech a rostlinách
    Soubor: scripts/environment/world.gd → _build_environment()
    Přidat: GPUParticles3D s "firefly" efektem na specifických místech

PRIORITA 3 – GAMEPLAY ROZŠÍŘENÍ
─────────────────────────────────
[ ] INVENTORY SYSTÉM
    Aktuální: collectibles se sbírají automaticky, žádný inventář
    Nový soubor: scripts/systems/inventory.gd
    HUD update: přidat "I" klávesa → zobrazit inventář (CanvasLayer)

[ ] QUEST/DIALOGUE SYSTÉM (volitelné)
    Jednoduchý trigger: Area3D u oltáře ruin → dialog popup
    Nový soubor: scripts/systems/quest_manager.gd

[ ] BOSS ENEMY (volitelné)
    Nový soubor: scripts/enemies/forest_guardian.gd (extends base_enemy)
    Větší health pool, speciální attack pattern, spawn reward

[ ] SPELL UPGRADE SYSTÉM
    Při levelupu nabídnout hráči upgrade jednoho kouzla
    Upravit: game_manager.gd → _apply_level_up_bonuses()

[ ] VÍCE SVĚTŮ / ZÓNY
    Aktuální: jedna velká world.tscn
    Přidat: portal Area3D → change_scene_to_file() do dalšího světa

PRIORITA 4 – POLISH & OPTIMALIZACE
─────────────────────────────────────
[ ] LOD (Level of Detail) – důležité pro Raspberry Pi
    Přidat: VisibleOnScreenNotifier3D na vzdálené stromy
    Skrýt/zjednodušit meshe mimo hráčův view frustum

[ ] OBJECT POOLING pro projektily
    Aktuální: instantiate/queue_free při každém kouzlu
    Optimalizace: recyklovat 10-20 předalokovaných instancí

[ ] VÍCE ANIMAČNÍCH KLÍČŮ pro nepřátele
    Aktuální: velmi jednoduché stub animace
    Vylepšit: reálný walk cycle (kývání těla, nohy)

[ ] MINIMAP (volitelné)
    SubViewport s ortogonální kamerou shora → TextureRect v HUD
    Marker pro hráče a nepřátele

[ ] CREDITS SCENE oddělená
    Aktuální: credits jsou popup v main menu
    Doporučeno: samostatná scenes/menus/credits.tscn

================================================================================
  TECHNICKÉ POZNÁMKY PRO DALŠÍ VÝVOJ
================================================================================

COLLISION LAYERS (projekt používá):
  Layer 1 (mask 1)  = Terén, skály, zdi (StaticBody3D)
  Layer 2 (mask 2)  = Hráč (Player CharacterBody3D)
  Layer 3 (mask 4)  = Nepřátelé (Enemy CharacterBody3D)
  Layer 4 (mask 8)  = Kouzla / Area3D projektily
  Layer 5 (mask 16) = Collectibles (Area3D)

AUTOLOADY (globálně přístupné v jakémkoliv skriptu):
  GameManager   – hráčovy statistiky, signály, správa scén
  AudioManager  – playback zvuků, nastavení hlasitosti
  SaveSystem    – ukládání/načítání, settings

SIGNÁLY (nejdůležitější):
  GameManager.health_changed(current, maximum)
  GameManager.mana_changed(current, maximum)
  GameManager.level_up(new_level)
  GameManager.experience_gained(amount, total)
  GameManager.player_died
  GameManager.game_paused(paused)
  GameManager.enemy_targeted(enemy_node)
  GameManager.enemy_untargeted
  base_enemy.died(position, xp_reward)

JAK PŘIDAT NOVÉ KOUZLO:
  1. Zkopírovat scripts/spells/nature_bolt.gd → scripts/spells/novy_spell.gd
  2. Přizpůsobit damage, speed, color, efekty
  3. Vytvořit scenes/spells/novy_spell.tscn (Area3D + script)
  4. Přidat cestu do SPELL_PATHS v scripts/player/player.gd
  5. Přidat mana cost do SPELL_MANA_COSTS
  6. Přidat cooldown do GameManager.spell_max_cooldowns

JAK PŘIDAT NOVÉHO NEPŘÍTELE:
  1. Zkopírovat scripts/enemies/forest_slime.gd → scripts/enemies/novy.gd
  2. Upravit stats (max_health, move_speed, detect_radius, ...)
  3. Implementovat _build_mesh() a _build_animations()
  4. Vytvořit scenes/enemies/novy.tscn (CharacterBody3D + CapsuleShape3D + script)
  5. Přidat cestu do ENEMY_TYPES v scripts/environment/world.gd

VÝKON – Raspberry Pi 4 limity:
  - MAX_ENEMIES = 12 (world.gd, řádek ~15)
  - AI_TICK = 0.15 s (base_enemy.gd, řádek ~27) – nezkracovat pod 0.1s
  - Stíny: vypnuté defaultně, zapnout jen Medium/High kvalita
  - Renderer: GL Compatibility (NIKDY měnit na Forward+/Vulkan na RPi4)
  - Particles: fixed_fps = 20-30 (NIKDY 60+)

ADRESÁŘOVÁ STRUKTURA – uložení dat na Linuxu:
  Uložené hry:  ~/.local/share/godot/app_userdata/Magical Forest/save_game.cfg
  Nastavení:    ~/.local/share/godot/app_userdata/Magical Forest/settings.cfg

================================================================================
  RYCHLÝ START NA NOVÉM PC
================================================================================

  1. Přenést složku /root/projects/MagicalForest/ na nový PC
     (git, USB, scp, archiv – cokoliv funguje)

  2. Stáhnout Godot 4.7.2 pro svou platformu:
     https://godotengine.org/download

  3. Spustit Godot → "Import" → vybrat složku MagicalForest/ → "Import & Edit"

  4. Godot automaticky:
     - Reimportuje všechny .tscn soubory (může chvíli trvat)
     - Upozorní na chybějící audio soubory (normální – viz PRIORITA 1)
     - Nabídne migraci projektu (odmítnout – projekt je pro 4.7.x)

  5. Spustit F5 → New Game → hra by měla najet

  6. Pokračovat dle REMAINING_WORK pořadí výše

PROMPT PRO NOVÉ OKNO (zkopírovat & vložit):
  ─────────────────────────────────────────────────────────────────
  Pokračuji ve vývoji hry Magical Forest RPG (Godot 4.7.2, GDScript).
  Projekt je ve složce [cesta]. Přečti soubor STATUS.md pro stav vývoje.
  Požadavky jsou v requieremnts.txt. Pokračuj od PRIORITY 1 – AUDIO
  a KAMERA KOLIZE. Poté přejdi na PRIORITA 2 vizuální vylepšení.
  Cílová platforma: výkonnější PC (Linux/Windows), sekundárně Raspberry Pi 4.
  ─────────────────────────────────────────────────────────────────

================================================================================
  VERZE A ZMĚNY
================================================================================

  2026-10-31  v0.1  Prvotní implementace (fáze 1-2)
                    - Celý herní základ postaven od nuly
                    - Godot 4.7.2 nainstalován na RPi4 (ARM64)
                    - Headless validace: 14/14 scén OK
                    - Opraveny type-inference chyby pro Godot 4.7
                    - Opravena @onready vs procedural mesh race condition
                    - Přidán enemy targeting systém

================================================================================
