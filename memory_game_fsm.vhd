library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory_game_fsm is
    Port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        start_button       : in  std_logic;

        tick_1hz           : in  std_logic;
        tick_500ms         : in  std_logic;

        rand_val           : in  std_logic_vector(7 downto 0);
        seq_value          : in  integer range 0 to 7;
        seq_length         : in  integer range 0 to 8;

        player_valid       : in  std_logic;
        player_selected    : in  integer range 0 to 7;
        waiting_for_release: in  std_logic;
        invalid_input      : in  std_logic;

        seq_clear          : out std_logic;
        seq_add            : out std_logic;
        seq_add_value      : out integer range 0 to 7;
        seq_read_index     : out integer range 0 to 7;

        load_seed          : out std_logic;
        seed_out           : out std_logic_vector(7 downto 0);

        leds               : out std_logic_vector(7 downto 0);

        round_num          : out integer range 0 to 10;
        score              : out integer range 0 to 10;

        show_pass          : out std_logic;
        show_fail          : out std_logic;
        show_win           : out std_logic;
        flash_leds         : out std_logic;
        game_active        : out std_logic
    );
end memory_game_fsm;

architecture Behavioral of memory_game_fsm is

    type state_type is (
        IDLE,
        LOAD_SEED_STATE,
        CLEAR_SEQ,
        BUILD_START_SEQ,
        ADD_NEXT_STEP,
        PREP_DISPLAY,
        DISPLAY_ON,
        DISPLAY_OFF,
        WAIT_PLAYER,
        CHECK_INPUT,
        ROUND_PASS_WAIT,
        ROUND_PASS_FLASH,
        FAIL_STATE,
        WIN_STATE
    );

    signal state : state_type := IDLE;

    signal round_count    : integer range 0 to 10 := 0;
    signal display_index  : integer range 0 to 7 := 0;
    signal input_index    : integer range 0 to 7 := 0;
    signal pass_count     : integer range 0 to 5 := 0;
    signal flash_toggle   : std_logic := '0';
    signal start_seq_done : integer range 0 to 4 := 0;

    signal led_reg        : std_logic_vector(7 downto 0) := (others => '0');
    signal seed_reg       : std_logic_vector(7 downto 0) := (others => '0');

    signal expected_value : integer range 0 to 7 := 0;

    signal start_last     : std_logic := '0';

begin

    process(clk)
        variable rand_index : integer range 0 to 7;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                round_count <= 0;
                display_index <= 0;
                input_index <= 0;
                pass_count <= 0;
                flash_toggle <= '0';
                start_seq_done <= 0;
                led_reg <= (others => '0');
                seed_reg <= (others => '0');
                expected_value <= 0;
                start_last <= '0';

                seq_clear <= '0';
                seq_add <= '0';
                seq_add_value <= 0;
                seq_read_index <= 0;
                load_seed <= '0';

                show_pass <= '0';
                show_fail <= '0';
                show_win <= '0';
                flash_leds <= '0';
                game_active <= '0';

            else
                -- defaults every cycle
                seq_clear <= '0';
                seq_add <= '0';
                load_seed <= '0';

                show_pass <= '0';
                show_fail <= '0';
                show_win <= '0';
                flash_leds <= '0';
                game_active <= '0';

                start_last <= start_button;

                rand_index := to_integer(unsigned(rand_val(2 downto 0)));

                case state is

                    when IDLE =>
                        led_reg <= (others => '0');
                        round_count <= 0;
                        display_index <= 0;
                        input_index <= 0;
                        pass_count <= 0;
                        flash_toggle <= '0';
                        start_seq_done <= 0;

                        if start_button = '1' and start_last = '0' then
                            seed_reg <= rand_val;
                            state <= LOAD_SEED_STATE;
                        end if;

                    when LOAD_SEED_STATE =>
                        load_seed <= '1';
                        state <= CLEAR_SEQ;

                    when CLEAR_SEQ =>
                        seq_clear <= '1';
                        start_seq_done <= 0;
                        state <= BUILD_START_SEQ;

                    when BUILD_START_SEQ =>
                        if start_seq_done < 4 then
                            seq_add <= '1';
                            seq_add_value <= rand_index;
                            start_seq_done <= start_seq_done + 1;
                        else
                            round_count <= 1;
                            state <= PREP_DISPLAY;
                        end if;

                    when ADD_NEXT_STEP =>
                        if seq_length < 8 then
                            seq_add <= '1';
                            seq_add_value <= rand_index;
                        end if;
                        state <= PREP_DISPLAY;

                    when PREP_DISPLAY =>
                        game_active <= '1';
                        display_index <= 0;
                        input_index <= 0;
                        seq_read_index <= 0;
                        led_reg <= (others => '0');
                        state <= DISPLAY_ON;

                    when DISPLAY_ON =>
                        game_active <= '1';
                        seq_read_index <= display_index;

                        led_reg <= (others => '0');
                        led_reg(seq_value) <= '1';

                        if tick_1hz = '1' then
                            state <= DISPLAY_OFF;
                        end if;

                    when DISPLAY_OFF =>
                        game_active <= '1';
                        led_reg <= (others => '0');

                        if tick_500ms = '1' then
                            if display_index < (seq_length - 1) then
                                display_index <= display_index + 1;
                                state <= DISPLAY_ON;
                            else
                                input_index <= 0;
                                state <= WAIT_PLAYER;
                            end if;
                        end if;

                    when WAIT_PLAYER =>
                        game_active <= '1';
                        led_reg <= (others => '0');
                        seq_read_index <= input_index;
                        expected_value <= seq_value;

                        if player_valid = '1' then
                            state <= CHECK_INPUT;
                        end if;

                    when CHECK_INPUT =>
                        game_active <= '1';

                        if player_selected = expected_value then
                            if input_index = seq_length - 1 then
                                if round_count = 10 then
                                    state <= WIN_STATE;
                                else
                                    pass_count <= 0;
                                    flash_toggle <= '0';
                                    state <= ROUND_PASS_WAIT;
                                end if;
                            else
                                input_index <= input_index + 1;
                                state <= WAIT_PLAYER;
                            end if;
                        else
                            pass_count <= 0;
                            flash_toggle <= '0';
                            state <= FAIL_STATE;
                        end if;

                    when ROUND_PASS_WAIT =>
                        game_active <= '1';
                        led_reg <= (others => '0');

                        if pass_count < 2 then
                            if tick_1hz = '1' then
                                pass_count <= pass_count + 1;
                            end if;
                        else
                            pass_count <= 0;
                            flash_toggle <= '0';
                            state <= ROUND_PASS_FLASH;
                        end if;

                    when ROUND_PASS_FLASH =>
                        game_active <= '1';
                        show_pass <= flash_toggle;

                        if tick_500ms = '1' then
                            flash_toggle <= not flash_toggle;
                            pass_count <= pass_count + 1;
                        end if;

                        if pass_count = 5 then
                            round_count <= round_count + 1;
                            if seq_length < 8 then
                                state <= ADD_NEXT_STEP;
                            else
                                state <= PREP_DISPLAY;
                            end if;
                            pass_count <= 0;
                            flash_toggle <= '0';
                        end if;

                    when FAIL_STATE =>
                        show_fail <= '1';
                        flash_leds <= tick_500ms;

                    when WIN_STATE =>
                        show_win <= '1';
                        flash_leds <= tick_500ms;

                end case;
            end if;
        end if;
    end process;

    leds <= led_reg;
    round_num <= round_count;
    score <= round_count - 1;
    seed_out <= seed_reg;

end Behavioral;