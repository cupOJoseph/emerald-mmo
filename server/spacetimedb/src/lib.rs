use spacetimedb::{Identity, ReducerContext, Table};

// ─── Tables ───

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
    pub gold: u64,
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

#[spacetimedb::table(name = item_definition, public)]
pub struct ItemDefinition {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub name: String,
    pub description: String,
    pub item_type: String,
    pub rarity: u8,
    pub stackable: bool,
    pub max_stack: u32,
    pub value: u64,
    pub icon_id: u16,
    pub created_by: Identity,
}

#[spacetimedb::table(name = inventory_item, public)]
pub struct InventoryItem {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub player_id: u64,
    pub item_def_id: u64,
    pub quantity: u32,
    pub slot: u8,
    pub is_bank: bool,
}

#[spacetimedb::table(name = trade_offer, public)]
pub struct TradeOffer {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub from_player_id: u64,
    pub to_player_id: u64,
    pub status: String,
    pub from_gold: u64,
    pub to_gold: u64,
    pub from_accepted: bool,
    pub to_accepted: bool,
    pub created_at: u64,
}

#[spacetimedb::table(name = trade_item, public)]
pub struct TradeItem {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub trade_id: u64,
    pub from_player: bool,
    pub item_def_id: u64,
    pub quantity: u32,
}

#[spacetimedb::table(name = admin_role, public)]
pub struct AdminRole {
    #[primary_key]
    pub identity: Identity,
    pub role: String,
    pub granted_by: Identity,
    pub granted_at: u64,
}

// ─── Helpers ───

fn find_player_by_identity(ctx: &ReducerContext, identity: &Identity) -> Option<Player> {
    ctx.db.player().iter().find(|p| p.owner_identity == *identity)
}

fn is_admin(ctx: &ReducerContext) -> bool {
    ctx.db.admin_role().iter().any(|a| a.identity == ctx.sender)
}

fn count_inventory_slots(ctx: &ReducerContext, player_id: u64) -> u8 {
    ctx.db.inventory_item().iter()
        .filter(|i| i.player_id == player_id && !i.is_bank)
        .count() as u8
}

fn now_secs(ctx: &ReducerContext) -> u64 {
    ctx.timestamp.to_duration_since_unix_epoch().unwrap_or_default().as_secs()
}

fn find_or_create_stack(ctx: &ReducerContext, player_id: u64, item_def_id: u64, quantity: u32, is_bank: bool) -> Result<(), String> {
    let item_def = ctx.db.item_definition().id().find(item_def_id)
        .ok_or("Item definition not found")?;

    if item_def.stackable {
        // Try to find existing stack
        if let Some(existing) = ctx.db.inventory_item().iter()
            .find(|i| i.player_id == player_id && i.item_def_id == item_def_id && i.is_bank == is_bank && i.quantity < item_def.max_stack) {
            let new_qty = existing.quantity + quantity;
            if new_qty <= item_def.max_stack {
                ctx.db.inventory_item().id().update(InventoryItem { quantity: new_qty, ..existing });
                return Ok(());
            }
        }
    }

    // Need a new slot
    if !is_bank {
        if count_inventory_slots(ctx, player_id) >= 32 {
            return Err("Inventory full".into());
        }
        // Find empty slot
        let used_slots: Vec<u8> = ctx.db.inventory_item().iter()
            .filter(|i| i.player_id == player_id && !i.is_bank)
            .map(|i| i.slot)
            .collect();
        let slot = (0u8..32).find(|s| !used_slots.contains(s))
            .ok_or("No empty inventory slot")?;
        ctx.db.inventory_item().insert(InventoryItem {
            id: 0, player_id, item_def_id, quantity, slot, is_bank: false,
        });
    } else {
        let slot = ctx.db.inventory_item().iter()
            .filter(|i| i.player_id == player_id && i.is_bank)
            .map(|i| i.slot)
            .max()
            .map(|s| s.wrapping_add(1))
            .unwrap_or(0);
        ctx.db.inventory_item().insert(InventoryItem {
            id: 0, player_id, item_def_id, quantity, slot, is_bank: true,
        });
    }
    Ok(())
}

