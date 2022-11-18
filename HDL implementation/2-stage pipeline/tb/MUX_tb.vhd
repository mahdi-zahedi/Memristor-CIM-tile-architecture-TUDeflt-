-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : MUX_tb.vhd                                         	     --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;


entity MUX_tb is
end MUX_tb;

architecture tb of MUX_tb is

-- constants
	constant bits_per_column : integer := 2;
	constant num_in_columns : integer := 4;

-- components
	component MUX is
		generic( bits_per_column	:	integer;
				 num_in_columns	:	integer
				);
		port(	i_data	: in  std_logic_vector(bits_per_column * num_in_columns - 1 downto 0);
			    i_sel	: in  std_logic_vector(num_in_columns - 1 downto 0);
				o_data	: out std_logic_vector(bits_per_column - 1 downto 0)
				);
	end component;

-- signals
	-- inputs
	signal input  : std_logic_vector(bits_per_column * num_in_columns -1 downto 0);
	signal sel	  : std_logic_vector(num_in_columns-1 downto 0);

	-- outputs
	signal output : std_logic_vector(bits_per_column - 1 downto 0);


begin

uut: MUX generic map(bits_per_column => bits_per_column, num_in_columns => num_in_columns)
		   port map(i_data => input, i_sel => sel, o_data => output);

-- test for num_in_bits=4, num_out_block=4	
	input <= "00111000",
			 "01001100" after 10 ns,
			 "10010000" after 20 ns,
			 "11100100" after 30 ns,
			 "00111000" after 40 ns,
			 "01001100" after 50 ns,
			 "10010000" after 60 ns,
			 "11100100" after 70 ns,
			 "00111000" after 80 ns,
			 "01001100" after 90 ns;
 
	sel <=   "0001",
			 "0010" after 25 ns,
			 "0100" after 50 ns,
			 "1000" after 75 ns;

end tb;
