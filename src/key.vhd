library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.itc.all;

entity key is
	port (
		-- system
		clk, rst_n : in std_logic;
		-- key
		key_row : in nibble_be_t;
		key_col : out nibble_be_t;
		-- user logic
		pressed : out std_logic;
		key     : out integer range 0 to 15
	);
end key;

architecture arch of key is

	signal pressed_i : std_logic; -- not debounced pressed flag

begin

	-- scan through columns
	process (clk, rst_n)
		variable curr_cycle_pressed : std_logic;
		variable column : integer range 0 to 3;
	begin
		if rst_n = '0' then
			pressed_i <= '0';
			curr_cycle_pressed := '0';
			column := 0;
		elsif rising_edge(clk) then
			if reduce(key_row, "and") = '0' then -- key_row has zeros (some key is pressed)
				key <= index_of(key_row, '0') * 4 + column;
				curr_cycle_pressed := '1'; -- remeber a button is pressed this cycle
			end if;

			if column = column'high then
				column := 0;
				pressed_i <= curr_cycle_pressed; -- update pressed flag
				curr_cycle_pressed := '0'; -- reset for next cycle
			else
				column := column + 1;
			end if;

			key_col <= "0111" ror column; -- cycle '0' between columns
		end if;
	end process;

	debounce_inst : entity work.debounce(arch)
		generic map(
			stable_time => 10
		)
		port map(
			clk     => clk,
			rst_n   => rst_n,
			sig_in  => pressed_i,
			sig_out => pressed
		);

end arch;
