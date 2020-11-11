library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package itc is
	--------------------------------------------------------------------------------
	-- common types
	--------------------------------------------------------------------------------

	subtype nibble_t is unsigned(3 downto 0);
	subtype nibble_be_t is unsigned(0 to 3); -- big endian nibble
	type nibbles_t is array (integer range <>) of nibble_t;
	type nibbles_be_t is array (integer range <>) of nibble_be_t;

	subtype byte_t is unsigned(7 downto 0);
	subtype byte_be_t is unsigned(0 to 7); -- big endian byte
	type bytes_t is array (integer range <>) of byte_t;
	type bytes_be_t is array (integer range <>) of byte_be_t;

	--------------------------------------------------------------------------------
	-- system constants
	--------------------------------------------------------------------------------

	constant sys_clk_freq : integer := 50_000_000;

	--------------------------------------------------------------------------------
	-- math constants
	--------------------------------------------------------------------------------

	-- (square root of 0 to 255) * 16
	constant sqrt : bytes_t(0 to 2 ** 8 - 1) := (
		x"00", x"10", x"16", x"1b", x"20", x"23", x"27", x"2a", 
		x"2d", x"30", x"32", x"35", x"37", x"39", x"3b", x"3d", 
		x"40", x"41", x"43", x"45", x"47", x"49", x"4b", x"4c", 
		x"4e", x"50", x"51", x"53", x"54", x"56", x"57", x"59", 
		x"5a", x"5b", x"5d", x"5e", x"60", x"61", x"62", x"63", 
		x"65", x"66", x"67", x"68", x"6a", x"6b", x"6c", x"6d", 
		x"6e", x"70", x"71", x"72", x"73", x"74", x"75", x"76", 
		x"77", x"78", x"79", x"7a", x"7b", x"7c", x"7d", x"7e", 
		x"80", x"80", x"81", x"82", x"83", x"84", x"85", x"86", 
		x"87", x"88", x"89", x"8a", x"8b", x"8c", x"8d", x"8e", 
		x"8f", x"90", x"90", x"91", x"92", x"93", x"94", x"95", 
		x"96", x"96", x"97", x"98", x"99", x"9a", x"9b", x"9b", 
		x"9c", x"9d", x"9e", x"9f", x"a0", x"a0", x"a1", x"a2", 
		x"a3", x"a3", x"a4", x"a5", x"a6", x"a7", x"a7", x"a8", 
		x"a9", x"aa", x"aa", x"ab", x"ac", x"ad", x"ad", x"ae", 
		x"af", x"b0", x"b0", x"b1", x"b2", x"b2", x"b3", x"b4", 
		x"b5", x"b5", x"b6", x"b7", x"b7", x"b8", x"b9", x"b9", 
		x"ba", x"bb", x"bb", x"bc", x"bd", x"bd", x"be", x"bf", 
		x"c0", x"c0", x"c1", x"c1", x"c2", x"c3", x"c3", x"c4", 
		x"c5", x"c5", x"c6", x"c7", x"c7", x"c8", x"c9", x"c9", 
		x"ca", x"cb", x"cb", x"cc", x"cc", x"cd", x"ce", x"ce", 
		x"cf", x"d0", x"d0", x"d1", x"d1", x"d2", x"d3", x"d3", 
		x"d4", x"d4", x"d5", x"d6", x"d6", x"d7", x"d7", x"d8", 
		x"d9", x"d9", x"da", x"da", x"db", x"db", x"dc", x"dd", 
		x"dd", x"de", x"de", x"df", x"e0", x"e0", x"e1", x"e1", 
		x"e2", x"e2", x"e3", x"e3", x"e4", x"e5", x"e5", x"e6", 
		x"e6", x"e7", x"e7", x"e8", x"e8", x"e9", x"ea", x"ea", 
		x"eb", x"eb", x"ec", x"ec", x"ed", x"ed", x"ee", x"ee", 
		x"ef", x"f0", x"f0", x"f1", x"f1", x"f2", x"f2", x"f3", 
		x"f3", x"f4", x"f4", x"f5", x"f5", x"f6", x"f6", x"f7", 
		x"f7", x"f8", x"f8", x"f9", x"f9", x"fa", x"fa", x"fb", 
		x"fb", x"fc", x"fc", x"fd", x"fd", x"fe", x"fe", x"ff"
	);

	--------------------------------------------------------------------------------
	-- tts command constants
	--------------------------------------------------------------------------------

	-- constant tts_instant_clear : byte_t := (x"80"); -- DO NOT USE, MAY CRASH MODULE
	constant tts_instant_vol_up : byte_t := x"81";
	constant tts_instant_vol_down : byte_t := x"82";
	constant tts_instant_pause : bytes_t(0 to 1) := (x"8f", x"00");
	constant tts_instant_resume : bytes_t(0 to 1) := (x"8f", x"01");
	constant tts_instant_skip : bytes_t(0 to 1) := (x"8f", x"02"); -- skips delay or music
	constant tts_instant_soft_reset : bytes_t(0 to 1) := (x"8f", x"03"); -- TODO what's the use case?

	-- concatenate 1 speed byte after
	-- e.g. 0x83 0x19 means 25% faster 
	-- range 0x00 to 0x28 (40%)
	-- default is 0x00
	constant tts_set_speed : byte_t := x"83";

	-- concatenate 1 volume byte after
	-- e.g. 0xff means 0db, 0xfe means -0.5db, 0x01 means -127db, 0x00 means mute
	-- range 0x00 to 0xff
	-- default is 0xd2 (-105db)
	constant tts_set_vol : byte_t := x"86";

	-- concatenate 4 time bytes after
	-- e.g. 0x0001d4c0 means delay 120000ms
	-- range 0x00000000 to 0xffffffff
	constant tts_delay : byte_t := x"87";

	-- concatenate 2 filename bytes and 2 repeat bytes after
	-- e.g. 0x03fd_0005 means play "1021.wav" 5 times
	-- filename can be 0x0001 to 0x270f (0001 to 9999)
	-- repeat = 0 means do not stop
	constant tts_play_file : byte_t := x"88";

	constant tts_sleep : byte_t := x"89";

	-- concatenate 1 state byte after, only last 3 bits (2 downto 0) have an effect
	-- e.g. 0x06 means set MO2, MO1, MO0 = 1, 1, 0
	-- range 0x00 to 0x07
	-- default is 0x07
	constant tts_set_mo : byte_t := x"8a";

	-- concatenate 1 mode byte after
	-- | mode  | line out | headphone | speaker |
	-- | :---: | :------: | :-------: | :-----: |
	-- | 0x01  |          |           |    L    |
	-- | 0x02  |          |           |    R    |
	-- | 0x03  |          |           |  both   |
	-- | 0x04  |          |   both    |         |
	-- | 0x05  |          |     L     |    L    |
	-- | 0x06  |          |     R     |    R    |
	-- | 0x07  |          |   both    |  both   |
	-- | 0x08  |   both   |           |         |
	-- | 0x09  |    L     |           |    L    |
	-- | 0x0a  |    R     |           |    R    |
	-- | 0x0b  |   both   |           |  both   |
	constant tts_set_channel : byte_t := x"8b";

	--------------------------------------------------------------------------------
	-- common functions
	--------------------------------------------------------------------------------

	-- to_integer: converts '0' and '1' to 0 and 1.
	-- logic: signal to be converted
	function to_integer(logic : std_logic) return integer;

	-- log. Yes, log. returns ceil(log_base(num))
	function log(base, num : integer) return integer;

	-- reverse: returns vector in reversed order.
	-- vector: vector to be reversed
	function reverse(vector : std_logic_vector) return std_logic_vector;
	function reverse(vector : unsigned) return unsigned;

	-- reduce: and/or/xor all bits in a std_logic_vector
	-- vector: vector to be reduced, index range must include 0
	-- operation: can be "and", "or_", "xor". not "or" because VHDL need fixed-length strings
	function reduce(vector : std_logic_vector; operation : string) return std_logic;
	function reduce(vector : unsigned; operation : string) return std_logic;

	-- index_of: searches vector for the element, and returns its index
	-- vector: vector to be searched
	-- element: element to look for
	function index_of(vector : std_logic_vector; element : std_logic) return integer;
	function index_of(vector : unsigned; element : std_logic) return integer;

	-- to_string: convert num into decimal string
	-- num: the unsigned number to be converted
	-- base: output base system. can be 2/8/10/16.
	function to_string(num, num_max, base, length : integer) return string;
