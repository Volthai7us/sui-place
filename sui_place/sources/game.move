module pixel_war::game {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use std::vector;
    use sui::vec_map::{Self, VecMap};
    use std::option::{Self};
    use sui::url::{Self, Url};

    const EFINISHED: u64 = 1;
    const ECOOLDOWN: u64 = 2;
    const EPERMISSION: u64 = 3;
    const ENOTSTARTED: u64 = 4;

    struct Pixel has store {
        color: u32,
    }

    struct Game has key, store {
        id: UID,
        owner: address,
        metadata: Url,
        x: u64,
        y: u64,
        cooldown: u64,
        canvas_periode: u64,
        pixels: vector<Pixel>,
        painted_amount: u64,
        players_cooldown: VecMap<address, u64>,
        start_time: u64,
        finish_time: u64,
    }

    fun create_pixel(color: u32 ) : Pixel {
        Pixel { color }
    }

    fun solid_canvas(x: u64, y: u64, color: u32) : vector<Pixel> {
        let pixels = vector::empty<Pixel>();
        let i = 0;
        while (i != x * y) {
            vector::push_back(&mut pixels, create_pixel(color));
            i = i + 1;
        };

        pixels
    }

    fun min_to_ms(min: u64) : u64 {
        min * 60 * 1000
    }


    public entry fun create_game(metadata: vector<u8>, x: u64, y: u64, bg_color: u32, cooldown: u64, start_time: u64, canvas_periode: u64, ctx: &mut TxContext) {
        let id = object::new(ctx);

        let pixels = solid_canvas(x, y, bg_color);        
        let players_cooldown = vec_map::empty();

        let game = Game {
            id: id,
            owner: tx_context::sender(ctx),
            metadata: url::new_unsafe_from_bytes(metadata),
            x: x,
            y: y,
            cooldown: cooldown,
            canvas_periode: canvas_periode,
            pixels: pixels,
            painted_amount: 0,
            players_cooldown: players_cooldown,
            start_time: start_time,
            finish_time: start_time + min_to_ms(canvas_periode),
        };

        transfer::share_object(game);
    }

    public entry fun set_pixel(index: u64, color: u32, clock: &Clock, game: &mut Game, ctx: &mut TxContext) {
        let current_time = clock::timestamp_ms(clock);

        let started = current_time > game.start_time;
        assert!(started, ENOTSTARTED);
        let passed = current_time > game.finish_time;
        assert!(!passed, EFINISHED);

        let sender = tx_context::sender(ctx);
        let player = vec_map::try_get(&game.players_cooldown, &sender);
        let current_time = clock::timestamp_ms(clock);
        if(option::is_some(&player)) {
            let value = *option::borrow(&player);
            assert!(value + game.cooldown < current_time, ECOOLDOWN);
            vec_map::remove(&mut game.players_cooldown, &sender);
            vec_map::insert(&mut game.players_cooldown, sender, current_time + game.cooldown);
        };
        if(option::is_none(&player)) {
            vec_map::insert(&mut game.players_cooldown, sender, current_time + game.cooldown);
        };

        let pixel = vector::borrow_mut<Pixel>(&mut game.pixels, index);
        pixel.color = color;
        game.painted_amount = game.painted_amount + 1;
    }

    public fun get_pixel(x: u64, y: u64, game: &mut Game) : u32 {
        let pixel = vector::borrow_mut<Pixel>(&mut game.pixels, x + y * game.x);
        pixel.color
    }

    public fun get_pixels(x: u64, y: u64, game: &mut Game) : vector<u32> {
        let pixels = vector::empty<u32>();
        let i = 0;
        while (i != x) {
            let j = 0;
            while (j != y) {
                let pixel = vector::borrow_mut<Pixel>(&mut game.pixels, j + i * game.x);
                vector::push_back(&mut pixels, pixel.color);
                j = j + 1;
            };
            i = i + 1
        };
        pixels
    }

    public entry fun get_all_pixels(game: &mut Game) : vector<u32> {
        let pixels = vector::empty<u32>();
        let i = 0;
        while (i != game.x * game.y) {
            let pixel = vector::borrow_mut<Pixel>(&mut game.pixels, i);
            vector::push_back(&mut pixels, pixel.color);
            i = i + 1
        };
        pixels
    }

    public entry fun get_info(game: &mut Game) : (Url, u64, u64, u64, u64, u64, u64) {
        (game.metadata, game.cooldown, game.canvas_periode, vec_map::size(&game.players_cooldown), game.painted_amount, game.start_time, game.finish_time)
    }
    
    public entry fun get_players(game: &mut Game) : VecMap<address, u64> {
        game.players_cooldown
    }

    public entry fun get_player_cooldown(game: &mut Game, player: address) : u64 {
        let player = vec_map::try_get(&game.players_cooldown, &player);
        if(option::is_some(&player)) {
            let value = *option::borrow(&player);
            value
        } else {
            0
        }
    }

    public entry fun update_metadata_url(metadata: vector<u8>, game: &mut Game, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == game.owner, EPERMISSION);
        game.metadata = url::new_unsafe_from_bytes(metadata);
    }

    public entry fun update_owner(owner: address, game: &mut Game, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == game.owner, EPERMISSION);
        game.owner = owner;
    }

    public entry fun update_start_time(start_time: u64, game: &mut Game, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == game.owner, EPERMISSION);
        game.start_time = start_time;
    }

    public entry fun update_finish_time(finish_time: u64, game: &mut Game, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == game.owner, EPERMISSION);
        game.finish_time = finish_time;
    }

    public entry fun update_cooldown(cooldown: u64, game: &mut Game, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == game.owner, EPERMISSION);
        game.cooldown = cooldown;
    }
}