#[test_only]
module pixel_war::game_test {
    use std::vector;
    use sui::test_scenario::{Self, Scenario};
    use sui::clock::{Self, Clock};
    use pixel_war::game;

    const GAME_ADMIN: address = @0xBABA; 
    const PLAYER_1: address = @0x1111;
    const PLAYER_2: address = @0x2222;
    const CLOCK: address = @0x6;
    const GAME_SIZE_X: u64 = 32;
    const GAME_SIZE_Y: u64 = 32;



    fun create_game(scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, GAME_ADMIN);
        let clock = clock::create_for_testing(test_scenario::ctx(scenerio));
        let image = vector::empty<u8>();
        let current_time = clock::timestamp_ms(&clock);
        game::create_game(image, GAME_SIZE_X, GAME_SIZE_Y, 0xffffff, 30, current_time, 300, test_scenario::ctx(scenerio));
        clock::share_for_testing(clock);
    }

    fun check_pixel(player: address, x: u64, y: u64, color: u32, scenerio: &mut Scenario, ) {
        test_scenario::next_tx(scenerio, player);
        let game = test_scenario::take_shared<game::Game>(scenerio);
        let pixel = game::get_pixel(x, y, &mut game);
        assert!(pixel == color, 1);
        test_scenario::return_shared(game)
    }

    fun set_pixel(player: address, x: u64, y: u64, color: u32, scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, player);
        let game = test_scenario::take_shared<game::Game>(scenerio);
        let index = x + GAME_SIZE_X * y;
        let clock = test_scenario::take_shared<Clock>(scenerio);
        game::set_pixel(index, color, &clock, &mut game, test_scenario::ctx(scenerio));
        test_scenario::return_shared(game);
        test_scenario::return_shared(clock);
    }

    fun check_size(player: address, scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, player);
        let game = test_scenario::take_shared<game::Game>(scenerio);
        let (_ipfs, _, _, _, _, _, _) = game::get_info(&mut game);
        // assert!(game_size_X == GAME_SIZE_X, 1);
        // assert!(game_size_Y == GAME_SIZE_Y, 1);
        test_scenario::return_shared(game)
    }

    fun check_time(scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, GAME_ADMIN);
        let clock = test_scenario::take_shared<Clock>(scenerio);
        let time = clock::timestamp_ms(&clock);
        assert!(time == 0, 1);
        test_scenario::return_shared(clock)
    }

    fun increase_time(time: u64, scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, GAME_ADMIN);
        let clock = test_scenario::take_shared<Clock>(scenerio);
        clock::increment_for_testing(&mut clock, time);
        test_scenario::return_shared(clock)
    }

    #[test]
    public fun test_create_game_and_check_pixels() {
        let scenerio_val = test_scenario::begin(GAME_ADMIN);
        let scenerio = &mut scenerio_val;

        create_game(scenerio);
        check_size(PLAYER_1, scenerio);
        check_pixel(PLAYER_1, 0, 0, 0xffffff, scenerio);
        check_time(scenerio);

        test_scenario::end(scenerio_val);
    }

    #[test]
    public fun test_size () {
        let scenerio_val = test_scenario::begin(GAME_ADMIN);
        let scenerio = &mut scenerio_val;

        create_game(scenerio);
        check_size(PLAYER_1, scenerio);

        test_scenario::end(scenerio_val);
    }

    #[test]
    public fun test_set_pixel_and_check() {
        let scenerio_val = test_scenario::begin(GAME_ADMIN);
        let scenerio = &mut scenerio_val;

        create_game(scenerio);
        set_pixel(PLAYER_1, 30, 20, 1561821733, scenerio);
        check_pixel(PLAYER_1, 30, 20, 1561821733, scenerio);

        test_scenario::end(scenerio_val);
    }

    #[test]
    #[expected_failure(abort_code = pixel_war::game::EFINISHED)]
    public fun test_set_pixel_after_finish() {
        let scenerio_val = test_scenario::begin(GAME_ADMIN);
        let scenerio = &mut scenerio_val;

        create_game(scenerio);
        increase_time(60 * 300 * 1000 + 1, scenerio);
        set_pixel(PLAYER_1, 30, 20, 0x123456, scenerio);
        
        test_scenario::end(scenerio_val);
    }

    #[test]
    #[expected_failure(abort_code = pixel_war::game::ECOOLDOWN)]
    public fun test_set_pixel_in_cooldown() {
        let scenerio_val = test_scenario::begin(GAME_ADMIN);
        let scenerio = &mut scenerio_val;

        create_game(scenerio);
        set_pixel(PLAYER_1, 30, 20, 0x123456, scenerio);
        set_pixel(PLAYER_1, 30, 20, 0x123456, scenerio);
        
        test_scenario::end(scenerio_val);
    }

    #[test]
    public fun test_set_pixel_after_cooldown() {
        let scenerio_val = test_scenario::begin(GAME_ADMIN);
        let scenerio = &mut scenerio_val;

        create_game(scenerio);
        set_pixel(PLAYER_1, 30, 20, 0x123456, scenerio);
        increase_time(60 * 30 + 1, scenerio);
        set_pixel(PLAYER_1, 30, 20, 0x123456, scenerio);
        
        test_scenario::end(scenerio_val);
    }
}