end package;

package body itc is
	function to_integer(logic : std_logic) return integer is begin
		if logic = '0' then
			return 0;
		else
			return 1;
		end if;
	end function;

	function log(base, num : integer) return integer is
		variable temp : integer := 1;
		variable result : integer := 0;
	begin
		for i in 0 to num loop
			if temp < num then
				temp := temp * base;
				result := result + 1;
			else
				return result;
			end if;
		end loop;
	end function;

	function reverse(vector : std_logic_vector) return std_logic_vector is
		variable result : std_logic_vector(vector'reverse_range);
	begin
		for i in vector'range loop
			result(i) := vector(i);
		end loop;

		return result;
	end function;

	function reverse(vector : unsigned) return unsigned is begin
		return unsigned(reverse(std_logic_vector(vector)));
	end function;

	function reduce(vector : std_logic_vector; operation : string) return std_logic is
		variable result : std_logic := vector(0);
	begin
		for i in vector'range loop
			case operation is
				when "and" =>
					result := result and vector(i);
				when "or_" =>
					result := result or vector(i);
				when "xor" =>
					result := result xor vector(i);
				when others =>
					return 'X';
			end case;
		end loop;

		return result;
	end function;

	function reduce(vector : unsigned; operation : string) return std_logic is begin
		return reduce(std_logic_vector(vector), operation);
	end function;

	function index_of(vector : std_logic_vector; element : std_logic) return integer is
		variable temp : std_logic_vector(vector'range);
	begin
		for i in vector'range loop
			if vector(i) = element then
				return i;
			end if;
		end loop;

		return 0;
	end function;

	function index_of(vector : unsigned; element : std_logic) return integer is begin
		return index_of(std_logic_vector(vector), element);
	end function;

	function to_bcd(num, num_max, dec_width : integer) return unsigned is
		constant bin_width : integer := log(2, num_max);
		variable bin : unsigned(bin_width - 1 downto 0) := to_unsigned(num, bin_width);
		variable bcd : unsigned(dec_width * 4 - 1 downto 0) := (others => '0');
	begin
		-- https://en.wikipedia.org/wiki/Double_dabble 
		for i in 0 to bin_width - 1 loop
			-- check if any nibble (bcd digit) is more then 4
			for digit in 0 to dec_width - 1 loop
				if bcd(digit * 4 + 3 downto digit * 4) > 4 then
					bcd(digit * 4 + 3 downto digit * 4) := bcd(digit * 4 + 3 downto digit * 4) + 3; -- add 3 to the digit
				end if;
			end loop;

			--   shift
			--  <------
			-- bcd & bin
			bcd := bcd sll 1;
			bcd(bcd'right) := bin(bin'left);
			bin := bin sll 1;
		end loop;

		return bcd;
	end function;

	function to_string(num, num_max, base, length : integer) return string is
		variable temp : unsigned(3 downto 0);
		variable result : string(1 to length);
	begin
		for c in 0 to length - 1 loop
			case base is
				when 2 =>
					temp := "000" & to_unsigned(num, length)(c);
				when 8 =>
					temp := "0" & to_unsigned(num, length * 3)(c * 3 + 2 downto c * 3);
				when 10 =>
					temp := to_bcd(num, num_max, length)(c * 4 + 3 downto c * 4); -- convert BCD to string
				when 16 =>
					temp := to_unsigned(num, length * 4)(c * 4 + 3 downto c * 4);
				when others =>
					return (1 to length => 'E');
			end case;

			if temp < 10 then -- 0 to 9
				result(length - c) := character'val(to_integer(temp) + character'pos('0'));
			else -- A to F
				result(length - c) := character'val(to_integer(temp) - 10 + character'pos('A'));
			end if;
		end loop;

		return result;
	end function;
end package body;