// ─── Original Reducers ───

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
        gold: 100,
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn update_position(ctx: &ReducerContext, x: f32, y: f32, direction: u8, is_moving: bool) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    ctx.db.player().id().update(Player { x, y, direction, is_moving, ..player });
    Ok(())
}

#[spacetimedb::reducer]
pub fn change_map(ctx: &ReducerContext, map_id: String, x: f32, y: f32) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    ctx.db.player().id().update(Player { map_id, x, y, is_moving: false, ..player });
    Ok(())
}

#[spacetimedb::reducer]
pub fn send_message(ctx: &ReducerContext, message: String) -> Result<(), String> {
    let message = message.trim().to_string();
    if message.is_empty() { return Err("Message cannot be empty".into()); }
    if message.len() > 500 { return Err("Message too long".into()); }
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    ctx.db.chat_message().insert(ChatMessage {
        id: 0,
        sender_id: player.id,
        sender_name: player.username.clone(),
        message,
        timestamp: now_secs(ctx),
        map_id: player.map_id.clone(),
    });
    Ok(())
}

#[spacetimedb::reducer(client_disconnected)]
pub fn on_disconnect(ctx: &ReducerContext) {
    if let Some(player) = find_player_by_identity(ctx, &ctx.sender) {
        ctx.db.player().id().update(Player { online: false, is_moving: false, ..player });
    }
}

#[spacetimedb::reducer(client_connected)]
pub fn on_connect(ctx: &ReducerContext) {
    if let Some(player) = find_player_by_identity(ctx, &ctx.sender) {
        ctx.db.player().id().update(Player { online: true, ..player });
    }
}

// ─── Money System ───

#[spacetimedb::reducer]
pub fn give_gold(ctx: &ReducerContext, target_player_id: u64, amount: u64) -> Result<(), String> {
    if !is_admin(ctx) { return Err("Admin only".into()); }
    let player = ctx.db.player().id().find(target_player_id).ok_or("Player not found")?;
    ctx.db.player().id().update(Player { gold: player.gold + amount, ..player });
    Ok(())
}

#[spacetimedb::reducer]
pub fn transfer_gold(ctx: &ReducerContext, to_player_id: u64, amount: u64) -> Result<(), String> {
    if amount == 0 { return Err("Amount must be > 0".into()); }
    let from = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    if from.gold < amount { return Err("Insufficient gold".into()); }
    let to = ctx.db.player().id().find(to_player_id).ok_or("Target player not found")?;
    if from.id == to.id { return Err("Cannot transfer to yourself".into()); }
    ctx.db.player().id().update(Player { gold: from.gold - amount, ..from });
    ctx.db.player().id().update(Player { gold: to.gold + amount, ..to });
    Ok(())
}

// ─── Inventory System ───

#[spacetimedb::reducer]
pub fn move_item_to_bank(ctx: &ReducerContext, inventory_item_id: u64, quantity: u32) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let item = ctx.db.inventory_item().id().find(inventory_item_id).ok_or("Item not found")?;
    if item.player_id != player.id || item.is_bank { return Err("Invalid item".into()); }
    if quantity == 0 || quantity > item.quantity { return Err("Invalid quantity".into()); }
    let def_id = item.item_def_id;

    if quantity == item.quantity {
        ctx.db.inventory_item().id().delete(inventory_item_id);
    } else {
        ctx.db.inventory_item().id().update(InventoryItem { quantity: item.quantity - quantity, ..item });
    }
    find_or_create_stack(ctx, player.id, def_id, quantity, true)?;
    Ok(())
}

