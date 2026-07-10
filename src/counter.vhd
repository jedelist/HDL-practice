library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (
        WIDTH : integer := 8
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        cnt : out std_logic_vector(WIDTH-1 downto 0);
        en : in std_logic
    );
end entity counter;

architecture rtl of counter is 
    signal count_out : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
    process(clk)
    begin 
        if rising_edge(clk) then
            if rst = '1' then
                count_out <= (others => '0');
            elsif en = '1' then 
                count_out <= count_out + 1;
            end if;
        end if;
    end process;

    cnt <= std_logic_vector(count_out);
end architecture rtl;
