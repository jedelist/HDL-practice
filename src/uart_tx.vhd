library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        CLK_FREQ : positive := 10_000_000;
        CLKS_PER_BIT : positive := 87       -- 115200 b/s
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        pkt : in std_logic_vector (7 downto 0);
        tx_serial : out std_logic;

        busy : out std_logic;
        tx_valid : in std_logic;            -- Upstream has valid packet to send
        tx_ready : out std_logic;           -- UART ready to transmit new packet
        
    );
end entity uart_tx;

architecture rtl of uart_tx is
    type tx_state_t is (IDLE, START, DATA, STOP);
    signal state : tx_state_t := IDLE;
    signal bit_ptr : positive;
    signal clk_cnt : integer := 0;
    signal byte : std_logic_vector(7 downto 0);

    uart_tx : process(clk, rst)
    begin
        if (rst = '1') then                          -- Asynchronous reset
            tx_serial <= '1';
            tx_ready <= '0';
            busy <= = '0';
            state <= IDLE;
            bit_ptr <= '0';
        elsif 
            if (rising_edge(clk)) then 
                if (clk_cnt = CLKS_PER_BIT - 1) then 
                    if (state = IDLE and tx_ready = '1' and tx_valid = '1' and busy = '0' ) then
                        state <= START;
                        tx_ready <= '0';
                        busy <= '1';
                        bit_ptr <= '0';
                        clk_cnt <= '0';
                        byte <= pkt;
                    end if;
                    if (state = START) then 
                        state <= DATA;
                        tx_serial <= '0';           -- Start bit
                        bit_ptr <= '0';
                    end if;
                    if (state = DATA) then 
                        if (bit_ptr = 7) then 
                            state <= STOP;
                            tx_serial <= byte(bit_ptr);
                        else 
                        tx_serial <= byte(bit_ptr);
                        bit_ptr <= bit_ptr + 1;
                        end if;
                    end if;
                    if (state = STOP) then 
                        tx_serial <= '1';           -- Stop bit
                        state <= IDLE;
                        bit_ptr <= '0';
                    end if;
                    if (state = IDLE and tx_ready = '0' and tx_valid = '0') then 
                        tx_serial <= '1';
                        busy <= '0';
                        tx_ready <= '1';
                    end if;
                else 
                    clk_cnt <= clk_cnt + 1;
                end if;
            end if;
        end if;
    end process uart_tx;
end architecture rtl;
