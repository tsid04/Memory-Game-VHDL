library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity switch_input is
    generic (
        STABLE_COUNT : integer := 50000000  -- 0.5 sec at 100 MHz
    );
    Port (
        clk                 : in  std_logic;
        reset               : in  std_logic;
        switches            : in  std_logic_vector(7 downto 0);

        valid               : out std_logic;
        selected            : out integer range 0 to 7;
        waiting_for_release : out std_logic;
        invalid_input       : out std_logic
    );
end switch_input;

architecture Behavioral of switch_input is

    type state_type is (WAIT_PRESS, CHECK_STABLE, WAIT_RELEASE);
    signal state : state_type := WAIT_PRESS;

    signal last_switches : std_logic_vector(7 downto 0) := (others => '0');
    signal stable_counter : integer := 0;

    signal selected_reg : integer range 0 to 7 := 0;

    -- Count how many switches are ON
    function count_ones(s : std_logic_vector(7 downto 0)) return integer is
        variable count : integer := 0;
    begin
        for i in 0 to 7 loop
            if s(i) = '1' then
                count := count + 1;
            end if;
        end loop;
        return count;
    end function;

    -- Find which switch is ON
    function get_index(s : std_logic_vector(7 downto 0)) return integer is
        variable index_val : integer := 0;
    begin
        for i in 0 to 7 loop
            if s(i) = '1' then
                index_val := i;
            end if;
        end loop;
        return index_val;
    end function;

begin

    process(clk)
        variable ones_count : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= WAIT_PRESS;
                last_switches <= (others => '0');
                stable_counter <= 0;
                selected_reg <= 0;

                valid <= '0';
                waiting_for_release <= '0';
                invalid_input <= '0';

            else
                valid <= '0';
                ones_count := count_ones(switches);

                case state is

                    when WAIT_PRESS =>
                        waiting_for_release <= '0';
                        stable_counter <= 0;

                        if ones_count > 1 then
                            invalid_input <= '1';
                        else
                            invalid_input <= '0';
                        end if;

                        if ones_count = 1 then
                            last_switches <= switches;
                            stable_counter <= 0;
                            state <= CHECK_STABLE;
                        end if;

                    when CHECK_STABLE =>
                        waiting_for_release <= '0';

                        if switches /= last_switches then
                            -- switches changed again, restart stability check
                            last_switches <= switches;
                            stable_counter <= 0;

                        else
                            if stable_counter < STABLE_COUNT then
                                stable_counter <= stable_counter + 1;
                            else
                                if count_ones(switches) = 1 then
                                    selected_reg <= get_index(switches);
                                    valid <= '1';
                                    invalid_input <= '0';
                                    state <= WAIT_RELEASE;
                                elsif count_ones(switches) > 1 then
                                    invalid_input <= '1';
                                    state <= WAIT_PRESS;
                                else
                                    state <= WAIT_PRESS;
                                end if;
                            end if;
                        end if;

                    when WAIT_RELEASE =>
                        waiting_for_release <= '1';

                        if switches = "00000000" then
                            waiting_for_release <= '0';
                            stable_counter <= 0;
                            invalid_input <= '0';
                            state <= WAIT_PRESS;
                        elsif count_ones(switches) > 1 then
                            invalid_input <= '1';
                        else
                            invalid_input <= '0';
                        end if;

                end case;
            end if;
        end if;
    end process;

    selected <= selected_reg;

end Behavioral;