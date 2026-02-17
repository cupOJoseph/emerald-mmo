# Emerald MMO — Project Spec

> A Pokemon Emerald-style MMO RPG built with Godot 4 + SpacetimeDB

## Vision
Top-down 16x16 pixel art MMO that feels like Pokemon Emerald but multiplayer. Players explore, see each other in real-time, chat, battle, trade. The vibe is nostalgic GBA but with modern multiplayer.

## Tech Stack
- **Engine**: Godot 4 (GDScript primary, C# for SpacetimeDB client)
- **Multiplayer DB**: SpacetimeDB (real-time sync via WebSocket, hosted at spacetimedb.com/@cupojoseph)
- **Tileset**: fikrydev's "Another RPG Tileset" (16x16, CC-BY-4.0)
- **Art style**: Pokemon Emerald inspired — 16x16 tiles, 4-directional player sprites

## Architecture

```
┌──────────────┐     WebSocket      ┌──────────────────┐
│  Godot Client │◄──────────────────►│  SpacetimeDB     │
│  (GDScript/C#)│     Real-time     │  (Rust modules)  │
│              │     sync           │                  │
│  - Rendering │                    │  - Player state  │
│  - Input     │                    │  - World state   │
│  - Animation │                    │  - Chat          │
│  - UI        │                    │  - Combat logic  │
└──────────────┘                    └──────────────────┘
```

## SpacetimeDB Module (Rust)

### Tables
```rust
#[table(name = player, public)]
pub struct Player {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub identity: Identity,
    pub username: String,
    pub x: f32,
    pub y: f32,
    pub direction: u8,       // 0=down, 1=up, 2=left, 3=right
    pub map_id: String,      // which map they're on
    pub is_moving: bool,
    pub sprite_id: u8,       // character sprite variant
    pub online: bool,
    pub last_active: u64,
}

#[table(name = chat_message, public)]
pub struct ChatMessage {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub sender_id: u64,
    pub sender_name: String,
    pub message: String,
    pub timestamp: u64,
    pub map_id: String,
}

#[table(name = npc, public)]
pub struct Npc {
    #[primary_key]
    pub id: u64,
    pub name: String,
    pub x: f32,
    pub y: f32,
    pub map_id: String,
    pub direction: u8,
    pub dialogue: String,
    pub sprite_id: u8,
}
```

### Reducers
```rust
// Player management
fn register_player(ctx, username: String, sprite_id: u8)
fn update_position(ctx, x: f32, y: f32, direction: u8, is_moving: bool)
fn change_map(ctx, map_id: String, x: f32, y: f32)
fn player_disconnect(ctx)

// Chat
fn send_message(ctx, message: String)

// Future: combat, trading, inventory
```

## Godot Project Structure

```
emerald-mmo/
├── project.godot
├── assets/
│   ├── tilesets/
│   │   └── rpg_tileset.png        # fikrydev tileset
│   ├── sprites/
│   │   ├── player/                # Player sprite sheets (4-dir walk)
│   │   └── npcs/                  # NPC sprites
│   └── ui/
├── scenes/
│   ├── main.tscn                  # Entry scene
│   ├── world/
│   │   ├── overworld.tscn         # Main overworld map
│   │   ├── town_start.tscn        # Starting town
│   │   └── route_1.tscn           # First route
│   ├── player/
│   │   ├── player.tscn            # Local player scene
│   │   └── remote_player.tscn     # Other players
│   ├── npc/
│   │   └── npc.tscn
│   └── ui/
│       ├── login_screen.tscn
│       ├── chat_box.tscn
│       ├── hud.tscn
│       └── dialogue_box.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd        # Global game state
│   │   └── network_manager.gd     # SpacetimeDB connection
│   ├── player/
│   │   ├── player_controller.gd   # Movement, input
│   │   └── remote_player.gd       # Sync other players
│   ├── world/
│   │   ├── map_manager.gd         # Map loading/transitions
│   │   └── camera_controller.gd   # Smooth follow camera
│   ├── npc/
│   │   └── npc_controller.gd
│   └── ui/
│       ├── chat_box.gd
│       ├── dialogue_box.gd
│       └── login_screen.gd
└── server/
    ├── Cargo.toml                  # SpacetimeDB Rust module
    └── src/
        └── lib.rs
```

## Core Systems

### 1. Movement (Pokemon Emerald Style)
- Grid-based: player snaps to 16x16 grid
- 4-directional (WASD or arrow keys)
- Smooth tween between tiles (not instant snap)
- Collision with walls, water, objects
- Tall grass triggers encounters (future)
- Running with Shift key (2x speed)

### 2. Multiplayer Sync
- Player position synced via SpacetimeDB subscriptions
- Other players rendered as RemotePlayer nodes
- Interpolate remote player movement for smoothness
- Players only see others on the same map
- Name labels above player sprites

### 3. Maps
- Built with Godot TileMap using the fikrydev tileset
- Multiple maps connected via warp zones (doors, paths)
- Collision layer for walls/obstacles
- Grass layer for encounter zones
- Water layer (surfable later)

### 4. Chat
- Simple text chat visible to players on same map
- Chat bubbles above player heads
- Chat box at bottom of screen
- Press Enter to type, Enter to send

### 5. NPCs
- Static NPCs with dialogue
- Face player when talked to
- Dialogue box (Pokemon style — bottom of screen, typewriter text)

## Phases

### Phase 1: Foundation (MVP) ← START HERE
- [ ] Godot 4 project setup with tileset
- [ ] Player scene with grid-based 4-dir movement
- [ ] Camera follow
- [ ] One map (starting town) built with TileMap
- [ ] SpacetimeDB module with Player table
- [ ] Connect Godot → SpacetimeDB
- [ ] See other players moving in real-time
- [ ] Basic login screen (pick username + sprite)

### Phase 2: World Building
- [ ] Multiple maps with warp transitions
- [ ] NPCs with dialogue system
- [ ] Chat system
- [ ] Collision refinement
- [ ] Running (shift)
- [ ] Map transitions with fade effect

### Phase 3: Game Systems
- [ ] Inventory system
- [ ] Wild encounters (tall grass)
- [ ] Basic turn-based battle system
- [ ] Pokemon-style party system
- [ ] Trading between players

### Phase 4: Polish
- [ ] Sound effects + music
- [ ] Day/night cycle
- [ ] Weather effects
- [ ] More maps, more NPCs
- [ ] Quests
