library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_tb is
end entity counter_tb;

architecture tb of counter_tb is
    constant CLK_PERIOD : time     := 10 ns;
    constant WIDTH      : positive := 4;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal en  : std_logic := '0';
    signal cnt : std_logic_vector(WIDTH - 1 downto 0);
begin
    dut : entity work.counter
        generic map (
            WIDTH => WIDTH
        )
        port map (
            clk => clk,
            rst => rst,
            en  => en,
            cnt => cnt
        );

    clk <= not clk after CLK_PERIOD / 2;

    stimulus : process
    begin
        ------------------------------------------------------------
        -- Enable the counter and verify counts 1 through 5.
        ------------------------------------------------------------

        wait until rising_edge(clk);
        en <= '1';

        for expected in 1 to 5 loop
            wait until rising_edge(clk);
            wait for 1 ns;

            assert cnt = std_logic_vector(to_unsigned(expected, WIDTH))
                report "Counter value mismatch: expected " &
                       integer'image(expected) &
                       ", got " &
                       integer'image(to_integer(unsigned(cnt)))
                severity failure;
        end loop;

        ------------------------------------------------------------
        -- Disable the counter and verify it holds at 5.
        ------------------------------------------------------------

        en <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert cnt = std_logic_vector(to_unsigned(5, WIDTH))
            report "Counter changed while disabled: expected 5, got " &
                   integer'image(to_integer(unsigned(cnt)))
            severity failure;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert cnt = std_logic_vector(to_unsigned(5, WIDTH))
            report "Counter changed while disabled: expected 5, got " &
                   integer'image(to_integer(unsigned(cnt)))
            severity failure;

        ------------------------------------------------------------
        -- Assert synchronous reset and verify zero after an edge.
        ------------------------------------------------------------

        rst <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert cnt = std_logic_vector(to_unsigned(0, WIDTH))
            report "Counter did not reset to zero: got " &
                   integer'image(to_integer(unsigned(cnt)))
            severity failure;

        rst <= '0';

        report "All tests passed" severity note;
        wait;
    end process;
end architecture tb;