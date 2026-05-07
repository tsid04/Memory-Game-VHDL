library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sequence_memory is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        clear      : in  std_logic;
        add        : in  std_logic;
        value_in   : in  integer range 0 to 7;
        read_index : in  integer range 0 to 7;
        value_out  : out integer range 0 to 7;
        length     : out integer range 0 to 8
    );
end sequence_memory;

architecture Behavioral of sequence_memory is

    type seq_array is array (0 to 7) of integer range 0 to 7;
    signal seq : seq_array := (others => 0);
    signal count : integer range 0 to 8 := 0;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                seq <= (others => 0);
                count <= 0;

            elsif clear = '1' then
                seq <= (others => 0);
                count <= 0;

            elsif add = '1' then
                if count < 8 then
                    seq(count) <= value_in;
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    value_out <= seq(read_index);
    length <= count;

end Behavioral;