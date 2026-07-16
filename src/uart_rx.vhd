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
        pkt_valid : out std_logic := '0'

    );
end entity uart_rx;

architecture rtl of uart_rx is
    type rx_state_t is (IDLE, START, DATA, STOP);
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
            bit_ptr <= 0;
            corrupt <= '0';
            clk_cnt <= 0;
            pkt_valid <= '0';
            byte <= (others => '0');
        elsif (rising_edge(clk)) then
            pkt_valid <= '0';                               -- pkt_valid remains low and pulses high in STOP
            case state is 
                when IDLE => 
                    if (rx_serial = '0') then
                        -- Detected potential START bit
                        busy <= '1';
                        state <= START;
                        bit_ptr <= 0;
                        clk_cnt <= 0;
                    else
                        busy <= '0';
                        pkt_valid <= '0';
                        corrupt <= '0';
                    end if;
                when START =>
                    if (clk_cnt = CLKS_PER_BIT / 2) then     -- Sample in the middle of bit
                        if (rx_serial = '0') then
                            state <= DATA;
                            clk_cnt <= 0;
                            busy <= '1';
                            bit_ptr <= 0;
                        else
                            state <= IDLE;                   -- Fall back to IDLE if not true START but
                            busy <= '0';
                            clk_cnt <= 0;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;
                when DATA =>
                    if (clk_cnt = CLKS_PER_BIT - 1) then
                        byte(bit_ptr) <= rx_serial;
                        clk_cnt <= 0;
                        if (bit_ptr = 7) then
                            state <= STOP;
                            bit_ptr <= 0;
                        else
                            bit_ptr <= bit_ptr + 1;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;
                when STOP =>
                    if (clk_cnt = CLKS_PER_BIT - 1) then
                        if (rx_serial = '1') then
                            pkt <= byte;
                            byte <= (others => '0');
                            pkt_valid <= '1';
                            state <= IDLE;
                            bit_ptr <= 0;
                            clk_cnt <= 0;
                            busy <= '0';
                        else
                            corrupt <= '1';
                            -- handle somehow according to spec:
                            state <= IDLE;
                            byte <= (others => '0');
                            busy <= '0';
                            clk_cnt <= 0;
                            bit_ptr <= 0;
                            
                        end if;
                    else 
                        clk_cnt <= clk_cnt + 1;
                    end if;
            end case;
        end if;
    end process uart_rx;
end architecture rtl;
