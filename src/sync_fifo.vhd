library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_fifo is
    generic (
        DATA_WIDTH : positive := 8;
        DEPTH : positive := 16
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        wr_en : in std_logic;
        rd_en : in std_logic;
        din : in std_logic_vector(DATA_WIDTH-1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH-1 downto 0);

        full : out std_logic;
        empty : out std_logic
    );
end entity sync_fifo;

architecture rtl of sync_fifo is
    type memory_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal mem : memory_t := (others => (others => '0'));

    signal wr_ptr : integer range 0 to DEPTH-1 := 0;
    signal rd_ptr : integer range 0 to DEPTH-1 := 0;
    signal count : natural range 0 to DEPTH    := 0;        -- can this be a variable?


begin
    full            <= '1' when count = DEPTH else '0';
    empty           <= '1' when count = 0 else '0';
    
    sync_fifo : process (clk)
    
        variable write_accepted : boolean;                        -- Variables must be declared in process scope
        variable read_accepted : boolean;

    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                count <= 0;
                mem <= (others => (others => '0'));               -- Not required to reset mem on reset, just ptrs and signals.
                wr_ptr <= 0; rd_ptr <= 0;
                dout <= (others => '0');                          -- Must reset d_out
            else
                write_accepted  := wr_en = '1' and full = '0';    -- Variables must be used in a process scope
                read_accepted   := rd_en = '1' and empty = '0';

                if (read_accepted) then                           -- Do I need internal variables since these are port signals?
                    dout <= mem(rd_ptr);
                    if (rd_ptr = DEPTH-1) then
                        rd_ptr <= 0;
                    else
                        rd_ptr <= rd_ptr + 1;
                    end if;
                end if;
                if (write_accepted) then
                    mem(wr_ptr) <= din;
                    if (wr_ptr = DEPTH-1) then
                        wr_ptr <= 0;
                    else
                        wr_ptr <= wr_ptr + 1;
                    end if;
                end if;
                -- Handle assigning count here to avoid simultaneous read/write from clobbering the value
                if (write_accepted and not read_accepted) then
                    count <= count + 1;
                elsif (read_accepted and not write_accepted) then
                    count <= count - 1;
                end if;
            end if;
        end if;
    end process sync_fifo;
end architecture rtl;