#[spacetimedb::reducer]
pub fn move_item_from_bank(ctx: &ReducerContext, bank_item_id: u64, quantity: u32, target_slot: u8) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let item = ctx.db.inventory_item().id().find(bank_item_id).ok_or("Item not found")?;
    if item.player_id != player.id || !item.is_bank { return Err("Invalid item".into()); }
    if quantity == 0 || quantity > item.quantity { return Err("Invalid quantity".into()); }
    if target_slot >= 32 { return Err("Invalid slot".into()); }

    let item_def = ctx.db.item_definition().id().find(item.item_def_id).ok_or("Item def not found")?;

    // Check target slot
    let existing = ctx.db.inventory_item().iter()
        .find(|i| i.player_id == player.id && !i.is_bank && i.slot == target_slot);

    if let Some(existing) = existing {
        if existing.item_def_id == item.item_def_id && item_def.stackable && existing.quantity + quantity <= item_def.max_stack {
            ctx.db.inventory_item().id().update(InventoryItem { quantity: existing.quantity + quantity, ..existing });
        } else {
            // Try finding empty slot
            let used: Vec<u8> = ctx.db.inventory_item().iter()
                .filter(|i| i.player_id == player.id && !i.is_bank)
                .map(|i| i.slot).collect();
            let slot = (0u8..32).find(|s| !used.contains(s)).ok_or("Inventory full")?;
            ctx.db.inventory_item().insert(InventoryItem {
                id: 0, player_id: player.id, item_def_id: item.item_def_id, quantity, slot, is_bank: false,
            });
        }
    } else {
        ctx.db.inventory_item().insert(InventoryItem {
            id: 0, player_id: player.id, item_def_id: item.item_def_id, quantity, slot: target_slot, is_bank: false,
        });
    }

    // Remove from bank
    if quantity == item.quantity {
        ctx.db.inventory_item().id().delete(bank_item_id);
    } else {
        ctx.db.inventory_item().id().update(InventoryItem { quantity: item.quantity - quantity, ..item });
    }
    Ok(())
}

#[spacetimedb::reducer]
pub fn drop_item(ctx: &ReducerContext, inventory_item_id: u64, quantity: u32) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let item = ctx.db.inventory_item().id().find(inventory_item_id).ok_or("Item not found")?;
    if item.player_id != player.id { return Err("Not your item".into()); }
    if quantity == 0 || quantity > item.quantity { return Err("Invalid quantity".into()); }
    if quantity == item.quantity {
        ctx.db.inventory_item().id().delete(inventory_item_id);
    } else {
        ctx.db.inventory_item().id().update(InventoryItem { quantity: item.quantity - quantity, ..item });
    }
    Ok(())
}

// ─── Admin System ───

