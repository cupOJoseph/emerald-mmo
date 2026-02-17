use spacetimedb::{Identity, ReducerContext, Table};

#[spacetimedb::table(name = player, public)]
pub struct Player {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub owner_identity: Identity,
    pub username: String,
    pub x: f32,
    pub y: f32,
    pub direction: u8,
    pub map_id: String,
    pub is_moving: bool,
    pub sprite_id: u8,
    pub online: bool,
}

#[spacetimedb::table(name = chat_message, public)]
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

fn find_player_by_identity(ctx: &ReducerContext, identity: &Identity) -> Option<Player> {
    ctx.db.player().iter().find(|p| p.owner_identity == *identity)
}

#[spacetimedb::reducer]
pub fn register_player(ctx: &ReducerContext, username: String, sprite_id: u8) -> Result<(), String> {
    let username = username.trim().to_string();
    if username.is_empty() {
        return Err("Username cannot be empty".into());
    }
    if username.len() > 20 {
        return Err("Username too long (max 20 characters)".into());
    }
    if ctx.db.player().iter().any(|p| p.username == username) {
        return Err("Username already taken".into());
    }
    if find_player_by_identity(ctx, &ctx.sender).is_some() {
        return Err("Player already registered".into());
    }
    ctx.db.player().insert(Player {
        id: 0,
        owner_identity: ctx.sender,
        username,
        x: 160.0,
        y: 160.0,
        direction: 0,
        map_id: "town_start".into(),
        is_moving: false,
        sprite_id,
        online: true,
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn update_position(ctx: &ReducerContext, x: f32, y: f32, direction: u8, is_moving: bool) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    ctx.db.player().id().update(Player {
        x,
        y,
        direction,
        is_moving,
        ..player
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn change_map(ctx: &ReducerContext, map_id: String, x: f32, y: f32) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    ctx.db.player().id().update(Player {
        map_id,
        x,
        y,
        is_moving: false,
        ..player
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn send_message(ctx: &ReducerContext, message: String) -> Result<(), String> {
    let message = message.trim().to_string();
    if message.is_empty() {
        return Err("Message cannot be empty".into());
    }
    if message.len() > 500 {
        return Err("Message too long".into());
    }
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    ctx.db.chat_message().insert(ChatMessage {
        id: 0,
        sender_id: player.id,
        sender_name: player.username.clone(),
        message,
        timestamp: ctx.timestamp.to_duration_since_unix_epoch().unwrap_or_default().as_secs(),
        map_id: player.map_id.clone(),
    });
    Ok(())
}

#[spacetimedb::reducer(client_disconnected)]
pub fn on_disconnect(ctx: &ReducerContext) {
    if let Some(player) = find_player_by_identity(ctx, &ctx.sender) {
        ctx.db.player().id().update(Player {
            online: false,
            is_moving: false,
            ..player
        });
    }
}

#[spacetimedb::reducer(client_connected)]
pub fn on_connect(ctx: &ReducerContext) {
    if let Some(player) = find_player_by_identity(ctx, &ctx.sender) {
        ctx.db.player().id().update(Player {
            online: true,
            ..player
        });
    }
}
