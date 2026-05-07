library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    Port (
        clk      : in  std_logic;  
        reset    : in  std_logic;

        tick_1hz : out std_logic;  
        tick_500ms : out std_logic 
    );
end clock_divider;

architecture Behavioral of clock_divider is

    
    constant ONE_SEC_COUNT : integer := 100000000;
    constant HALF_SEC_COUNT : integer := 50000000;

    signal count_1hz : integer := 0;
    signal count_500ms : integer := 0;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                count_1hz <= 0;
                count_500ms <= 0;
                tick_1hz <= '0';
                tick_500ms <= '0';

            else
                
                if count_1hz = ONE_SEC_COUNT - 1 then
                    count_1hz <= 0;
                    tick_1hz <= '1';
                else
                    count_1hz <= count_1hz + 1;
                    tick_1hz <= '0';
                end if;

                
                if count_500ms = HALF_SEC_COUNT - 1 then
                    count_500ms <= 0;
                    tick_500ms <= '1';
                else
                    count_500ms <= count_500ms + 1;
                    tick_500ms <= '0';
                end if;

            end if;
        end if;
    end process;

end Behavioral;