#[spacetimedb::reducer]
pub fn set_initial_admin(ctx: &ReducerContext) -> Result<(), String> {
    if ctx.db.admin_role().iter().next().is_some() {
        return Err("Admin already exists".into());
    }
    ctx.db.admin_role().insert(AdminRole {
        identity: ctx.sender,
        role: "owner".into(),
        granted_by: ctx.sender,
        granted_at: now_secs(ctx),
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn grant_admin(ctx: &ReducerContext, target_identity: Identity, role: String) -> Result<(), String> {
    let caller = ctx.db.admin_role().identity().find(&ctx.sender).ok_or("Not an admin")?;
    if caller.role != "owner" && caller.role != "admin" {
        return Err("Insufficient permissions".into());
    }
    if role != "admin" && role != "moderator" {
        return Err("Invalid role (admin or moderator)".into());
    }
    ctx.db.admin_role().insert(AdminRole {
        identity: target_identity,
        role,
        granted_by: ctx.sender,
        granted_at: now_secs(ctx),
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn create_item_definition(ctx: &ReducerContext, name: String, description: String, item_type: String, rarity: u8, stackable: bool, max_stack: u32, value: u64, icon_id: u16) -> Result<(), String> {
    if !is_admin(ctx) { return Err("Admin only".into()); }
    if name.is_empty() { return Err("Name required".into()); }
    if rarity > 4 { return Err("Rarity must be 0-4".into()); }
    let valid_types = ["consumable", "equipment", "key", "material", "currency"];
    if !valid_types.contains(&item_type.as_str()) { return Err("Invalid item type".into()); }
    ctx.db.item_definition().insert(ItemDefinition {
        id: 0, name, description, item_type, rarity, stackable,
        max_stack: if stackable { max_stack.max(1) } else { 1 },
        value, icon_id, created_by: ctx.sender,
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn spawn_item(ctx: &ReducerContext, player_id: u64, item_def_id: u64, quantity: u32) -> Result<(), String> {
    if !is_admin(ctx) { return Err("Admin only".into()); }
    if quantity == 0 { return Err("Quantity must be > 0".into()); }
    let _ = ctx.db.player().id().find(player_id).ok_or("Player not found")?;
    find_or_create_stack(ctx, player_id, item_def_id, quantity, false)?;
    Ok(())
}

#[spacetimedb::reducer]
pub fn update_item_definition(ctx: &ReducerContext, item_def_id: u64, name: String, description: String, value: u64) -> Result<(), String> {
    if !is_admin(ctx) { return Err("Admin only".into()); }
    let item = ctx.db.item_definition().id().find(item_def_id).ok_or("Item not found")?;
    ctx.db.item_definition().id().update(ItemDefinition { name, description, value, ..item });
    Ok(())
}

// ─── Trading System ───

#[spacetimedb::reducer]
pub fn create_trade(ctx: &ReducerContext, to_player_id: u64) -> Result<(), String> {
    let from = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let to = ctx.db.player().id().find(to_player_id).ok_or("Target not found")?;
    if !to.online { return Err("Target player is offline".into()); }
    if from.map_id != to.map_id { return Err("Must be on the same map".into()); }
    if from.id == to.id { return Err("Cannot trade with yourself".into()); }

    // Check no pending trades
    let has_pending = ctx.db.trade_offer().iter().any(|t| {
        t.status == "pending" && (t.from_player_id == from.id || t.to_player_id == from.id
            || t.from_player_id == to.id || t.to_player_id == to.id)
    });
    if has_pending { return Err("A trade is already pending".into()); }

    ctx.db.trade_offer().insert(TradeOffer {
        id: 0, from_player_id: from.id, to_player_id: to.id,
        status: "pending".into(), from_gold: 0, to_gold: 0,
        from_accepted: false, to_accepted: false,
        created_at: now_secs(ctx),
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn add_trade_item(ctx: &ReducerContext, trade_id: u64, item_id: u64, quantity: u32) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let trade = ctx.db.trade_offer().id().find(trade_id).ok_or("Trade not found")?;
    if trade.status != "pending" { return Err("Trade is not pending".into()); }

    let is_from = trade.from_player_id == player.id;
    let is_to = trade.to_player_id == player.id;
    if !is_from && !is_to { return Err("Not your trade".into()); }

    let item = ctx.db.inventory_item().id().find(item_id).ok_or("Item not found")?;
    if item.player_id != player.id || item.is_bank { return Err("Invalid item".into()); }
    if quantity == 0 || quantity > item.quantity { return Err("Invalid quantity".into()); }

    ctx.db.trade_item().insert(TradeItem {
        id: 0, trade_id, from_player: is_from, item_def_id: item.item_def_id, quantity,
    });

    // Reset acceptances
    ctx.db.trade_offer().id().update(TradeOffer { from_accepted: false, to_accepted: false, ..trade });
    Ok(())
}

#[spacetimedb::reducer]
pub fn set_trade_gold(ctx: &ReducerContext, trade_id: u64, gold_amount: u64) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let trade = ctx.db.trade_offer().id().find(trade_id).ok_or("Trade not found")?;
    if trade.status != "pending" { return Err("Trade is not pending".into()); }

    if trade.from_player_id == player.id {
        if player.gold < gold_amount { return Err("Insufficient gold".into()); }
        ctx.db.trade_offer().id().update(TradeOffer { from_gold: gold_amount, from_accepted: false, to_accepted: false, ..trade });
    } else if trade.to_player_id == player.id {
        if player.gold < gold_amount { return Err("Insufficient gold".into()); }
        ctx.db.trade_offer().id().update(TradeOffer { to_gold: gold_amount, from_accepted: false, to_accepted: false, ..trade });
    } else {
        return Err("Not your trade".into());
    }
    Ok(())
}

#[spacetimedb::reducer]
pub fn accept_trade(ctx: &ReducerContext, trade_id: u64) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let trade = ctx.db.trade_offer().id().find(trade_id).ok_or("Trade not found")?;
    if trade.status != "pending" { return Err("Trade is not pending".into()); }

    let is_from = trade.from_player_id == player.id;
    let is_to = trade.to_player_id == player.id;
    if !is_from && !is_to { return Err("Not your trade".into()); }

    let new_from_accepted = if is_from { true } else { trade.from_accepted };
    let new_to_accepted = if is_to { true } else { trade.to_accepted };

    if !new_from_accepted || !new_to_accepted {
        // Only one side accepted so far
        ctx.db.trade_offer().id().update(TradeOffer {
            from_accepted: new_from_accepted, to_accepted: new_to_accepted, ..trade
        });
        return Ok(());
    }

    // Both accepted - execute trade
    let from_player = ctx.db.player().id().find(trade.from_player_id).ok_or("From player not found")?;
    let to_player = ctx.db.player().id().find(trade.to_player_id).ok_or("To player not found")?;

    // Check gold
    if from_player.gold < trade.from_gold { return Err("Initiator has insufficient gold".into()); }
    if to_player.gold < trade.to_gold { return Err("Recipient has insufficient gold".into()); }

    // Collect trade items
    let trade_items: Vec<TradeItem> = ctx.db.trade_item().iter()
        .filter(|ti| ti.trade_id == trade_id)
        .collect();

    // Count items going to each player to check inventory space
    let items_to_from: Vec<&TradeItem> = trade_items.iter().filter(|ti| !ti.from_player).collect();
    let items_to_to: Vec<&TradeItem> = trade_items.iter().filter(|ti| ti.from_player).collect();

    // Rough space check (worst case: each trade item needs a new slot)
    let from_slots = count_inventory_slots(ctx, from_player.id);
    let to_slots = count_inventory_slots(ctx, to_player.id);
    // Items leaving free up slots, items arriving use slots
    let from_items_leaving = trade_items.iter().filter(|ti| ti.from_player).count() as u8;
    let to_items_leaving = trade_items.iter().filter(|ti| !ti.from_player).count() as u8;

    if from_slots.saturating_sub(from_items_leaving) + (items_to_from.len() as u8) > 32 {
        return Err("Initiator inventory would be full".into());
    }
    if to_slots.saturating_sub(to_items_leaving) + (items_to_to.len() as u8) > 32 {
        return Err("Recipient inventory would be full".into());
    }

    // Transfer gold
    let from_new_gold = from_player.gold - trade.from_gold + trade.to_gold;
    let to_new_gold = to_player.gold - trade.to_gold + trade.from_gold;
    ctx.db.player().id().update(Player { gold: from_new_gold, ..from_player });
    ctx.db.player().id().update(Player { gold: to_new_gold, ..to_player });

    // Transfer items
    for ti in &trade_items {
        let target_player_id = if ti.from_player { trade.to_player_id } else { trade.from_player_id };
        let source_player_id = if ti.from_player { trade.from_player_id } else { trade.to_player_id };

        // Remove from source inventory
        if let Some(src_item) = ctx.db.inventory_item().iter()
            .find(|i| i.player_id == source_player_id && i.item_def_id == ti.item_def_id && !i.is_bank && i.quantity >= ti.quantity)
        {
            if src_item.quantity == ti.quantity {
                ctx.db.inventory_item().id().delete(src_item.id);
            } else {
                ctx.db.inventory_item().id().update(InventoryItem { quantity: src_item.quantity - ti.quantity, ..src_item });
            }
        }

        // Add to target
        let _ = find_or_create_stack(ctx, target_player_id, ti.item_def_id, ti.quantity, false);
    }

    // Clean up trade items
    for ti in trade_items {
        ctx.db.trade_item().id().delete(ti.id);
    }

    // Mark complete
    ctx.db.trade_offer().id().update(TradeOffer {
        status: "accepted".into(), from_accepted: true, to_accepted: true, ..trade
    });
    Ok(())
}

#[spacetimedb::reducer]
pub fn cancel_trade(ctx: &ReducerContext, trade_id: u64) -> Result<(), String> {
    let player = find_player_by_identity(ctx, &ctx.sender).ok_or("Player not found")?;
    let trade = ctx.db.trade_offer().id().find(trade_id).ok_or("Trade not found")?;
    if trade.status != "pending" { return Err("Trade is not pending".into()); }
    if trade.from_player_id != player.id && trade.to_player_id != player.id {
        return Err("Not your trade".into());
    }

    // Clean up trade items
    let trade_items: Vec<TradeItem> = ctx.db.trade_item().iter()
        .filter(|ti| ti.trade_id == trade_id)
        .collect();
    for ti in trade_items {
        ctx.db.trade_item().id().delete(ti.id);
    }

    ctx.db.trade_offer().id().update(TradeOffer { status: "cancelled".into(), ..trade });
    Ok(())
}
