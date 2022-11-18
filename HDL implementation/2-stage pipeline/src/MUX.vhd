-----------------------------------------------------------------------
-- Project: CiM-Tile HW Design/implementation                        --
-- File	  : MUX.vhd                                            		 --
-- Author : Remon van Duijnen (R.F.J.vanDuijnen@student.tudelft.nl)  --
-- Version: 1.0														 --
----------------------------------------------------------------------- 

library ieee;
use ieee.std_logic_1164.all;
use IEEE.math_real.all;

-- NOTE: This MUX uses an already decoded select signal. 

entity MUX is
generic( num_in_columns	  :	integer;
		 bits_per_column  :	integer
	);
port(	i_data	: in  std_logic_vector(num_in_columns * bits_per_column - 1 downto 0);
	    i_sel	: in  std_logic_vector(num_in_columns - 1 downto 0);
		o_data	: out std_logic_vector(bits_per_column - 1 downto 0)
	);
end MUX;

architecture behavioural of MUX is

	type blocks_array is array (num_in_columns-1 downto 0) of std_logic_vector(bits_per_column-1 downto 0);
	
	signal AND_output_blocks : blocks_array;
	signal tmp : blocks_array;

begin

G0: for i in num_in_columns - 1 downto 0 generate
G1: 	for j in  bits_per_column - 1 downto 0 generate
	
			AND_output_blocks(i)(j) <= i_data(i * bits_per_column + j) AND i_sel(i);
	
		end generate;
	end generate;



G2: for j in bits_per_column - 1 downto 0 generate
		tmp(0)(j) <= AND_output_blocks(0)(j);
	
G3:		for i in  num_in_columns-1 downto 1 generate
			tmp(i)(j) <= AND_output_blocks(i)(j) OR tmp(i-1)(j);
		end generate;
	end generate;

	o_data <= tmp(num_in_columns-1);

end behavioural;
