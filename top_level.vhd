library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port (
        clk          : in  std_logic;                      
        reset        : in  std_logic;                      
        start_button : in  std_logic;                      
        switches     : in  std_logic_vector(7 downto 0);   

        led          : out std_logic_vector(7 downto 0);   
        seg          : out std_logic_vector(6 downto 0);   
        an           : out std_logic_vector(7 downto 0)    
    );
end top_level;

architecture Behavioral of top_level is

    
    signal tick_1hz    : std_logic;
    signal tick_500ms  : std_logic;

    
    signal rand_val    : std_logic_vector(7 downto 0);
    signal load_seed   : std_logic;
    signal seed_out    : std_logic_vector(7 downto 0);

    
    signal seq_clear      : std_logic;
    signal seq_add        : std_logic;
    signal seq_add_value  : integer range 0 to 7;
    signal seq_read_index : integer range 0 to 7;
    signal seq_value      : integer range 0 to 7;
    signal seq_length     : integer range 0 to 8;

   
    signal player_valid        : std_logic;
    signal player_selected     : integer range 0 to 7;
    signal waiting_for_release : std_logic;
    signal invalid_input       : std_logic;

   
    signal leds_from_fsm : std_logic_vector(7 downto 0);
    signal round_num     : integer range 0 to 10;
    signal score         : integer range 0 to 10;

    signal show_pass     : std_logic;
    signal show_fail     : std_logic;
    signal show_win      : std_logic;
    signal flash_leds    : std_logic;
    signal game_active   : std_logic;

begin
    u_clock_divider : entity work.clock_divider
        port map (
            clk        => clk,
            reset      => reset,
            tick_1hz   => tick_1hz,
            tick_500ms => tick_500ms
        );

    u_lfsr_rng : entity work.lfsr_rng
        port map (
            clk       => clk,
            reset     => reset,
            enable    => '1',
            load_seed => load_seed,
            seed      => seed_out,
            rand_out  => rand_val
        );

    u_sequence_memory : entity work.sequence_memory
        port map (
            clk        => clk,
            reset      => reset,
            clear      => seq_clear,
            add        => seq_add,
            value_in   => seq_add_value,
            read_index => seq_read_index,
            value_out  => seq_value,
            length     => seq_length
        );

    u_switch_input : entity work.switch_input
        generic map (
            STABLE_COUNT => 50000000   -- 0.5 sec at 100 MHz
        )
        port map (
            clk                 => clk,
            reset               => reset,
            switches            => switches,
            valid               => player_valid,
            selected            => player_selected,
            waiting_for_release => waiting_for_release,
            invalid_input       => invalid_input
        );

    u_memory_game_fsm : entity work.memory_game_fsm
        port map (
            clk                 => clk,
            reset               => reset,
            start_button        => start_button,

            tick_1hz            => tick_1hz,
            tick_500ms          => tick_500ms,

            rand_val            => rand_val,
            seq_value           => seq_value,
            seq_length          => seq_length,

            player_valid        => player_valid,
            player_selected     => player_selected,
            waiting_for_release => waiting_for_release,
            invalid_input       => invalid_input,

            seq_clear           => seq_clear,
            seq_add             => seq_add,
            seq_add_value       => seq_add_value,
            seq_read_index      => seq_read_index,

            load_seed           => load_seed,
            seed_out            => seed_out,

            leds                => leds_from_fsm,

            round_num           => round_num,
            score               => score,

            show_pass           => show_pass,
            show_fail           => show_fail,
            show_win            => show_win,
            flash_leds          => flash_leds,
            game_active         => game_active
        );

    u_seven_seg_controller : entity work.seven_seg_controller
        port map (
            clk       => clk,
            reset     => reset,

            round_num => round_num,
            score     => score,

            show_pass => show_pass,
            show_fail => show_fail,
            show_win  => show_win,

            seg       => seg,
            an        => an
        );


    process(leds_from_fsm, flash_leds, show_fail, show_win)
    begin
        if (show_fail = '1') or (show_win = '1') then
            if flash_leds = '1' then
                led <= "11111111";
            else
                led <= "00000000";
            end if;
        else
            led <= leds_from_fsm;
        end if;
    end process;

end Behavioral;
