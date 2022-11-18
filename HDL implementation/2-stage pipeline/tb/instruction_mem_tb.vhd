-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : instruction_memory_1_tb.vhd                              --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity instruction_memory_1_tb is
end instruction_memory_1_tb;

architecture tb of instruction_memory_1_tb is

-- constants
	constant inst_size : integer := 3;
	constant PC_size   : integer := 10;
	constant mem_size  : integer := 1024;

-- components
	component instruction_memory_1 is
		generic(inst_size : integer;
				PC_size   : integer;
				mem_size  : integer);
		port( i_PC : in std_logic_vector(PC_size - 1 downto 0);
	
			  o_inst : out std_logic_vector(inst_size * 8 - 1 downto 0)
	);
	end component;

-- signals
	-- inputs
	signal i_PC : std_logic_vector(PC_size - 1 downto 0);

	-- outputs
	signal o_inst : std_logic_vector(inst_size*8 - 1 downto 0);

begin

uut: instruction_memory_1 generic map(inst_size => inst_size, PC_size => PC_size, mem_size => mem_size)
						  port map(i_PC => i_PC, o_inst => o_inst);

	i_PC <= "0000000000",
 			"0000000001" after 10 ns,
 			"0000000010" after 20 ns,
 			"0000000100" after 30 ns;

end tb;
