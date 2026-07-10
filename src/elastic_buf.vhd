library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity elastic_buffer is
    generic (
        DATA_WIDTH : positive := 8
    );

    port (
        clk : in std_logic;
        rst : in std_logic;

        in_valid : in std_logic;
        in_ready : out std_logic;
        in_data : in std_logic_vector (DATA_WIDTH - 1 downto 0);

        out_valid : out std_logic;
        out_ready : in std_logic;
        out_data : out std_logic_vector (DATA_WIDTH - 1 downto 0)
    );
end entity elastic_buffer;

architecture rtl of elastic_buffer is
        signal data_reg : std_logic_vector(DATA_WIDTH - 1 downto 0);
        signal valid_reg : std_logic;
        --signal stage : positive := 0;
begin
    -- Combinational logic
    in_ready <= '1' when valid_reg = '0' or out_ready = '1' else '0';
    out_valid <= valid_reg;
    out_data <= data_reg;

    buf : process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                data_reg <= (others => '0');
                valid_reg <= '0';
            else

                if (in_valid = '1' and in_ready = '1') then
                    valid_reg <= '1';
                    data_reg <= in_data;

                elsif (valid_reg = '1' and out_ready = '1') then
                    valid_reg <= '0';
                end if;
            end if;
        end if;
    end process buf;
end architecture rtl;
