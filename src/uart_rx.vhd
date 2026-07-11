library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        CLK_FREQ : positive := 10_000_000;
        CLKS_PER_BIT : positive := 87       -- 115200 b/s
    );
    port(
        clk : in std_logic;
        rst : in std_logic;

        rx_serial : in std_logic;
        pkt : out std_logic_vector(7 downto 0) := (others => '0');

        busy : out std_logic := '0';
        corrupt : out std_logic := '0';
        pkt_valid : out std_logic := '0';

    );
end entity uart_rx;

architecture rtl of uart_rx is
    type rx_state_t is (IDLE, DATA, STOP);
    signal state : rx_state_t := IDLE;

    signal clk_cnt : natural range 0 to CLKS_PER_BIT - 1 := 0;
    signal byte : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_ptr : natural range 0 to 7 := 0;
begin
    uart_rx : process(clk, rst)
    begin
        if (rst = '1') then
            pkt <= (others => '0');
            busy <= '0';
            state <= IDLE;
            bit_ptr <= '0';
            corrupt <= '0';
            clk_cnt <= 0;
            pkt_valid <= '0';
        elsif (rising_edge(clk)) then
            if (clk_cnt = CLKS_PER_BIT - 1) then
                clk_cnt <= 0;
                if (state = IDLE and rx_serial = '0') then
                    state <= DATA;
                    busy <= '1';
                    bit_ptr <= 0;
                    byte <= (others => '0');
                elsif (state = IDLE) then
                    busy <= '0';
                    corrupt <= '0';
                    byte <= (others => '0');
                end if;
                if (state = DATA and bit_ptr < 7) then
                    byte(bit_ptr) <= rx_serial;
                    bit_ptr <= bit_ptr + 1;
                end if;
                if (state = DATA and bit_ptr = 7) then
                    byte(bit_ptr) <= rx_serial;
                    state <= STOP;
                end if;
                if (state = STOP) then
                    if (rx_serial = '1') then       -- Correct format case
                        state <= IDLE;
                        pkt <= byte;
                        pkt_valid <= '1';
                        bit_ptr <= 0;
                        corrupt <= '0';
                        busy <= '0';
                        byte <= (others => '0');
                    else                            -- Edge case handle differently depending on spec.
                        corrupt <= '1';
                        busy <= '1';
                        pkt_valid <= '0';
                    end if;
                end if;
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process uart_rx;
end architecture rtl;
