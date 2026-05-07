library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lfsr_rng is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        enable    : in  std_logic;
        load_seed : in  std_logic;
        seed      : in  std_logic_vector(7 downto 0);
        rand_out  : out std_logic_vector(7 downto 0)
    );
end lfsr_rng;

architecture Behavioral of lfsr_rng is

    signal lfsr : std_logic_vector(7 downto 0) := "10101101";
    signal feedback : std_logic;

begin


    feedback <= lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                lfsr <= "10101101";

            elsif load_seed = '1' then
                if seed = "00000000" then
                    lfsr <= "00000001";
                else
                    lfsr <= seed;
                end if;

            elsif enable = '1' then
                lfsr <= lfsr(6 downto 0) & feedback;
            end if;
        end if;
    end process;

    rand_out <= lfsr;

end Behavioral;
