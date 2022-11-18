-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : PC_LUT_tb.vhd                                            --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity PC_LUT_tb is
end PC_LUT_tb;


architecture behavioural of PC_LUT_tb is

-- constants
	constant bandwidth : integer := 32;
	constant large_instruction_size_bytes : integer := (bandwidth / 8) + 1;
	constant size	   : integer := integer(ceil(log2(real((bandwidth / 8) + 2)))); -- +1 for opcode/index
																					-- +1 for correct ceil

-- components
	component PC_LUT is
	generic(val_00   : integer;
			val_01   : integer;
			val_10   : integer;
			val_11   : integer;
			bit_size : integer);
	port   (sel : in  std_logic_vector(1 downto 0);
			O   : out std_logic_vector(bit_size - 1 downto 0));
	end component;

-- signals
	-- inputs
	signal sel : std_logic_vector(1 downto 0);

	-- outputs
	signal O : std_logic_vector(size - 1 downto 0);

begin
	
uut:	PC_LUT   generic map(val_00 => large_instruction_size_bytes,
						 	 val_01 => 1, 
						 	 val_10 => 1, 
						 	 val_11 => 1, 
						 	 bit_size => size)
			 	 port map   (sel => sel, O => O);

	sel <= "00",
		   "01" after 10 ns,
		   "10" after 20 ns,
		   "11" after 30 ns;

end behavioural;
