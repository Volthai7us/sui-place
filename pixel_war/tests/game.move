#[test_only]
module pixel_war::game_test {
    use sui::test_scenario::{Self, Scenario};
    use pixel_war::game;

    const GAME_ADMIN: address = @0xBABA; 
    const PLAYER_1: address = @0x1111;
    const PLAYER_2: address = @0x2222;
    const GAME_SIZE_X: u64 = 32;
    const GAME_SIZE_Y: u64 = 32;


    fun create_game(scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, GAME_ADMIN);
        game::create_game(GAME_SIZE_X, GAME_SIZE_Y, test_scenario::ctx(scenerio));
    }

    fun check_pixel(player: address, x: u64, y: u64, color: u64, scenerio: &mut Scenario, ) {
        test_scenario::next_tx(scenerio, player);
        let game = test_scenario::take_shared<game::Game>(scenerio);
        let pixel = game::get_pixel(x, y, &mut game);
        assert!(pixel == color, 1);
        test_scenario::return_shared(game)
    }

    fun set_pixel(player: address, x: u64, y: u64, color: u64, scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, player);
        let game = test_scenario::take_shared<game::Game>(scenerio);
        let index = x + GAME_SIZE_X * y;
        game::set_pixel(index, color, &mut game);
        test_scenario::return_shared(game)
    }

    fun check_size(player: address, scenerio: &mut Scenario) {
        test_scenario::next_tx(scenerio, player);
        let game = test_scenario::take_shared<game::Game>(scenerio);
        let (game_size_X, game_size_Y) = game::get_size(&mut game);
        assert!(game_size_X == GAME_SIZE_X, 1);
        assert!(game_size_Y == GAME_SIZE_Y, 1);
        test_scenario::return_shared(game)
    }

    #[test]
    public fun test_create_game_and_check_pixels() {
        let scenerio_val = test_scenario::begin(GAME_ADMIN);
        let scenerio = &mut scenerio_val;

        create_game(scenerio);
        check_size(PLAYER_1, scenerio);
        check_pixel(PLAYER_1, 0, 0, 0xffffff, scenerio);

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
        set_pixel(PLAYER_1, 30, 20, 0x123456, scenerio);
        check_pixel(PLAYER_1, 30, 20, 0x123456, scenerio);

        test_scenario::end(scenerio_val);
    }
}