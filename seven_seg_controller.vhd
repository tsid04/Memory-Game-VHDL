library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_controller is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;

        round_num : in  integer range 0 to 10;
        score     : in  integer range 0 to 10;

        show_pass : in  std_logic;
        show_fail : in  std_logic;
        show_win  : in  std_logic;

        seg       : out std_logic_vector(6 downto 0);
        an        : out std_logic_vector(7 downto 0)
    );
end seven_seg_controller;

architecture Behavioral of seven_seg_controller is

    signal refresh_count : unsigned(15 downto 0) := (others => '0');
    signal digit_select  : unsigned(2 downto 0) := (others => '0');

    type seg_array is array (0 to 7) of std_logic_vector(6 downto 0);
    signal digits : seg_array := (others => "1111111");

    -- 7-seg patterns, active low
    constant BLANK : std_logic_vector(6 downto 0) := "1111111";
    constant ZERO  : std_logic_vector(6 downto 0) := "1000000";
    constant ONE   : std_logic_vector(6 downto 0) := "1111001";
    constant TWO   : std_logic_vector(6 downto 0) := "0100100";
    constant THREE : std_logic_vector(6 downto 0) := "0110000";
    constant FOUR  : std_logic_vector(6 downto 0) := "0011001";
    constant FIVE  : std_logic_vector(6 downto 0) := "0010010";
    constant SIX   : std_logic_vector(6 downto 0) := "0000010";
    constant SEVEN : std_logic_vector(6 downto 0) := "1111000";
    constant EIGHT : std_logic_vector(6 downto 0) := "0000000";
    constant NINE  : std_logic_vector(6 downto 0) := "0010000";

    constant P_CHAR : std_logic_vector(6 downto 0) := "0001100";
    constant A_CHAR : std_logic_vector(6 downto 0) := "0001000";
    constant S_CHAR : std_logic_vector(6 downto 0) := "0010010";
    constant F_CHAR : std_logic_vector(6 downto 0) := "0001110";
    constant I_CHAR : std_logic_vector(6 downto 0) := "1111001";
    constant L_CHAR : std_logic_vector(6 downto 0) := "1000111";
    constant W_CHAR : std_logic_vector(6 downto 0) := "1010101";
    constant N_CHAR : std_logic_vector(6 downto 0) := "0101011";

    function to_seg(num : integer) return std_logic_vector is
    begin
        case num is
            when 0 => return ZERO;
            when 1 => return ONE;
            when 2 => return TWO;
            when 3 => return THREE;
            when 4 => return FOUR;
            when 5 => return FIVE;
            when 6 => return SIX;
            when 7 => return SEVEN;
            when 8 => return EIGHT;
            when 9 => return NINE;
            when others => return BLANK;
        end case;
    end function;

begin

    -- refresh counter for multiplexing
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                refresh_count <= (others => '0');
            else
                refresh_count <= refresh_count + 1;
            end if;
        end if;
    end process;

    digit_select <= refresh_count(15 downto 13);

    -- choose what all 8 digits should show
    process(round_num, score, show_pass, show_fail, show_win)
        variable tens : integer;
        variable ones : integer;
    begin
        for i in 0 to 7 loop
            digits(i) <= BLANK;
        end loop;

        if show_pass = '1' then
            digits(7) <= P_CHAR;
            digits(6) <= A_CHAR;
            digits(5) <= S_CHAR;
            digits(4) <= S_CHAR;

        elsif show_fail = '1' then
            digits(7) <= F_CHAR;
            digits(6) <= A_CHAR;
            digits(5) <= I_CHAR;
            digits(4) <= L_CHAR;

            tens := score / 10;
            ones := score mod 10;
            digits(1) <= to_seg(tens);
            digits(0) <= to_seg(ones);

        elsif show_win = '1' then
            digits(7) <= W_CHAR;
            digits(6) <= I_CHAR;
            digits(5) <= N_CHAR;

            tens := score / 10;
            ones := score mod 10;
            digits(1) <= to_seg(tens);
            digits(0) <= to_seg(ones);

        else
            tens := round_num / 10;
            ones := round_num mod 10;
            digits(1) <= to_seg(tens);
            digits(0) <= to_seg(ones);
        end if;
    end process;

    -- multiplex active digit
    process(digit_select, digits)
    begin
        case digit_select is
            when "000" =>
                an  <= "11111110";
                seg <= digits(0);
            when "001" =>
                an  <= "11111101";
                seg <= digits(1);
            when "010" =>
                an  <= "11111011";
                seg <= digits(2);
            when "011" =>
                an  <= "11110111";
                seg <= digits(3);
            when "100" =>
                an  <= "11101111";
                seg <= digits(4);
            when "101" =>
                an  <= "11011111";
                seg <= digits(5);
            when "110" =>
                an  <= "10111111";
                seg <= digits(6);
            when others =>
                an  <= "01111111";
                seg <= digits(7);
        end case;
    end process;

end Behavioral;